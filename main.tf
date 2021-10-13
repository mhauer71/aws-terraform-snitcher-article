module "aws_snitcher" {
  source      = "./modules/aws-snitcher"
  config      = local.config
  common_tags = local.common_tags
}
