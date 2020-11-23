# Find, API and publish CI/CD

Today the deployment process is somewhat manual, unreliable and slow. This creates frustration for the devs and it takes up a lot of their time.

Overtime, the strategy is to move to Gov.UK PaaS, using Github Actions as an orchesteration deployment tool. This would allow us to move to a continous deployment model, anchored by quality integrated testing and the right security controls in place.

Here is the proposal.

### Spaces
We have 3 spaces in paas: bat-qa, bat-staging, bat-prod.
* The managers (tech leads etc) are SpaceManagers so they can add/remove SpaceDevelopers
* Developers are SpaceDevelopers in bat-qa. They can be made temporarily SpaceDeveloper in staging and prod by a SpaceManager

### Environments
We translated the existing Azure environments such as QA, Staging and Prod to new PaaS permanent environments, with the same names as today.
* Prod is in bat-prod space. It has a full size database, and several instances of webapps and workers.
* Staging is in bat-staging space. It has the same configuration as prod (or very close). Its database is refreshed daily with sanitised data.
* QA is in bat-qa space. It has a smaller size infrastructure and possibly different feature flags. Its database is refreshed daily with sanitised data.

Each publish PR creates a review app. It points by default to QA but can be changed by the developer.

It is also possible to deploy a brand new environment for API or publish for any purpose via a simple make command.

The make command can also be used to make exceptional deployment to permanent environments without the pipeline.

### Feature flags
There is one yaml file with sections for each environment. It also has plain text environment variables used by the apps. They can be used to enable/disable feature flags in specific environments.

### Secrets
Secrets are stored in yaml in Azure keyvault. They are read by terraform and passed to the app as environment variables.
They can be edited via a script by users with sufficient level of access to Azure subscriptions.
This means when a secret is added to keyvault's yaml file, it will be made available in the app at next deployment, without changing any code or infra.

### Smoke tests
They have enough coverage to give us confidence that they can replace manual testing.
Publish and API have a different suite of smoke tests. API doesn't need Cypress and should run for all versions of the API.

### Decoupling
API and publish are released independently with separate pipelines. If a new version of publish is released, it must always be compatible with the current version of the API (and vice versa). It may imply temporary code duplication which should be removed with a later PR.

### Pipeline
Here are the main steps of the pipeline:
* Build a docker image with a unique tag and push it to docker hub
* Run unit tests, lint, etc
* Deploy to QA, run smoke tests in QA
* Deploy to Staging, run smoke tests in Staging
* Deploy to Prod, run smoke tests in Prod

### Rollback options
The deployment uses blue-green so if the new app version fails to start, it is automatically rolled back to the existing version and the pipeline fails.

If there is any need to redeploy a particular previous version manually, we can trigger the deployment pipeline with a particular commit SHA to any environment. This maps automatically to the corresponding docker image.

If a code change is required, it should go via PR, as a new docker image build is needed.

### Monitoring
Basic monitoring is StatusCake pinging the site every 1 minute.

Smoke tests run continuously against prod, every 5/10 min.

PaaS metrics as well as application custom metrics are available in prometheus. They are used for alerting and creating dashboards in grafana.

Logs are streamed to Logit.io, with custom filters for paas logs to enrich kibana filter, queries and graphs.
