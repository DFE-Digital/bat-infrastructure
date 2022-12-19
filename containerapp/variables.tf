variable "location" {
  type        = string
  default     = "westeurope"
  description = "Desired Azure Region"
}

variable "resource_group_name" {
  type = string
}

variable "aca_resource_group_name" {
  type = string
}

variable "aca_log_analytics_workspace_name" {
  type = string
}

variable "aca_environment_name" {
  type = string
}

variable "container_apps" {
  type = list(object({
    name            = string
    image           = string
    tag             = string
    containerPort   = number
    ingress_enabled = bool
    min_replicas    = number
    max_replicas    = number
    cpu_requests    = number
    mem_requests    = string
  }))

  default = [{
    image           = "thorstenhans/gopher"
    name            = "herogopher"
    tag             = "hero"
    containerPort   = 80
    ingress_enabled = true
    min_replicas    = 1
    max_replicas    = 2
    cpu_requests    = 0.5
    mem_requests    = "1.0Gi"
    },
    {
      image           = "thorstenhans/gopher"
      name            = "devilgopher"
      tag             = "devil"
      containerPort   = 80
      ingress_enabled = true
      min_replicas    = 1
      max_replicas    = 2
      cpu_requests    = 0.5
      mem_requests    = "1.0Gi"
  }]
}

variable azure_credentials { default = null }
