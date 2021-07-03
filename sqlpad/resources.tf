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
  service_binding {
    service_instance = cloudfoundry_service_instance.postgres.id
  }
}

resource "cloudfoundry_route" "web_app_cloudapps_digital_route" {
  domain   = data.cloudfoundry_domain.london_cloudapps_digital.id
  space    = data.cloudfoundry_space.space.id
  hostname = local.app_name
}

resource "cloudfoundry_service_instance" "postgres" {
  name         = local.postgres_name
  space        = data.cloudfoundry_space.space.id
  service_plan = data.cloudfoundry_service.postgres.service_plans["tiny-unencrypted-12"]
}

resource "cloudfoundry_service_key" "postgres_service_key" {
  name             = "${local.postgres_name}-key"
  service_instance = cloudfoundry_service_instance.postgres.id
}
