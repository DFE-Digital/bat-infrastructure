variable "paas_sso_passcode" { default = "" }

variable "monitoring_space_name" {}
variable "monitoring_instance_name" {}

variable "influxdb_service_plan" {}

variable "alertmanager_app_config" {
  type = map(
    object({
      response_threshold = optional(number)
      response_window    = optional(string)
      receiver = optional(string)
    })
  )
}
variable "alertmanager_receivers" {}

variable "postgres_services" {}
variable "redis_services" {}
variable "alertable_redis_services" {}
variable "alertable_postgres_services" {
  default = {}
}
variable "postgres_dashboard_url" { default = "" }

variable "internal_apps" { default = [] }

variable "key_vault_name" {}
variable "key_vault_resource_group" {}
variable "key_vault_infra_secret_name" {}

variable "azure_credentials" { default = null }

locals {
  azure_credentials          = try(jsondecode(var.azure_credentials), null)
  infra_secrets              = yamldecode(data.azurerm_key_vault_secret.infra_secrets.value)
  paas_api_url               = "https://api.london.cloud.service.gov.uk"
  alertmanager_slack_receivers = { for r in var.alertmanager_receivers : r => local.infra_secrets[r]}
  alert_rules_variables = {
    cfapps_dashboard_url     = "https://grafana-${var.monitoring_instance_name}.london.cloudapps.digital/d/eF19g4RZx/cf-apps?orgId=1&refresh=10s&var-SpaceName=${var.monitoring_space_name}"
    redis_dashboard_url       = "https://grafana-${var.monitoring_instance_name}.london.cloudapps.digital/d/_XaXFGTMz/redis?orgId=1&refresh=30s"
    apps                      = var.alertmanager_app_config
    alertable_redis_instances = [for r in var.alertable_redis_services : split("/", r)[1]]
    monitoring_space_name = var.monitoring_space_name
  }
  alert_rules = templatefile("./config/alert.rules.tmpl", local.alert_rules_variables)

  redis_services = concat(var.redis_services, var.alertable_redis_services)
}
