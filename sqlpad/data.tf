data "cloudfoundry_org" "org" {
  name = "dfe"
}

data "cloudfoundry_space" "space" {
  name = var.paas_space_name
  org  = data.cloudfoundry_org.org.id
}

data "cloudfoundry_domain" "london_cloudapps_digital" {
  name = "london.cloudapps.digital"
}

data "cloudfoundry_service" "postgres" {
  name = "postgres"
}

data "azurerm_key_vault" "key_vault" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group
}

data "azurerm_key_vault_secret" "infra_secrets" {
  key_vault_id = data.azurerm_key_vault.key_vault.id
  name         = var.key_vault_infra_secret_name
}
