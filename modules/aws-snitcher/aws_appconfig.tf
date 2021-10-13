resource "aws_appconfig_application" "snitch" {
  name        = "aws-terraform-snitch"
  description = "AWS Terraform Snitch"

  tags = var.common_tags
}

resource "aws_appconfig_environment" "snitch" {
  name           = "aws-terraform-snitch-${var.config.stage}"
  description    = "AWS Terraform Snitch ${var.config.stage} Environment"
  application_id = aws_appconfig_application.snitch.id

# To roll back a configuration in response to a CloudWatch alarm
#   monitor {
#     alarm_arn      = aws_cloudwatch_metric_alarm.example.arn
#     alarm_role_arn = aws_iam_role.example.arn
#   }

  tags = var.common_tags
}

resource "aws_appconfig_configuration_profile" "snitch" {
  application_id = aws_appconfig_application.snitch.id
  name           = "aws-terraform-snitch-configuration-profile"
  description    = "AWS Terraform Snitch Configuration Profile"
  location_uri   = "hosted"

  validator {
    # https://extendsclass.com/json-schema-validator.html
    content = jsonencode({
        "definitions": {},
        "$schema": "http://json-schema.org/draft-07/schema#", 
        "$id": "https://example.com/object1630528135.json", 
        "title": "Root", 
        "type": "object",
        "required": [
          "notifications_on",
          "debug_log_messages"
        ],
        "properties": {
          "notify": {
            "$id": "#root/notifications_on", 
            "title": "Notification is enabled", 
            "type": "boolean",
            "examples": [
              true
            ],
            "default": true
          },
          "debug_log_messages": {
            "$id": "#root/debug_log_messages", 
            "title": "Debug_log_messages", 
            "type": "boolean",
            "examples": [
              false
            ],
            "default": true
          }
        }
    })
    type    = "JSON_SCHEMA"
  }

  tags = var.common_tags
}

resource "aws_appconfig_hosted_configuration_version" "snitch" {
  application_id           = aws_appconfig_application.snitch.id
  configuration_profile_id = aws_appconfig_configuration_profile.snitch.configuration_profile_id
  description              = "AWS Terraform Snitch Hosted Configuration Version"
  content_type             = "application/json"

  content = jsonencode({
    notifications_on = true,
    debug_log_messages = true
  })
}

resource "aws_appconfig_deployment_strategy" "snitch" {
  name                           = "aws-terraform-snitch-deployment-strategy"
  description                    = "AWS Terraform Snitch Deployment Strategy"
  deployment_duration_in_minutes = 2
#   final_bake_time_in_minutes     = 4
  growth_factor                  = 100.0
  growth_type                    = "LINEAR"
  replicate_to                   = "NONE"

  tags = var.common_tags
}


resource "aws_appconfig_deployment" "snitch_deployment" {
  application_id           = aws_appconfig_application.snitch.id
  configuration_profile_id = aws_appconfig_configuration_profile.snitch.configuration_profile_id
  configuration_version    = aws_appconfig_hosted_configuration_version.snitch.version_number
  deployment_strategy_id   = aws_appconfig_deployment_strategy.snitch.id
  description              = "Deploy AWS Terraform Snitch Application Configuration"
  environment_id           = aws_appconfig_environment.snitch.environment_id
  tags                     = var.common_tags
}