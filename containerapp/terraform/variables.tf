# Set in config mk file and passed by Makefile
variable "environment" {}
variable "resource_prefix" {}
variable "config_short" {}
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

variable "container_apps" {
  type = list(object({
    name            = string
    image           = string
    tag             = string
    containerPort   = number
    ingress_enabled = bool
    min_replicas    = number
    max_replicas    = number
    scale_rules     = any
    cpu_requests    = number
    mem_requests    = string
    secrets         = any
    env_vars        = any
    probes          = any
  }))
  default = []
}

variable "azure_credentials" { default = null }
