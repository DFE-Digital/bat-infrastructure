# Container App POC

Testing for suitability of Container Apps as a PaaS replacement

https://www.thorsten-hans.com/deploy-azure-container-apps-with-terraform/

## Installation

Install Terraform 1.3.6
`brew install tfenv`
`tfenv install 1.3.6`
`tfenve use 1.3.6`

### Set Azure Subscription

`az login` to an Azure subscription you can create resources in and update the AZ_SUBSCRIPTION value in the `poc.mk` file with the subscription name

### Create Terraform Backend
Create the backend resource group, storage account and key vault
Execute `make poc deploy-azure-resources AUTO_APPROVE=1`

### Deploy Container Environment & Apps
Add details to container_apps object in poc.tfvars.json to create more containers
Execute `make poc terraform-apply`
