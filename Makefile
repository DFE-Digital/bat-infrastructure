ifndef VERBOSE
.SILENT:
endif

ARM_TEMPLATE_TAG=1.1.0
RG_TAGS={"Product" : "Teacher services cloud"}
SERVICE_SHORT=sqlpad

install-konduit: ## Install the konduit script, for accessing backend services
	[ ! -f bin/konduit.sh ] \
		&& curl -s https://raw.githubusercontent.com/DFE-Digital/teacher-services-cloud/master/scripts/konduit.sh -o bin/konduit.sh \
		&& chmod +x bin/konduit.sh \
		|| true

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

.PHONY: install-fetch-config
install-fetch-config: ## Install the fetch-config script, for viewing/editing secrets in Azure Key Vault
	[ ! -f bin/fetch_config.rb ] \
		&& curl -s https://raw.githubusercontent.com/DFE-Digital/bat-platform-building-blocks/master/scripts/fetch_config/fetch_config.rb -o bin/fetch_config.rb \
		&& chmod +x bin/fetch_config.rb \
		|| true

sqlpad-init-aks: set-azure-account
	rm -rf sqlpad-aks/vendor/modules/aks
	git -c advice.detachedHead=false clone --depth=1 --single-branch --branch ${TERRAFORM_MODULES_TAG} https://github.com/DFE-Digital/terraform-modules.git sqlpad-aks/vendor/modules/aks


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
