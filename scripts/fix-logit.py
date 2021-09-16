from elasticsearch import Elasticsearch
from elasticsearch.exceptions import RequestError
import json

# This script is an example of fixing data in Logit. In this case the params.subjects_failed field must be fixed and copied to params.subjects.
# It follows these steps:
# - iterate all Elasticsearch indices
# - run a query to return documents matching a query
# - iterate all index documents
# - read the existing data
# - create the new data
# - update the document with the new data
# Requirements:
# - access to Elasticsearch
# - https://pypi.org/project/elasticsearch/

# This was the maximum count per index
MAX_RESULT_WINDOW = 11000

# Start with a small result size while developping
SIZE = MAX_RESULT_WINDOW

# Search query. See: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html
QUERY_BODY_SUBJECTS_FAILED = {"query": {
    "bool": {"should": [{"exists": {"field": "params.subjects_failed"}}]}}
}

# Connection to Elasticsearch. Get the credentials from "Elasticsearch settings" in the stack settings
ES = Elasticsearch(
    ['xxxxxx.logit.io'],
    http_auth=('USERNAME', 'PASSWORD'),
    scheme="https",
    port=443,
)

# Skip already processed indices. Useful when restarting the script
ALREADY_PROCESSED = [
    'logstash-2021.08.30',
    'logstash-2021.08.29',
    'logstash-2021.08.28',
]

# Update the document with the new value
def update_document(doc, subjects):
    print('Updating document {}'.format(doc['_id']))
    update_body = {
        'doc': {
            'params': {
                'subjects': subjects
            }
        }
    }
    try:
        ES.update(
            index = doc['_index'],
            id = doc['_id'],
            body = update_body
        )
    except RequestError as e:
        # Some updates may fail. We capture the issue without stopping processing
        print('Error updating document: {}'.format(e))

# Create the new value
# In this case it's from a different field which is possibly in a different format
def new_subjects(doc):
    subjects_failed = doc['_source']['params']['subjects_failed']
    subjects = subjects_failed if isinstance(subjects_failed, list) else json.loads(subjects_failed)
    return subjects

# Elasticsearch default results quantity is 10000. We can increase it reasonbly. For more see:
# https://www.elastic.co/guide/en/elasticsearch/reference/current/paginate-search-results.html
def increase_results_window(index):
    body = {
        "index" : {
            "max_result_window" : MAX_RESULT_WINDOW
        }
    }
    ES.indices.put_settings(
        index = index,
        body = body
    )

def process_index(index):
    increase_results_window(index)

    # Search Elasticsearch to return documents matching a query
    result = ES.search(index=i, body=QUERY_BODY_SUBJECTS_FAILED, size=SIZE, track_total_hits=True)

    print("Processing index {} with {} documents".format(index, result['hits']['total']['value']))

    # Iterate each document
    for doc in result['hits']['hits']:
        subjects = new_subjects(doc)
        update_document(doc, subjects)

## BEGIN

logstash_indices = ES.indices.get("logstash*")

for i in logstash_indices:
    if i in ALREADY_PROCESSED:
        print('Index {} was already processed, skipping'.format(i))
        continue

    process_index(i)

## END
