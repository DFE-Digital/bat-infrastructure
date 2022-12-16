resource "azurerm_monitor_diagnostic_setting" "getanid-keyvault-diagnostics" {
  name                       = "${data.azurerm_key_vault.vault.name}-diagnostics"
  target_resource_id         = data.azurerm_key_vault.vault.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.analytics.id

  log {
    category = "AuditEvent"
    enabled  = true #at least one Audit/Metric needs to be enabled.

    retention_policy {
      enabled = local.keyvault_logging_enabled
    }
  }


  metric {
    category = "AllMetrics"
    enabled  = local.keyvault_logging_enabled
    retention_policy {
      enabled = local.keyvault_logging_enabled
    }
  }
}
