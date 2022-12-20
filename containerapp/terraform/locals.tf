locals {
  azure_credentials = try(jsondecode(var.azure_credentials), null)
  backend_resource_group_name = var.resource_group_name
}
