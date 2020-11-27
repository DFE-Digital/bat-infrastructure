# Reusable GitHub Actions

A set of resuable custom actions that can be used in different repos.

## Prepare Environment Matrix
Given a comma separated input of `available-environments`, this [action](prepare-environment-matrix/action.yml) can be used to prepare the environment matrix from the workflow inputs.
Useful in scenarios when there is a need to selectively deploy to environments depending on the input parameter in a `workflow_dispatch` workflow.
### Usage
```yml
 - id:   select-environments
   uses: DFE-Digital/bat-infrastructure/actions/prepare-environment-matrix@main
   # Optional inputs
   with:
     available-environments: qa, staging, production # this is the default value
 # Use the output value in a different step
 - run: echo ${{ steps.select-environments.outputs.environments }}
```
Used in: [Find](https://github.com/DFE-Digital/find-teacher-training/blob/master/.github/workflows/deploy.yml#L29), [Publish](https://github.com/DFE-Digital/publish-teacher-training/blob/master/.github/workflows/deploy.yml#L29) & [Teacher Training API](https://github.com/DFE-Digital/teacher-training-api/blob/master/.github/workflows/deploy.yml#L29)

## Setup Cloud Foundry CLI
Installs the Cloud Foundry CLI and logs the specified user into `CF_SPACE_NAME`.
### Usage
```yml
 - uses: DFE-Digital/bat-infrastructure/actions/setup-cf-cli@main
   with:
     CF_USERNAME: ${{ secrets.CF_USERNAME }}
     CF_PASSWORD: ${{ secrets.CF_PASSWORD }}
     CF_SPACE_NAME: bat-qa # required
     # Optional inputs
     CF_CLI_VERSION: v7 # default v7, allowed values: v6 or v7
     CF_ORG_NAME: dfe-teacher-services # default
     CF_API_URL:  https://api.london.cloud.service.gov.uk # default
     INSTALL_CONDUIT: true # default: false
```
