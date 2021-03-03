variable paas_user {}

variable paas_password {}

variable paas_sso_code { default = "" }

variable paas_exporter_username {}

variable paas_exporter_password {}

variable grafana_admin_password {}

variable grafana_google_client_id {}

variable grafana_google_client_secret {}

variable monitoring_space_name {}

variable monitoring_instance_name {}

variable influxdb_service_plan {}

locals {
  paas_api_url = "https://api.london.cloud.service.gov.uk"
}
