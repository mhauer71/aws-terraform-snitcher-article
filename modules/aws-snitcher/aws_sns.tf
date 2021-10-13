
resource "aws_sns_topic" "aws_config_notifications" {
  name = "aws_config_${var.config.service_name}_notifications"
  tags = var.common_tags
}

# My Subscription for tests
resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.aws_config_notifications.arn
  protocol  = "email"
  endpoint = var.config.sns_notification_email
}