variable "app_definition_yaml" {
  type = string
}

variable "timeout" {
  description = "The timeout in seconds for provisioning the container app revision"
  default     = 120
  type        = string
}