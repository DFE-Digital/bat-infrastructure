## Overview

The Ruby script is to assist in generating the Cloudfoundry 'cf update-service <service_name>' command.

As new custom domains are onboarded, there is the need to update the existing CDN service on Cloudfoundry.

## Example

An example of the 'cf update-service <service_name>' command is described below:-

```
cf update-service bat-cdn-qa -c \
'{"headers":["Accept","Authorization"],"domain":"qa.find-postgraduate-teacher-training.service.gov.uk,qa.register-trainee-teachers.education.gov.uk,qa.api.publish-teacher-training-courses.service.gov.uk,qa.publish-teacher-training-courses.service.gov.uk"}'
```
### Configuration

The Ruby script also includes a control file. This yaml file (cdn-config.yml) contains the parameters for each environment.

Each section has three elements:

- Service - The service is the name of the cloud foundry CDN route service which needs to be updated.
- Headers - Are a list of header settings, by default these are Accept and Authorization
- Domain - Is a list of the domain names which need to be maintained for the service.

```
git-staging:
  service: get-into-teaching-cdn-test
  headers: *headers
  domain:
    - staging-adviser-getintoteaching.education.gov.uk
    - staging-getintoteaching.education.gov.uk
```

## Usage

In order to add a new custom domain to the CDN service, update the appropriate cdn-config.yml with correct values.
please note, the ruby file takes single argument, which must be supplied when the script is instigated.
The supplied argument (ARVG) represents the intended target environment. To run the script from the shell, do the following:-

### Valid options
|Option.       |Application       |Environment|
|--------------|------------------|-----------|
|bat-qa        |Becoming A Teacher|QA         |
|bat-staging   |Becoming A Teacher|Staging    |
|bat-prod      |Becoming A Teacher|Production |
|git-staging   |Get Into Teaching |Staging    | 
|git-prod      |Get Into Teaching |Production |

Running the script with any of the above will print out the desired `cf update <service_name>` command along with the newly updated custom domain. The output can then be executed from the shell, while logged into Cloudfoundry.

### Example

```
./bat-cdn.rb git-staging

cf update-service get-into-teaching-cdn-test -c '{"headers":["Accept","Authorization"],"domain":"staging-adviser-getintoteaching.education.gov.uk,staging-getintoteaching.education.gov.uk"}'-staging

```
