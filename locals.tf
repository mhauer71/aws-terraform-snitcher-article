locals {

  environment = terraform.workspace

  defaults   = try(yamldecode(file("workspace-config/default.yml")), {})
  env_config = try(yamldecode(file("workspace-config/${local.environment}.yml")), {})

  config = merge(
    local.defaults,
    local.env_config,
  )

  common_tags = {
    Service     = local.config.service_name
    Owner       = local.config.owner
    Environment = terraform.workspace
  }
}