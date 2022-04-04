variable "paas_sso_passcode" { default = "" }

variable "monitoring_space_name" {}
variable "monitoring_instance_name" {}

variable "influxdb_service_plan" {}

variable "alertmanager_app_config" {
  type = map(
    object({
      response_threshold = optional(number)
    })
  )
}

variable "postgres_services" {}
variable "redis_services" {}
variable "alertable_redis_services" {}
variable "alertable_postgres_services" {}

variable "internal_apps" { default = [] }

variable "key_vault_name" {}
variable "key_vault_resource_group" {}
variable "key_vault_infra_secret_name" {}

variable "azure_credentials" { default = null }

locals {
  azure_credentials          = try(jsondecode(var.azure_credentials), null)
  infra_secrets              = yamldecode(data.azurerm_key_vault_secret.infra_secrets.value)
  paas_api_url               = "https://api.london.cloud.service.gov.uk"
  alertmanager_slack_channel = "twd_bat_devops"
  alert_rules_variables = {
    grafana_dashboard_url     = "https://grafana-bat.london.cloudapps.digital/d/eF19g4RZx/cf-apps?orgId=1&refresh=10s&var-SpaceName=${var.monitoring_space_name}"
    redis_dashboard_url       = "https://grafana-bat.london.cloudapps.digital/d/_XaXFGTMz/redis?orgId=1&refresh=30s"
    postgres_dashboard_url    = "https://grafana-bat.london.cloudapps.digital/d/a2FR6FUMz/cf-databases?orgId=1&refresh=1m&var-SpaceName=${var.monitoring_space_name}"
    apps                      = var.alertmanager_app_config
    alertable_redis_instances = [for r in var.alertable_redis_services : split("/", r)[1]]
    alertable_postgres_instances = [for r in var.alertable_postgres_services : split("/", r)[1]]
  }
  alert_rules = templatefile("./config/alert.rules.tmpl", local.alert_rules_variables)

  redis_services = concat(var.redis_services, var.alertable_redis_services)
  postgres_services = concat(var.postgres_services, var.alertable_postgres_services)
  
}
