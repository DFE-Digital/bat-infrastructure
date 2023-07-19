module "application_configuration" {
  source = "./vendor/modules/aks//aks/application_configuration"

  namespace             = var.namespace
  environment           = var.environment
  azure_resource_prefix = var.azure_resource_prefix
  service_short         = var.service_short
  config_short          = var.config_short

  config_variables = {
    PGSSLMODE             = local.postgres_ssl_mode
  }
  secret_variables = {
    SQLPAD_ADMIN_PASSWORD         = module.infrastructure_secrets.map.SQLPAD-ADMIN-PASSWORD
    SQLPAD_ADMIN                  = module.infrastructure_secrets.map.SQLPAD-ADMIN-ID
    SQLPAD_BACKEND_DB_URI         = module.postgres.url
    SQLPAD_QUERY_RESULT_MAX_ROWS  = 100000
    SQLPAD_USERPASS_AUTH_DISABLED = false
    PUBLIC_URL                    = module.web_application.hostname
  }
}

module "web_application" {
  source = "./vendor/modules/aks//aks/application"

  is_web = true

  namespace    = var.namespace
  environment  = var.environment
  service_name = local.service_name

  cluster_configuration_map  = module.cluster_data.configuration_map
  kubernetes_config_map_name = module.application_configuration.kubernetes_config_map_name
  kubernetes_secret_name     = module.application_configuration.kubernetes_secret_name

  docker_image           = "sqlpad/sqlpad:${local.version}"
  probe_path             = null
  max_memory             = var.max_memory
}

module "infrastructure_secrets" {
  source = "./vendor/modules/aks//aks/secrets"

  azure_resource_prefix = var.azure_resource_prefix
  service_short         = var.service_short
  config_short          = var.config_short
  key_vault_short       = null
}
