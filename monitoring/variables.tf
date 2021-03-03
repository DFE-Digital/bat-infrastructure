variable paas_user {}

variable paas_password {}

variable paas_sso_code { default = "" }

variable paas_exporter_username {}

variable paas_exporter_password {}

variable grafana_admin_password {}

variable grafana_google_client_id {}

variable grafana_google_client_secret {}

variable monitoring_env {}

locals {
  paas_api_url             = "https://api.london.cloud.service.gov.uk"
  monitoring_space_name    = "bat-${var.monitoring_env}"
  monitoring_instance_name = var.monitoring_env == "prod" ? "bat" : "bat-${var.monitoring_env}"
  influxdb_service_plan    = var.monitoring_env == "prod" ? "small-1_x" : "tiny-1_x"
}
