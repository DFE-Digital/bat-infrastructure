# Container App POC

Testing for suitability of Container Apps as a PaaS replacement

https://www.thorsten-hans.com/deploy-azure-container-apps-with-terraform/

## Installation

### Create Terraform Backend
pwsh

#### If you need some existing tags
$rg = az group show -n s121d01-apply-rg |  ConvertFrom-Json
$tags = $rg.tags


$backend = Get-Content ./containerapp/workspace_variables/qa_backend.tfvars | ConvertFrom-StringData
az group create -n $backend.resource_group_name -l westeurope
az storage account create -n $backend.storage_account_name -g $backend.resource_group_name
az storage container create -n $backend.container_name --account-name $backend.storage_account_name

### User configuration

cd containerapp
terraform init -reconfigure -backend-config=workspace_variables/qa_backend.tfvars
terraform plan -var-file=workspace_variables/qa.tfvars.json -var-file=workspace_variables/qa_backend.tfvars

### Required terraform variables
