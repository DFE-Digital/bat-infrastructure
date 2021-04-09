variable "cf_user" {}

variable "cf_password" {}

variable "cf_space" {}

variable "app_instances" { default = 1 }

variable "app_memory" { default = 512 }

variable "sqlpad_admin" {}

variable "sqlpad_google_client_id" {}

variable "sqlpad_google_client_secret" {}

variable "connections" {}

locals {
  cf_api_url       = "https://api.london.cloud.service.gov.uk"
  app_docker_image = "sqlpad/sqlpad:6.5"
  app_name         = "bat-sqlpad"

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
    SQLPAD_USERPASS_AUTH_DISABLED = true
    PUBLIC_URL                    = "https://${cloudfoundry_route.web_app_cloudapps_digital_route.endpoint}"
    SQLPAD_GOOGLE_CLIENT_ID       = var.sqlpad_google_client_id
    SQLPAD_GOOGLE_CLIENT_SECRET   = var.sqlpad_google_client_secret
    ## SQLlite, the backing database for SQLPad
    SQLPAD_CONNECTIONS__sqllite__name                             = "SQLPad"
    SQLPAD_CONNECTIONS__sqllite__driver                           = "sqlite"
    SQLPAD_CONNECTIONS__sqllite__multiStatementTransactionEnabled = true
    SQLPAD_CONNECTIONS__sqllite__filename                         = "/var/lib/sqlpad/sqlpad.sqlite"
    SQLPAD_CONNECTIONS__sqllite__readonly                         = true
  }, local.connections)
}
