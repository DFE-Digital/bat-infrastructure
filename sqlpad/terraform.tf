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
  api_url  = local.paas_api_url
  user     = var.paas_user
  password = var.paas_password
}
