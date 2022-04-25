
variable "azure_credentials" { default = null }

variable "hosted_zone" {
  type    = map(any)
  default = {}
}

variable "environment" { default = "Prod" }
variable "portfolio" { default = "Early Years and Schools Group" }
variable "product" { default = "Find postgraduate teacher training" }
variable "service" { default = "Teacher services" }

locals {
  azure_credentials = try(jsondecode(var.azure_credentials), null)
}
