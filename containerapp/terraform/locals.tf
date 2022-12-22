locals {
  azure_credentials           = try(jsondecode(var.azure_credentials), null)
  backend_resource_group_name = var.resource_group_name

  aca_environment_name = (
    var.cip_tenant ?
    "${var.resource_prefix}-tsc-${var.config_short}-cae" :
    "${var.resource_prefix}cae-tsc-${var.config_short}"
  )

  aca_resource_group_name = (
    var.cip_tenant ?
    "${var.resource_prefix}-tsc-ca-${var.config_short}-rg" :
    "${var.resource_prefix}rg-tsc-ca-${var.config_short}"
  )

  aca_log_analytics_workspace_name = (
    var.cip_tenant ?
    "${var.resource_prefix}-tsc-${var.config_short}-caelaw" :
    "${var.resource_prefix}caelaw-tsc-${var.config_short}"
  )
}
