locals {
  auth_server_api_clients_app_env_vars = merge([
    for i, v in local.infrastructure_secrets.API_CLIENTS : merge({
      "ApiClients__${i}__ClientId" = v.CLIENT_ID
      }, merge([
        for k, x in v.API_KEYS : {
          "ApiClients__${i}__ApiKeys__${k}" = x
        }
    ]...))
  ]...)

  auth_server_notify_domain_allow_list_env_vars = merge([
    for i, v in lookup(local.infrastructure_secrets, "NOTIFY_DOMAIN_ALLOW_LIST", []) : {
      "Notify__DomainAllowList__${i}" = v
    }
  ]...)

  auth_server_env_vars = merge(
    local.auth_server_api_clients_app_env_vars,
    local.auth_server_notify_domain_allow_list_env_vars,
    {
      EnvironmentName                              = local.hosting_environment,
      ApplicationInsights__ConnectionString        = azurerm_application_insights.insights.connection_string
      ConnectionStrings__DefaultConnection         = "Server=${local.postgres_server_name}.postgres.database.azure.com;User Id=${local.infrastructure_secrets.POSTGRES_ADMIN_USERNAME};Password=${local.infrastructure_secrets.POSTGRES_ADMIN_PASSWORD};Database=${local.postgres_database_name};Port=5432;Trust Server Certificate=true;"
      ConnectionStrings__Redis                     = azurerm_redis_cache.redis.primary_connection_string,
      ConnectionStrings__DataProtectionBlobStorage = "DefaultEndpointsProtocol=https;AccountName=${azurerm_storage_account.data-protection.name};AccountKey=${azurerm_storage_account.data-protection.primary_access_key}"
      ConnectionStrings__ServiceBus                = azurerm_servicebus_namespace.sb_namespace.default_primary_connection_string
      DataProtectionKeysContainerName              = azurerm_storage_container.keys.name,
      DOCKER_REGISTRY_SERVER_URL                   = "https://ghcr.io",
      DfeAnalytics__CredentialsJson                = local.infrastructure_secrets.ANALYTICS_CREDENTIALS
      DfeAnalytics__DatasetId                      = local.infrastructure_secrets.ANALYTICS_DATASETID
      EncryptionKeys__0                            = local.infrastructure_secrets.ENCRYPTION_KEY0,
      EncryptionKeys__1                            = local.infrastructure_secrets.ENCRYPTION_KEY1,
      SigningKeys__0                               = local.infrastructure_secrets.SIGNING_KEY0,
      SigningKeys__1                               = local.infrastructure_secrets.SIGNING_KEY1,
      Notify__ApiKey                               = local.infrastructure_secrets.NOTIFY_API_KEY,
      Notify__ApplyDomainFiltering                 = lookup(local.infrastructure_secrets, "NOTIFY_APPLY_DOMAIN_FILTERING", "false")
      Notify__NoSendApiKey                         = lookup(local.infrastructure_secrets, "NOTIFY_NO_SEND_API_KEY", "")
      AdminCredentials__Username                   = local.infrastructure_secrets.ADMIN_CREDENTIALS_USERNAME,
      AdminCredentials__Password                   = local.infrastructure_secrets.ADMIN_CREDENTIALS_PASSWORD,
      Sentry__Dsn                                  = local.infrastructure_secrets.SENTRY_DSN,
      FindALostTrnIntegration__HandoverEndpoint    = local.infrastructure_secrets.FIND_HANDOVER_ENDPOINT,
      FindALostTrnIntegration__EnableStubEndpoints = local.infrastructure_secrets.FIND_ENABLE_STUB_ENDPOINTS,
      FindALostTrnIntegration__SharedKey           = local.infrastructure_secrets.FIND_SHARED_KEY,
      DqtApi__ApiKey                               = local.infrastructure_secrets.DQT_API_KEY,
      DqtApi__BaseAddress                          = local.infrastructure_secrets.DQT_API_BASE_ADDRESS,
      WebHooks__QueueName                          = azurerm_servicebus_queue.webhooks.name
      Serilog__WriteTo__2__Args__uri               = local.infrastructure_secrets.LOGSTASH_ENDPOINT
      WEBSITE_SWAP_WARMUP_PING_PATH                = "/status"
      WEBSITE_SWAP_WARMUP_PING_STATUSES            = "200"
    }
  )

  test_client_env_vars = {
    ClientId                   = "testclient",
    ClientSecret               = local.infrastructure_secrets.TESTCLIENT_SECRET,
    DOCKER_REGISTRY_SERVER_URL = "https://ghcr.io",
    SignInAuthority            = "https://${var.domain}"
  }
}

data "azurerm_linux_web_app" "auth-server-app" {
  provider            = azurerm
  name                = local.auth_server_app_name
  resource_group_name = data.azurerm_resource_group.group.name
}

resource "azurerm_postgresql_flexible_server" "postgres-server" {
  name                   = local.postgres_server_name
  location               = data.azurerm_resource_group.group.location
  resource_group_name    = data.azurerm_resource_group.group.name
  version                = 12
  administrator_login    = local.infrastructure_secrets.POSTGRES_ADMIN_USERNAME
  administrator_password = local.infrastructure_secrets.POSTGRES_ADMIN_PASSWORD
  create_mode            = "Default"
  storage_mb             = var.postgres_flexible_server_storage_mb
  sku_name               = var.postgres_flexible_server_sku
  dynamic "high_availability" {
    for_each = var.enable_postgres_high_availability ? [1] : []
    content {
      mode = "ZoneRedundant"
    }
  }
  lifecycle {
    ignore_changes = [
      tags,
      # Allow Azure to manage deployment zone. Ignore changes.
      zone,
      # Allow Azure to manage primary and standby server on fail-over. Ignore changes.
      high_availability[0].standby_availability_zone
    ]
  }
}

resource "azurerm_postgresql_flexible_server_database" "postgres-database" {
  name      = local.postgres_database_name
  server_id = azurerm_postgresql_flexible_server.postgres-server.id
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "postgres-fw-rule-azure" {
  name             = "AllowAzure"
  server_id        = azurerm_postgresql_flexible_server.postgres-server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_redis_cache" "redis" {
  name                = local.redis_database_name
  location            = data.azurerm_resource_group.group.location
  resource_group_name = data.azurerm_resource_group.group.name
  capacity            = var.redis_service_capacity
  family              = var.redis_service_family
  sku_name            = var.redis_service_sku
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"
  redis_version       = var.redis_service_version

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_log_analytics_workspace" "analytics" {
  name                = local.log_analytics_workspace_name
  location            = data.azurerm_resource_group.group.location
  resource_group_name = data.azurerm_resource_group.group.name
  sku                 = var.log_analytics_sku
  retention_in_days   = local.storage_log_retention_days

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_application_insights" "insights" {
  name                 = local.app_insights_name
  location             = data.azurerm_resource_group.group.location
  resource_group_name  = data.azurerm_resource_group.group.name
  application_type     = "web"
  daily_data_cap_in_gb = var.application_insights_daily_data_cap_mb
  retention_in_days    = var.application_insights_retention_days

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
resource "azurerm_service_plan" "service-plan" {
  name                   = local.app_service_plan_name
  location               = data.azurerm_resource_group.group.location
  resource_group_name    = data.azurerm_resource_group.group.name
  os_type                = "Linux"
  sku_name               = var.app_service_plan_sku
  zone_balancing_enabled = var.worker_count != null ? true : false
  worker_count           = var.worker_count
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_linux_web_app" "auth-server-app" {
  name                = local.auth_server_app_name
  location            = data.azurerm_resource_group.group.location
  resource_group_name = data.azurerm_resource_group.group.name
  service_plan_id     = azurerm_service_plan.service-plan.id
  https_only          = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    http2_enabled       = true
    minimum_tls_version = "1.2"
    health_check_path   = "/health"
    #All ip_restriction properties need to be included due to the bug raised here: https://github.com/hashicorp/terraform-provider-azurerm/issues/17189
    ip_restriction = [{
      name     = "FrontDoor"
      action   = "Allow"
      priority = 1
      headers = [{
        x_azure_fdid      = [local.infrastructure_secrets.FRONTDOOR_ID]
        x_fd_health_probe = []
        x_forwarded_for   = []
        x_forwarded_host  = []
      }]
      service_tag               = "AzureFrontDoor.Backend"
      ip_address                = null
      virtual_network_subnet_id = null
    }]
  }

  sticky_settings {
    app_setting_names = keys(data.azurerm_linux_web_app.auth-server-app.app_settings)
  }

  app_settings = data.azurerm_linux_web_app.auth-server-app.app_settings

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_linux_web_app_slot" "auth-server-stage" {
  count          = var.enable_blue_green ? 1 : 0
  name           = local.web_app_slot_name
  app_service_id = azurerm_linux_web_app.auth-server-app.id
  site_config {
    http2_enabled       = true
    minimum_tls_version = "1.2"
    health_check_path   = "/health"
  }
  app_settings = local.auth_server_env_vars
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}


resource "azurerm_linux_web_app" "test-client-app" {
  count               = var.deploy_test_client_app ? 1 : 0
  name                = local.test_client_app_name
  location            = data.azurerm_resource_group.group.location
  resource_group_name = data.azurerm_resource_group.group.name
  service_plan_id     = azurerm_service_plan.service-plan.id
  https_only          = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    http2_enabled       = true
    minimum_tls_version = "1.2"
    application_stack {
      docker_image     = var.docker_image
      docker_image_tag = var.testclient_tag
    }
  }

  app_settings = local.test_client_env_vars

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_servicebus_namespace" "sb_namespace" {
  name                = local.servicebus_namespace_name
  location            = data.azurerm_resource_group.group.location
  resource_group_name = data.azurerm_resource_group.group.name
  sku                 = "Standard"

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_servicebus_queue" "webhooks" {
  name         = "webhooks"
  namespace_id = azurerm_servicebus_namespace.sb_namespace.id
}
