module prometheus_all {
  source = "git::https://github.com/DFE-Digital/cf-monitoring//prometheus_all"

  enabled_modules          = ["paas_prometheus_exporter", "prometheus", "grafana", "influxdb", "alertmanager"]
  monitoring_instance_name = var.monitoring_instance_name
  monitoring_org_name      = data.cloudfoundry_org.dfe.name
  monitoring_space_name    = var.monitoring_space_name

  paas_exporter_username = var.paas_exporter_username
  paas_exporter_password = var.paas_exporter_password

  grafana_admin_password       = var.grafana_admin_password
  grafana_google_client_id     = var.grafana_google_client_id
  grafana_google_client_secret = var.grafana_google_client_secret
  grafana_json_dashboards      = [file("./grafana_dashboards/production_dashboard.json"), file("./grafana_dashboards/qa_dashboard.json")]

  alert_rules = file("./config/alert.rules")

  influxdb_service_plan = var.influxdb_service_plan
}
