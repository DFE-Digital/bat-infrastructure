resource "cloudfoundry_app" "sqlpad" {
  name         = local.app_name
  docker_image = local.app_docker_image
  instances    = var.app_instances
  memory       = var.app_memory
  space        = data.cloudfoundry_space.space.id
  strategy     = "blue-green-v2"
  timeout      = 180
  environment  = local.app_env_variables
  routes {
    route = cloudfoundry_route.web_app_cloudapps_digital_route.id
  }
}

resource "cloudfoundry_route" "web_app_cloudapps_digital_route" {
  domain   = data.cloudfoundry_domain.london_cloudapps_digital.id
  space    = data.cloudfoundry_space.space.id
  hostname = local.app_name
}
