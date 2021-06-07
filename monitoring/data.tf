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
