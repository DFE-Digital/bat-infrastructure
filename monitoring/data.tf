data "cloudfoundry_org" "dfe" {
  name = "dfe"
}

data "cloudfoundry_space" "monitoring" {
  name = var.monitoring_space_name
  org  = data.cloudfoundry_org.dfe.id
}

data "cloudfoundry_domain" "cloudapps" {
  name = "london.cloudapps.digital"
}

data "azurerm_key_vault" "key_vault" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group
}

data "azurerm_key_vault_secret" "infra_secrets" {
  key_vault_id = data.azurerm_key_vault.key_vault.id
  name         = var.key_vault_infra_secret_name
}
