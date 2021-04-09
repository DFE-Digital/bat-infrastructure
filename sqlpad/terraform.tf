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
  api_url  = local.cf_api_url
  user     = var.cf_user
  password = var.cf_password
}
