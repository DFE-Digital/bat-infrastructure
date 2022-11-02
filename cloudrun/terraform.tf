terraform {
  required_version = "~> 1.2.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.53.0"
    }
    google = {
      source = "hashicorp/google"
      version = "4.40.0"
    }
  }
  backend "azurerm" {
  }
}

# see https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference
# all below optional
#  project = "{{YOUR GCP PROJECT}}"
#  region  = "us-central1"
#  zone    = "us-central1-c"

provider "google" {
  project            = try(var.GOOGLE_PROJECT, null)
  region             = try(var.GOOGLE_REGION, null)
  zone               = try(var.GOOGLE_ZONE, null)
  credentials        = try(local.GOOGLE_CREDENTIALS, null)
}

provider "azurerm" {
  features {}

  skip_provider_registration = true
  subscription_id            = try(local.azure_credentials.subscriptionId, null)
  client_id                  = try(local.azure_credentials.clientId, null)
  client_secret              = try(local.azure_credentials.clientSecret, null)
  tenant_id                  = try(local.azure_credentials.tenantId, null)
}
