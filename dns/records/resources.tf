# CNAME records

locals {
  cname_records = flatten([
    for zone_name, zone_cfg in var.hosted_zone : [
      for record_name, record_cfg in zone_cfg["cnames"] : {
        record_name         = record_name
        zone_name           = zone_name
        resource_group_name = zone_cfg["resource_group_name"]
        target              = record_cfg["target"]
        ttl                 = try(record_cfg["ttl"], 300)
      }
    ]
  ])
}

resource "azurerm_dns_cname_record" "cname_records" {
  for_each            = {
    for zone in local.cname_records : "${zone.zone_name}.${zone.record_name}" => zone
  }

  name                = each.value.record_name
  zone_name           = each.value.zone_name
  resource_group_name = each.value.resource_group_name
  ttl                 = each.value.ttl
  record              = each.value.target

}
