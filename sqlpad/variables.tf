variable "app_instances" { default = 1 }

variable "app_memory" { default = 1024 }

variable "sqlpad_admin" { default = "admin" }

variable "app_name" {}

variable "app_env" {}

variable "postgres_name" {}

variable "paas_space_name" {}

variable "paas_sso_passcode" { default = "" }

variable "azure_credentials" { default = null }

variable "key_vault_name" {}
variable "key_vault_resource_group" {}
variable "key_vault_infra_secret_name" {}

locals {
  cf_api_url                 = "https://api.london.cloud.service.gov.uk"
  app_docker_image           = "sqlpad/sqlpad:6.11.1"
  app_name                   = var.app_name
  postgres_name              = var.postgres_name
  azure_credentials          = try(jsondecode(var.azure_credentials), null)
  infra_secrets              = yamldecode(data.azurerm_key_vault_secret.infra_secrets.value)

  app_env_variables = {
    SQLPAD_ADMIN                  = var.sqlpad_admin
    SQLPAD_ADMIN_PASSWORD         = local.infra_secrets["SQLPAD_ADMIN_PASSWORD"]
    SQLPAD_BACKEND_DB_URI         = "${cloudfoundry_service_key.postgres_service_key.credentials.uri}?ssl=no-verify"
    SQLPAD_QUERY_RESULT_MAX_ROWS  = 100000
    SQLPAD_USERPASS_AUTH_DISABLED = true
    PUBLIC_URL                    = "https://${cloudfoundry_route.web_app_cloudapps_digital_route.endpoint}"
    SQLPAD_GOOGLE_CLIENT_ID       = local.infra_secrets["SQLPAD_GOOGLE_CLIENT_ID"]
    SQLPAD_GOOGLE_CLIENT_SECRET   = local.infra_secrets["SQLPAD_GOOGLE_CLIENT_SECRET"]
  }

}
