resource "aws_lambda_alias" "aws_snitch_rule_alias" {
  name             = "aws-config-${var.config.service_name}-rules-alias-${data.aws_region.current_region.name}"
  description      = "AWS Config Terraform Snitch Rule"
  function_name    = aws_lambda_function.lambda_snitch_rules.function_name
  function_version = "$LATEST"
}

resource "aws_lambda_permission" "allow_event_bridge_invoke_permission_lambda_function" {
  statement_id  = "AllowExecutionEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_snitch_rules.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.aws_config_notification_rule.arn
}

data "archive_file" "lambda_snitch_rule_dist" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_snitch_rule/src/"
  output_path = "${path.module}/lambda_snitch_rule/dist/lambda_eventbridge_rule.zip"
}

resource "aws_lambda_function" "lambda_snitch_rules" {
    filename         = "${path.module}/lambda_snitch_rule/dist/lambda_eventbridge_rule.zip"
    function_name    = "aws-config-${var.config.service_name}-rules"
    role             = aws_iam_role.aws_config_snitch_role.arn
    handler          = "index.handler"
    timeout          = "30"
    runtime          = "nodejs14.x"
    source_code_hash = filebase64sha256("${path.module}/lambda_snitch_rule/dist/lambda_eventbridge_rule.zip")
    tags             = var.common_tags

    # Lambda Layer Extension to access AWS AppConfig
    #   | In essence, a Lambda extension is like a client that runs in parallel to a Lambda invocation
    #   | This extension includes best practices that simplify using AWS AppConfig while reducing costs. Reduced costs result from fewer API calls to the AWS AppConfig service and, 
    #   | separately, reduced costs from shorter Lambda function processing times.
    # See: https://docs.aws.amazon.com/appconfig/latest/userguide/appconfig-integration-lambda-extensions.html
    # Extension Configuration: https://docs.aws.amazon.com/appconfig/latest/userguide/appconfig-integration-lambda-extensions.html#appconfig-integration-lambda-extensions-config
    layers           = ["arn:aws:lambda:${var.config.aws_region}:434848589818:layer:AWS-AppConfig-Extension:41"]
    
    environment {
      variables = {
        AWS_APPCONFIG_APPLICATION_NAME                = aws_appconfig_application.snitch.name
        AWS_APPCONFIG_ENVIRONMENT                     = aws_appconfig_environment.snitch.name
        AWS_APPCONFIG_CONFIGURATION_PROFILE           = aws_appconfig_configuration_profile.snitch.name
        AWS_APPCONFIG_EXTENSION_POLL_INTERVAL_SECONDS = 10
        AWS_APPCONFIG_EXTENSION_POLL_TIMEOUT_MILLIS   = 3000
        AWS_APPCONFIG_EXTENSION_HTTP_PORT             = 2772
        AWS_APPCONFIG_EXTENSION_LOG_LEVEL             = "info" #debug, info, warn, error, none
        SNS_TOPIC                                     = aws_sns_topic.aws_config_notifications.arn
      }
    }
}
