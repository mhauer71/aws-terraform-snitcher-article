resource "random_string" "role_suffix" {
  length  = 6
  special = false
  number  = false
  upper   = false
  lower   = true
}

locals {
  #role_name = "aws-terraform-snitch-config-recorder-${var.stage}-${random_string.role_suffix.result}"
  role_name = "aws-config-${var.config.service_name}-recorder"
}

resource "aws_iam_role" "recorder" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.recorder_trust_policy.json
  tags               = var.common_tags
}

data "aws_iam_policy_document" "recorder_trust_policy" {
  statement {
    sid = "AllowConfigService"
    effect = "Allow"
    actions = [ "sts:AssumeRole" ]
    principals {
      type = "Service"
      identifiers = [ "config.amazonaws.com" ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "recorder" {
  role       = aws_iam_role.recorder.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}


