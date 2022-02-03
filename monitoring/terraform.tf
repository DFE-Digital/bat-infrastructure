terraform {
  required_version = "~> 0.15.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.62.0"
    }
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = "0.14.2"
    }
  }
  backend "azurerm" {
  }
  experiments = [module_variable_optional_attrs]
}

provider "cloudfoundry" {
  api_url           = local.paas_api_url
  user              = var.paas_sso_passcode == "" ? local.infra_secrets.CF_USER : null
  password          = var.paas_sso_passcode == "" ? local.infra_secrets.CF_PASSWORD : null
  sso_passcode      = var.paas_sso_passcode != "" ? var.paas_sso_passcode : null
  store_tokens_path = var.paas_sso_passcode != "" ? ".cftoken" : null
}

provider "azurerm" {
  features {}

  skip_provider_registration = true
  subscription_id            = try(local.azure_credentials.subscriptionId, null)
  client_id                  = try(local.azure_credentials.clientId, null)
  client_secret              = try(local.azure_credentials.clientSecret, null)
  tenant_id                  = try(local.azure_credentials.tenantId, null)
}
