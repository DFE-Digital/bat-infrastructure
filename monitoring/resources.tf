module "prometheus_all" {
  source = "git::https://github.com/DFE-Digital/cf-monitoring//prometheus_all"

  monitoring_instance_name = var.monitoring_instance_name
  monitoring_org_name      = data.cloudfoundry_org.dfe.name
  monitoring_space_name    = var.monitoring_space_name

  paas_exporter_username = local.infra_secrets["PAAS_EXPORTER_USERNAME"]
  paas_exporter_password = local.infra_secrets["PAAS_EXPORTER_PASSWORD"]

  prometheus_disk_quota = 5120
  prometheus_memory     = 4096
  internal_apps         = var.internal_apps

  grafana_admin_password       = local.infra_secrets["GRAFANA_ADMIN_PASSWORD"]
  grafana_google_client_id     = local.infra_secrets["GRAFANA_GOOGLE_CLIENT_ID"]
  grafana_google_client_secret = local.infra_secrets["GRAFANA_GOOGLE_CLIENT_SECRET"]
  grafana_runtime_version      = "7.5.11"
  grafana_json_dashboards      = [file("dashboards/bat_runtime.json")]

  alert_rules            = local.alert_rules
  alertmanager_slack_url = local.infra_secrets["SLACK_WEBHOOK"]

  influxdb_service_plan = var.influxdb_service_plan

  redis_services    = local.redis_services
  postgres_services = var.postgres_services

  enable_prometheus_yearly = true
}
