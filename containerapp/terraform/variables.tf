# Set in config mk file and passed by Makefile
variable "environment" {}
variable "resource_prefix" {}
variable "resource_group_name" {
  type = string
}

# Set in config json file
variable "cip_tenant" { type = bool }

variable "location" {
  type        = string
  default     = "westeurope"
  description = "Desired Azure Region"
}

# variable "aca_resource_group_name" {
#   type = string
# }

# variable "aca_log_analytics_workspace_name" {
#   type = string
# }

# variable "aca_environment_name" {
#   type = string
# }

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
    secrets         = any
    env_vars        = any
  }))
  default = []
}

variable "azure_credentials" { default = null }
