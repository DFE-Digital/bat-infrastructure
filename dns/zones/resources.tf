# Zone

resource "azurerm_dns_zone" "dns_zone" {
  for_each = var.hosted_zone

  name                = each.key
  resource_group_name = each.value.resource_group_name

  tags = {
    Environment = var.environment
    Portfolio   = var.portfolio
    Product     = var.product
    Service     = var.service
  }
}

# CAA record

locals {
  caa_records = flatten([
    for zone_name, zone_cfg in var.hosted_zone : [
      for record_name, record_cfg in zone_cfg["caa_records"] : {
        record_name         = record_name
        zone_name           = zone_name
        resource_group_name = zone_cfg["resource_group_name"]
        flags               = record_cfg["flags"]
        tag                 = record_cfg["tag"]
        value               = record_cfg["value"]
      }
    ]
  ])
}

resource "azurerm_dns_caa_record" "caa_records" {
  for_each            = {
    for zone in local.caa_records : "${zone.zone_name}.${zone.record_name}" => zone
  }

  name                = each.value.record_name
  zone_name           = each.value.zone_name
  resource_group_name = each.value.resource_group_name
  ttl                 = 300

  record {
    flags = each.value.flags
    tag   = each.value.tag
    value = each.value.value
  }

  depends_on = [
    azurerm_dns_zone.dns_zone
  ]

}

# TXT record

locals {
  txt_records = flatten([
    for zone_name, zone_cfg in var.hosted_zone : [
      for record_name, record_cfg in zone_cfg["txt_records"] : {
        record_name         = record_name
        zone_name           = zone_name
        resource_group_name = zone_cfg["resource_group_name"]
        value               = record_cfg["value"]
      }
    ]
  ])
}

resource "azurerm_dns_txt_record" "txt_records" {
  for_each            = {
    for zone in local.txt_records : "${zone.zone_name}.${zone.record_name}" => zone
  }

  name                = each.value.record_name
  zone_name           = each.value.zone_name
  resource_group_name = each.value.resource_group_name
  ttl                 = 300

  record {
    value = each.value.value
  }

  depends_on = [
    azurerm_dns_zone.dns_zone
  ]

}
