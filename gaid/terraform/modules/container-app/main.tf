locals {
  generated_yaml_path = abspath("${path.module}/.terraform/temp/container-app-${sha1(var.app_definition_yaml)}.yml")

  app_name = yamldecode(var.app_definition_yaml).name
  resource_group = yamldecode(var.app_definition_yaml).resourcegroup
}

resource "null_resource" "deploy_container_app_revision" {
  triggers = {
    definition = var.app_definition_yaml
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/scripts"
    command     = "&{echo $env:YAML | Out-File (New-Item -Path ${local.generated_yaml_path} -Force); ./Publish-ContainerAppRevision.ps1 -YamlFile ${local.generated_yaml_path} -TimeoutSeconds ${var.timeout}}"
    interpreter = ["pwsh", "-Command"]
    environment = {
      YAML = var.app_definition_yaml
    }
  }
}

data "external" "container_app" {
  program = ["pwsh", "-Command", "az", "containerapp", "show", "--name", local.app_name, "-g", local.resource_group, "--query", "'{fqdn: properties.configuration.ingress.fqdn}'"]

  depends_on = [
    null_resource.deploy_container_app_revision
  ]
}