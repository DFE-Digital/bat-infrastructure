locals {
  azure_credentials           = try(jsondecode(var.azure_credentials), null)
  backend_resource_group_name = var.resource_group_name

  aca_environment_name = (
    var.cip_tenant ?
    "${var.resource_prefix}-tsc-${var.environment}-cae" :
    "${var.resource_prefix}cae-tsc-${var.environment}"
  )

  aca_resource_group_name = (
    var.cip_tenant ?
    "${var.resource_prefix}-tsc-ca-${var.environment}-rg" :
    "${var.resource_prefix}rg-tsc-ca-${var.environment}"
  )

  aca_log_analytics_workspace_name = (
    var.cip_tenant ?
    "${var.resource_prefix}-tsc-${var.environment}-caelaw" :
    "${var.resource_prefix}caelaw-tsc-${var.environment}"
  )
}
