resource "aws_config_configuration_recorder" "recorder" {
  name = "snitch"
  role_arn = aws_iam_role.recorder.arn

  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "channel" {
  name = "config-s3-sns-delivery"

  s3_bucket_name = aws_s3_bucket.config.id
  s3_key_prefix = var.key_prefix

  snapshot_delivery_properties {
    delivery_frequency = var.snapshot_frequency
  }
}

resource "aws_config_configuration_recorder_status" "recorder" {
  name = aws_config_configuration_recorder.recorder.name
  is_enabled = true

  # cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder_status
  depends_on = [aws_config_delivery_channel.channel]
}