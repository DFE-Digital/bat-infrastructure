ifndef VERBOSE
.SILENT:
endif

TERRAFILE_VERSION=0.8
ARM_TEMPLATE_TAG=1.1.0
RG_TAGS={"Product" : "Teacher services cloud"}
SERVICE_SHORT=sqlpad

install-terrafile: ## Install terrafile to manage terraform modules
	[ ! -f bin/terrafile ] \
		&& curl -sL https://github.com/coretech/terrafile/releases/download/v${TERRAFILE_VERSION}/terrafile_${TERRAFILE_VERSION}_$$(uname)_x86_64.tar.gz \
		| tar xz -C ./bin terrafile \
		|| true

install-konduit: ## Install the konduit script, for accessing backend services
	[ ! -f bin/konduit.sh ] \
		&& curl -s https://raw.githubusercontent.com/DFE-Digital/teacher-services-cloud/master/scripts/konduit.sh -o bin/konduit.sh \
		&& chmod +x bin/konduit.sh \
		|| true

qa:
	$(eval DEPLOY_ENV=qa)
	$(eval AZURE_SUBSCRIPTION=s121-findpostgraduateteachertraining-development)

prod:
	$(if $(CONFIRM_PRODUCTION), , $(error Production can only run with CONFIRM_PRODUCTION))
	$(eval DEPLOY_ENV=prod)
	$(eval AZURE_SUBSCRIPTION=s121-findpostgraduateteachertraining-production)

qa_aks:
	$(eval include global_config/qa_aks.sh)

production_aks:
	$(eval include global_config/production_aks.sh)
	$(if $(CONFIRM_PRODUCTION), , $(error Can only run with CONFIRM_PRODUCTION))

ci:	## Run in automation environment
	$(eval export DISABLE_PASSCODE=true)
	$(eval export AUTO_APPROVE=-auto-approve)

set-azure-account:
	az account set -s $(AZURE_SUBSCRIPTION)

monitoring-init: set-azure-account
	$(if $(or $(DISABLE_PASSCODE),$(PASSCODE)), , $(error Missing environment variable "PASSCODE", retrieve from https://login.london.cloud.service.gov.uk/passcode))
	cd monitoring && terraform init -backend-config workspace-variables/backend_${DEPLOY_ENV}.tfvars -upgrade -reconfigure

monitoring-plan: monitoring-init
	cd monitoring && terraform plan -var-file workspace-variables/${DEPLOY_ENV}.tfvars.json

monitoring-apply: monitoring-init
	cd monitoring && terraform apply -var-file workspace-variables/${DEPLOY_ENV}.tfvars.json ${AUTO_APPROVE}

sqlpad-init: set-azure-account
	$(if $(or $(DISABLE_PASSCODE),$(PASSCODE)), , $(error Missing environment variable "PASSCODE", retrieve from https://login.london.cloud.service.gov.uk/passcode))
	terraform -chdir=sqlpad init -backend-config workspace_variables/backend_${DEPLOY_ENV}.tfvars -upgrade -reconfigure

sqlpad-plan: sqlpad-init
	terraform -chdir=sqlpad plan -var-file workspace_variables/${DEPLOY_ENV}.tfvars.json

sqlpad-apply: sqlpad-init
	terraform -chdir=sqlpad apply -var-file workspace_variables/${DEPLOY_ENV}.tfvars.json ${AUTO_APPROVE}

sqlpad-destroy: sqlpad-init
	terraform -chdir=sqlpad destroy -var-file workspace_variables/${DEPLOY_ENV}.tfvars.json ${AUTO_APPROVE}

.PHONY: install-fetch-config
install-fetch-config: ## Install the fetch-config script, for viewing/editing secrets in Azure Key Vault
	[ ! -f bin/fetch_config.rb ] \
		&& curl -s https://raw.githubusercontent.com/DFE-Digital/bat-platform-building-blocks/master/scripts/fetch_config/fetch_config.rb -o bin/fetch_config.rb \
		&& chmod +x bin/fetch_config.rb \
		|| true

read-keyvault-config:
	jq -r '.key_vault_name' monitoring/workspace-variables/$(DEPLOY_ENV).tfvars.json
	$(eval export key_vault_name=$(shell jq -r '.key_vault_name' monitoring/workspace-variables/$(DEPLOY_ENV).tfvars.json))
	$(eval key_vault_app_secret_name=$(shell jq -r '.key_vault_app_secret_name' monitoring/workspace-variables/$(DEPLOY_ENV).tfvars.json))
	$(eval key_vault_infra_secret_name=$(shell jq -r '.key_vault_infra_secret_name' monitoring/workspace-variables/$(DEPLOY_ENV).tfvars.json))

edit-infra-secrets: read-keyvault-config install-fetch-config set-azure-account
	bin/fetch_config.rb -s azure-key-vault-secret:${key_vault_name}/${key_vault_infra_secret_name} \
		-e -d azure-key-vault-secret:${key_vault_name}/${key_vault_infra_secret_name} -f yaml -c

print-infra-secrets: read-keyvault-config install-fetch-config set-azure-account
	bin/fetch_config.rb -s azure-key-vault-secret:${key_vault_name}/${key_vault_infra_secret_name} -f yaml

validate-infra-secrets: read-keyvault-config install-fetch-config set-azure-account
	bin/fetch_config.rb -s azure-key-vault-secret:${key_vault_name}/${key_vault_infra_secret_name} -d quiet \
		&& echo Data in ${key_vault_name}/${key_vault_infra_secret_name} looks valid

sqlpad-init-aks: install-terrafile set-azure-account
	./bin/terrafile -p sqlpad-aks/vendor/modules -f sqlpad-aks/config/$(CONFIG)_Terrafile
	terraform -chdir=sqlpad-aks init -upgrade -reconfigure \
		-backend-config=resource_group_name=${RESOURCE_GROUP_NAME} \
		-backend-config=storage_account_name=${STORAGE_ACCOUNT_NAME} \
		-backend-config=key=${ENVIRONMENT}_kubernetes.tfstate

	$(eval export TF_VAR_azure_resource_prefix=$(AZURE_RESOURCE_PREFIX))
	$(eval export TF_VAR_config_short=$(CONFIG_SHORT))
	$(eval export TF_VAR_service_short=$(SERVICE_SHORT))
	$(eval export TF_VAR_rg_name=$(RESOURCE_GROUP_NAME))

sqlpad-plan-aks: sqlpad-init-aks
	terraform -chdir=sqlpad-aks plan -var-file "config/${CONFIG}.tfvars.json"

sqlpad-apply-aks: sqlpad-init-aks
	terraform -chdir=sqlpad-aks apply -var-file "config/${CONFIG}.tfvars.json"

set-what-if:
	$(eval WHAT_IF=--what-if)

arm-deployment: set-azure-account
	az deployment sub create --name "resourcedeploy-tsc-$(shell date +%Y%m%d%H%M%S)" \
		-l "UK South" --template-uri "https://raw.githubusercontent.com/DFE-Digital/tra-shared-services/${ARM_TEMPLATE_TAG}/azure/resourcedeploy.json" \
		--parameters "resourceGroupName=${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-rg" 'tags=${RG_TAGS}' \
			"tfStorageAccountName=${AZURE_RESOURCE_PREFIX}${SERVICE_SHORT}tfstate${CONFIG_SHORT}sa" "tfStorageContainerName=terraform-state" \
			"keyVaultName=${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-kv" ${WHAT_IF}

deploy-arm-resources: arm-deployment

validate-arm-resources: set-what-if arm-deployment

read-cluster-config:
	$(eval CLUSTER=$(shell jq -r '.cluster' sqlpad-aks/config/$(CONFIG).tfvars.json))
	$(eval NAMESPACE=$(shell jq -r '.namespace' sqlpad-aks/config/$(CONFIG).tfvars.json))

get-cluster-credentials: read-cluster-config set-azure-account ## make <config> get-cluster-credentials [ENVIRONMENT=<clusterX>]
	az aks get-credentials --overwrite-existing -g ${AZURE_RESOURCE_PREFIX}-tsc-${CLUSTER_SHORT}-rg -n ${AZURE_RESOURCE_PREFIX}-tsc-${CLUSTER}-aks
	kubelogin convert-kubeconfig -l $(if ${GITHUB_ACTIONS},spn,azurecli)

ssh: get-cluster-credentials
	$(if $(APP_NAME), $(eval export APP_ID=$(APP_NAME)) , $(eval export APP_ID=$(CONFIG)))
	kubectl -n ${NAMESPACE} exec -ti --tty deployment/sqlpad-${APP_ID} -- /bin/sh

logs: get-cluster-credentials
	$(if $(APP_NAME), $(eval export APP_ID=$(APP_NAME)) , $(eval export APP_ID=$(CONFIG)))
	kubectl -n ${NAMESPACE} logs -l app=sqlpad-${APP_ID} --tail=-1 --timestamps=true
