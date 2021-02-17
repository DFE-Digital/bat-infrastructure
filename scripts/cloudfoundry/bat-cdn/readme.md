The Ruby script is to assist in generating the Cloudfoundry 'cf update-service <service_name>' command.

As new custom domains are onboarded, there is the need to update the existing CDN service on Cloudfoundry.

The CDN service for QA, Staging and Prod are bat-cdn-qa, bat-cdn-staging and bat-cdn-prod respectively.

An example of the 'cf update-service <service_name>' command is described below:-

cf update-service bat-cdn-qa -c \
'{"headers":["Accept","Authorization"],"domain":"qa.find-postgraduate-teacher-training.service.gov.uk,qa.register-trainee-teachers.education.gov.uk,qa.api.publish-teacher-training-courses.service.gov.uk,qa.publish-teacher-training-courses.service.gov.uk"}'

The Ruby script also includes a control file. This yaml file (cdn-config.yml) contains the parameters for each environment.

Usage:

In order to add a new custom domain to the CDN service, update the appropriate cdn-config.yml with correct values.
please note, the ruby file takes single argument, which must be supplied when the script is instigated.
The supplied argument (ARVG) represents the intended target environment. To run the script from the shell, do the following:-

#QA
`bat-cdn.rb qa`

#Staging
`bat-cdn.rb staging`

#Prod
`bat-cdn.rb prod`

Running any of the above will print out the desired `cf update <service_name>` command along with the newly updated custom domain. The output can then be executed from the shell, while logged into Cloudfoundry.

#AWS endpoint
CIP needs to configure our hostname entries as CNAME to point to the following AWS addresses:-

QA
CNAME => d1g6p51l52so6s.cloudfront.net

STAGING
CNAME => d2jkti130squc1.cloudfront.net

PRODUCTION
CNAME => d2jkti130squc1.cloudfront.net
