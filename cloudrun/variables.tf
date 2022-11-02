variable "container_port" { default = 8080 }

variable "container_memory" { default = "512M" }

variable "container_cpu" { default = 1 }

variable "min_instances" { default = 0 }

variable "max_instances" { default = 2 }

variable "azure_credentials" { default = null }
variable "GOOGLE_CREDENTIALS" { default = null }
variable "GOOGLE_PROJECT" { default = null }
variable "GOOGLE_REGION" { default = null }
variable "GOOGLE_ZONE" { default = null }

variable "key_vault_name" {}
variable "key_vault_resource_group" {}
variable "key_vault_infra_secret_name" {}

variable "app_name" {}

locals {
  azure_credentials          = try(jsondecode(var.azure_credentials), null)
  GOOGLE_CREDENTIALS         = try(jsondecode(var.GOOGLE_CREDENTIALS), null)
  infra_secrets              = yamldecode(data.azurerm_key_vault_secret.infra_secrets.value)
  app_name                   = var.app_name
}
