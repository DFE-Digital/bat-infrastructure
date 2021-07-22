module "prometheus_all" {
  source = "git::https://github.com/DFE-Digital/cf-monitoring//prometheus_all"

  enabled_modules          = ["paas_prometheus_exporter", "prometheus", "grafana", "influxdb", "alertmanager"]
  monitoring_instance_name = var.monitoring_instance_name
  monitoring_org_name      = data.cloudfoundry_org.dfe.name
  monitoring_space_name    = var.monitoring_space_name

  paas_exporter_username = var.paas_exporter_username
  paas_exporter_password = var.paas_exporter_password

  prometheus_disk_quota = 2048
  prometheus_memory     = 4096
  internal_apps         = var.internal_apps

  grafana_admin_password       = var.grafana_admin_password
  grafana_google_client_id     = var.grafana_google_client_id
  grafana_google_client_secret = var.grafana_google_client_secret
  grafana_runtime_version      = "7.2.2"

  alert_rules            = local.alert_rules
  alertmanager_slack_url = var.alertmanager_slack_url

  influxdb_service_plan = var.influxdb_service_plan

  redis_services    = var.redis_services
  postgres_services = var.postgres_services
}
