output "auth_server_fqdn" {
  value = var.domain
}

output "postgres_server_name" {
  value = azurerm_postgresql_flexible_server.postgres-server.name
}

output "blue_green" {
  value = var.enable_blue_green
}

output "web_app_slot_name" {
  value = local.web_app_slot_name
}
