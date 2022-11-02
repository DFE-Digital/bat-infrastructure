
## Manually created VPC crun-vpc
data "google_compute_network" "crun-vpc" {
  name                    = "crun-vpc"
  project                 = local.infra_secrets["POC_GCP_PROJECT_ID"]
}

## Manually created Subnet crun-subnet
data "google_compute_subnetwork" "crun-subnet" {
  name          = "crun-subnet"
  project       = local.infra_secrets["POC_GCP_PROJECT_ID"]
  region        = "europe-west2"
#  network       = google_compute_network.crun-vpc.id
}

## manually created private ip address range
data "google_compute_global_address" "private_ip_sql" {
  name          = "crun-privateip"
  project       = local.infra_secrets["POC_GCP_PROJECT_ID"]
}

## manually created private ip address range
data "google_compute_global_address" "private_ip_redis" {
  name          = "crun-privateip-redis"
  project       = local.infra_secrets["POC_GCP_PROJECT_ID"]
}

#resource "google_service_networking_connection" "private_vpc_connection" {
#  network                 = google_compute_network.private_network.id
#  service                 = "servicenetworking.googleapis.com"
#  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
#}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.bat-hello.location
  project     = google_cloud_run_service.bat-hello.project
  service     = google_cloud_run_service.bat-hello.name

  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_cloud_run_service" "bat-hello" {
  name     = var.app_name
  location = "europe-west2"
  project  = local.infra_secrets["POC_GCP_PROJECT_ID"]

  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale"        = var.min_instances
        "autoscaling.knative.dev/maxScale"        = var.max_instances
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.name
        # all egress from the service should go through the VPC Connector
#        "run.googleapis.com/vpc-access-egress"    = "all-traffic"
        "run.googleapis.com/vpc-access-egress"    = "private-ranges-only"
        "run.googleapis.com/cloudsql-instances"   = google_sql_database_instance.default.connection_name
#        "run.googleapis.com/client-name"          = "postgres"
      }
    }
    spec {
      containers {
        image = local.infra_secrets["POC_GCP_IMAGE"]
#        image = "gcr.io/cloudrun/hello"
        ports {
          container_port = var.container_port
        }
        env {
          name = "RAILS_ENV"
          value = "review"
        }
        env {
          name = "RACK_ENV"
          value = "review"
        }
        env {
          name = "RAILS_MAX_THREADS"
          value = 50
        }
        env {
          name = "RAILS_SERVE_STATIC_FILES"
          value = "true"
        }
        env {
          name = "REDIS_CACHE_URL"
          value = "redis://192.168.3.11:6379/"
        }
        env {
#          name = "REDIS_WORKER_URL"
          name = "REDIS_URL"
          value = "redis://192.168.3.3:6379/"
        }
        env {
          name = "RAILS_HOST"
          value = "qa.find-postgraduate-teacher-training.service.gov.uk"
        }
        env {
          name = "WEBPACKER_DEV_SERVER_HOST"
          value = "webpacker"
        }
        env {
          name = "SECRET_KEY_BASE"
          value_from {
            secret_key_ref {
            key = "latest"
            name = "SECRET_KEY_BASE"
            }
          }
        }
        env {
          name = "SETTINGS__GOOGLE__MAPS_API_KEY"
          value_from {
            secret_key_ref {
            key = "latest"
            name = "SETTINGS__GOOGLE__MAPS_API_KEY"
            }
          }
        }
        resources {
          limits = {
            cpu = var.container_cpu
            memory = var.container_memory
          }
        }
      }
      service_account_name = local.infra_secrets["POC_GCP_SA_EMAIL"]
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
#  autogenerate_revision_name = true
  depends_on = [google_redis_instance.cache,google_redis_instance.worker]
}

## Manually enabled the VPCACCESS API
#resource "google_project_service" "vpcaccess_api" {
#  service                     = "vpcaccess.googleapis.com"
#  project                     = local.infra_secrets["POC_GCP_PROJECT_ID"]
#  disable_on_destroy          = false
#  disable_dependent_services  = false
#}

# Serverless VPC access connector
resource "google_vpc_access_connector" "connector" {
  name          = "vpcconn"
  project       = local.infra_secrets["POC_GCP_PROJECT_ID"]
  provider      = google-beta
  region        = "europe-west2"
  min_instances = 2
  max_instances = 3
  subnet {
    name = data.google_compute_subnetwork.crun-subnet.name
  }
  machine_type  = "e2-micro"
#  depends_on    = [google_project_service.vpcaccess_api]
}

resource "google_sql_database_instance" "default" {
  name             = "crun-sql-instance"
  region           = "europe-west2"
  database_version = "POSTGRES_14"
  project          = local.infra_secrets["POC_GCP_PROJECT_ID"]

#  depends_on = [google_service_networking_connection.default]
#  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
#    tier      = "db-f1-micro"
    tier      = "db-custom-1-4096"
    disk_size = 10
    disk_autoresize = "false"
    ip_configuration {
      ipv4_enabled       = "false"
      private_network    = data.google_compute_network.crun-vpc.id
      allocated_ip_range = data.google_compute_global_address.private_ip_sql.name
    }
  }
  deletion_protection = false # set to true to prevent destruction of the resource
}

resource "google_redis_instance" "cache" {
# maxmemory policy     : allkeys-lru
  name           = "crun-redis"
  tier           = "BASIC"
  memory_size_gb = 1
  project        = local.infra_secrets["POC_GCP_PROJECT_ID"]
  region         = "europe-west2"

  authorized_network = data.google_compute_network.crun-vpc.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  reserved_ip_range  = data.google_compute_global_address.private_ip_redis.name
  redis_version     = "REDIS_5_0"
  display_name      = "Terraform Test Instance"

  redis_configs = {
    maxmemory-policy = "allkeys-lru"
  }

#  depends_on = [google_service_networking_connection.private_service_connection]

}

resource "google_redis_instance" "worker" {
# maxmemory policy     : noeviction
  name           = "crun-redis-worker"
  tier           = "BASIC"
  memory_size_gb = 1
  project        = local.infra_secrets["POC_GCP_PROJECT_ID"]
  region         = "europe-west2"

  authorized_network = data.google_compute_network.crun-vpc.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  reserved_ip_range  = data.google_compute_global_address.private_ip_redis.name

  redis_version     = "REDIS_5_0"
  display_name      = "Terraform worker Instance"

  redis_configs = {
    maxmemory-policy = "noeviction"
  }

#  depends_on = [google_service_networking_connection.private_service_connection]

}
