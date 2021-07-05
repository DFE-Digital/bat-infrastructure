variable "cf_user" {}

variable "cf_password" {}

variable "cf_space" {}

variable "app_instances" { default = 1 }

variable "app_memory" { default = 1024 }

variable "sqlpad_admin" {}

variable "sqlpad_google_client_id" {}

variable "sqlpad_google_client_secret" {}

variable "connections" {}

locals {
  cf_api_url       = "https://api.london.cloud.service.gov.uk"
  app_docker_image = "sqlpad/sqlpad:6.7.1"
  app_name         = "bat-sqlpad"
  postgres_name    = "bat-sqlpad-postgres"

  sqlpad_connections = [
    for index, connection in jsondecode(var.connections) :
    {
      for key, value in connection :
      "SQLPAD_CONNECTIONS__${connection.id}__${key}" => value
    }
  ]
  connection_keys   = flatten([for c in local.sqlpad_connections : [for k, v in c : k]])
  connection_values = flatten([for c in local.sqlpad_connections : [for k, v in c : v]])
  connections       = zipmap(local.connection_keys, local.connection_values)

  app_env_variables = merge({
    SQLPAD_ADMIN                  = var.sqlpad_admin
    SQLPAD_ADMIN_PASSWORD         = ""
    SQLPAD_BACKEND_DB_URI         = "${cloudfoundry_service_key.postgres_service_key.credentials.uri}?ssl=no-verify"
    SQLPAD_QUERY_RESULT_MAX_ROWS  = 100000
    SQLPAD_USERPASS_AUTH_DISABLED = true
    PUBLIC_URL                    = "https://${cloudfoundry_route.web_app_cloudapps_digital_route.endpoint}"
    SQLPAD_GOOGLE_CLIENT_ID       = var.sqlpad_google_client_id
    SQLPAD_GOOGLE_CLIENT_SECRET   = var.sqlpad_google_client_secret
  }, local.connections)
}
