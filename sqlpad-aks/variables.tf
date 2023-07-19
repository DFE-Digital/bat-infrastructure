variable "cluster" {}
variable "namespace" {}
variable "environment" {}
variable "azure_credentials_json" { default = null }
variable "azure_resource_prefix" {}
variable "config_short" {}
variable "service_short" {}
variable "deploy_azure_backing_services" { default = true }
variable "dns_suffix" {}
variable "rg_name" {}
variable "enable_postgres_ssl" { default = true }
variable "max_memory"  { default = "1Gi" }

locals {
  service_name = "sqlpad"
  version      = "6.11.4"

  azure_credentials = try(jsondecode(var.azure_credentials_json), null)

  main_web_domain   = "sqlpad.${var.dns_suffix}"
  postgres_ssl_mode = var.enable_postgres_ssl ? "require" : "disable"
}
