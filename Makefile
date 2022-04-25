ifndef VERBOSE
.SILENT:
endif

qa:
	$(eval DEPLOY_ENV=qa)
	$(eval AZURE_SUBSCRIPTION=s121-findpostgraduateteachertraining-development)

prod:
	$(if $(CONFIRM_PRODUCTION), , $(error Production can only run with CONFIRM_PRODUCTION))
	$(eval DEPLOY_ENV=prod)
	$(eval AZURE_SUBSCRIPTION=s121-findpostgraduateteachertraining-production)

ci:	## Run in automation environment
	$(eval export DISABLE_PASSCODE=true)
	$(eval export AUTO_APPROVE=-auto-approve)

register:
	$(eval DNS_ZONE=register)
	$(eval AZURE_SUBSCRIPTION=s121-findpostgraduateteachertraining-production)

set-azure-account:
	az account set -s $(AZURE_SUBSCRIPTION)

monitoring-init: set-azure-account
	$(if $(or $(DISABLE_PASSCODE),$(PASSCODE)), , $(error Missing environment variable "PASSCODE", retrieve from https://login.london.cloud.service.gov.uk/passcode))
	cd monitoring && terraform init -backend-config workspace-variables/backend_${DEPLOY_ENV}.tfvars -upgrade -reconfigure

monitoring-plan: monitoring-init
	cd monitoring && terraform plan -var-file workspace-variables/${DEPLOY_ENV}.tfvars.json

monitoring-apply: monitoring-init
	cd monitoring && terraform apply -var-file workspace-variables/${DEPLOY_ENV}.tfvars.json ${AUTO_APPROVE}

dnszone-init: set-azure-account
	echo "Setting up DNS zone for $(DNS_ZONE) in subscription $(AZURE_SUBSCRIPTION)"
	az account show
	cd dns/zones && terraform init -backend-config workspace-variables/backend_${DNS_ZONE}.tfvars -upgrade -reconfigure

dnszone-plan: dnszone-init
	cd dns/zones && terraform plan -var-file workspace-variables/${DNS_ZONE}-zone.tfvars.json

dnszone-apply: dnszone-init
	cd dns/zones && terraform apply -var-file workspace-variables/${DNS_ZONE}-zone.tfvars.json ${AUTO_APPROVE}

dnsrecord-init: set-azure-account
	$(if $(DNS_ENV), , $(error must supply domain environment DNS_ENV))
	echo "Setting up DNS for $(DNS_ZONE) $(DNS_ENV) in subscription $(AZURE_SUBSCRIPTION)"
	az account show
	cd dns/records && terraform init -backend-config workspace-variables/backend_${DNS_ZONE}_${DNS_ENV}.tfvars -upgrade -reconfigure

dnsrecord-plan: dnsrecord-init
	cd dns/records && terraform plan -var-file workspace-variables/${DNS_ZONE}_${DNS_ENV}.tfvars.json

dnsrecord-apply: dnsrecord-init
	cd dns/records && terraform apply -var-file workspace-variables/${DNS_ZONE}_${DNS_ENV}.tfvars.json ${AUTO_APPROVE}

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
