
# Rule to catch AWS.Config Events
resource "aws_cloudwatch_event_rule" "aws_config_notification_rule" {
  name        = "aws_config_${var.config.service_name}_notification_rule"
  description = "Catch AWS Config Events"
  tags        = var.common_tags

  event_pattern = <<EOF
{
  "source": ["aws.config"],
  "detail-type": ["Config Configuration Item Change"],
  "detail": {
    "messageType": ["ConfigurationItemChangeNotification"]
  }
}
EOF
}

# For debug/tests purposes
# resource "aws_cloudwatch_event_target" "sns" {
#   depends_on = [aws_cloudwatch_event_rule.aws_config_notification_rule]
#   rule       = aws_cloudwatch_event_rule.aws_config_notification_rule.name
#   target_id  = "SendToSNS"
#   arn        = aws_sns_topic.aws_config_notifications.arn
# }

resource "aws_cloudwatch_event_target" "lambda" {
  depends_on = [aws_cloudwatch_event_rule.aws_config_notification_rule]
  rule       = aws_cloudwatch_event_rule.aws_config_notification_rule.name
  target_id  = "SendToLambda"
  arn        = aws_lambda_function.lambda_snitch_rules.arn
}