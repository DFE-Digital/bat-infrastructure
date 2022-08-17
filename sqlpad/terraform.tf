terraform {
  required_version = "~> 0.14.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.53.0"
    }
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = "0.13.0"
    }
  }
  backend "azurerm" {
  }
}

provider "cloudfoundry" {
  api_url           = local.cf_api_url
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
