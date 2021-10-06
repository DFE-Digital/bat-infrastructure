#!/usr/bin/env python

import sys
import argparse
try:
    from elasticsearch import Elasticsearch
    from elasticsearch.exceptions import RequestError
except Exception as exx:
    print("""Unable to import Elasticsearch.
Ensure you have the appropriate version for the version of ElasticSearch you are connecting to, e.g.

    pip3 install 'elasticsearch<7.14.0'

You can find more info here: https://pypi.org/project/elasticsearch/
""")
    raise(exx)

import json
from pprint import pprint

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
# - pip install 'elasticsearch<7.4.0'

# This was the maximum count per index
MAX_RESULT_WINDOW = 11000

# Start with a small result size while developping
SIZE = MAX_RESULT_WINDOW

def parse_args(args):
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description='''Remove params from PUT and POST requests in Elasticsearch indices.

This script will connect to the given Elasticsearch instance and process all the
indices, removing any params stored in the "payload.params_json" field.''',
        epilog='''Authentication:

Retrieve the URL, username and password from the Logstash dashboard for the
stack you want to run against.

Examples:

The following command processes all the indices starting from 2021.09.24 going
to the current date, restricting the matches to the production environment:

    $ {arg0}  -u 'https://host.logit.io' -U 'user_from_logit' -p 'password_from_logit' -s 2021.09.24 -e production
        '''.format(arg0=sys.argv[0])
    )
    parser.add_argument('-u', '--url', required=True, help='URL for Elasticsearch endpoint')
    parser.add_argument('-U', '--user', required=True, help='User to authenticate with Elasticsearch endpoint')
    parser.add_argument('-p', '--password', required=True, help='Password to authenticate with Elasticsearch endpoint')

    parser.add_argument('-e', '--environment', metavar='ENV', help='The environment to operate on')

    date_group = parser.add_mutually_exclusive_group()
    date_group.add_argument('-d', '--date', help='Only parse the index for the given date')
    date_group.add_argument('-s', '--start', metavar="DATE", help='Only parse indexes starting from the given date')

    parser.add_argument('-n', '--dry-run', action='store_true', help='Do not change anything, print changes that would be done')

    processed_args = parser.parse_args(args)
    print(processed_args.url)

    return processed_args

# Update the document with the new value
def update_document(doc):
    print('Updating document {}'.format(doc['_id']))
    update_body = {
        'doc': {
            'payload': {
                'params_json': "{}"
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

def process_index(index, environment, dry_run):
    increase_results_window(index)

    query_body = {
        "query": {
            "bool": {
                "must": [
                    {"match": {"application": "register"}},
                    {"match": {"environment": environment}},
                    {"match": {"payload.method": "PUT OR POST"}},
                ],
                "must_not": [
                    {"match": {"payload.params_json.keyword": "{}"}},
                ],
            }
        }
    }

    # Search Elasticsearch to return documents matching a query
    result = ES.search(index=index, body=query_body, size=SIZE, track_total_hits=True)

    print("Processing index {} with {} documents".format(index, result['hits']['total']['value']))

    # Iterate each document
    for doc in result['hits']['hits']:
        if not dry_run:
            update_document(doc)
        else:
            param_keys = json.loads(doc['_source']['payload']['params_json']).keys()
            print("found matching doc {id} from {timestamp} with params: {param_keys}".format(
                id=doc['_id'],
                timestamp=doc['_source']['@timestamp'],
                param_keys=",".join(param_keys)))

## BEGIN

if __name__ == "__main__":
    args = parse_args(sys.argv[1:])

    # Connection to Elasticsearch. Get the credentials from "Elasticsearch settings" in the stack settings
    ES = Elasticsearch(
        args.url,
        http_auth=(args.user, args.password),
        scheme="https",
        port=443,
    )

    logstash_indices = ES.indices.get("logstash*")

    if args.date:
        logstash_date = "logstash-{}".format(args.date)

        # if not filter(lambda i : i == logstash_date, logstash_indices):
        if logstash_date not in logstash_indices:
            raise Exception("could not find index for date {}".format(args.date))
        logstash_indices = [logstash_date]

    if args.start:
        logstash_date = "logstash-{}".format(args.start)
        logstash_indices = filter(lambda i : i >= logstash_date, logstash_indices)

    for index in sorted(logstash_indices):
        process_index(index, environment=args.environment, dry_run=args.dry_run)
## END
