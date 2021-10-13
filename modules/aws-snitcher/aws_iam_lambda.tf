locals {
  #role_name_enrichment     = "aws-config-${var.config.service_name}-role-${data.aws_region.current_region.name}-${random_string.role_suffix.result}"
  role_name_enrichment     = "aws-config-${var.config.service_name}-role-${data.aws_region.current_region.name}"
}

### Role For Enrichment Invoke Lambda
resource "aws_iam_role" "aws_config_snitch_role" {
  name  = local.role_name_enrichment

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

data "aws_iam_policy_document" "aws_config_notification_role_policy_doc" {
     statement  {
       actions = ["logs:CreateLogGroup"]
       resources = ["arn:aws:logs:${var.config.aws_region}:${var.config.account}:*"]
     }

     statement  {
       actions = ["logs:CreateLogStream","logs:PutLogEvents"]
       resources = ["arn:aws:logs:${var.config.aws_region}:${var.config.account}:log-group:/aws/lambda/aws-config-${var.config.service_name}-rules:*"]
     }

     statement {
       actions = ["cloudtrail:LookupEvents"]
       resources = ["*"]
     }

     statement {
       actions = ["appconfig:GetConfiguration"]
       resources = ["*"]
     }

     statement  {
       actions = ["sns:Publish"]
       resources = ["*"]
     }
}

resource "aws_iam_role_policy" "aws_config_notification_role_policy" {
  name   = "aws_config_notification_role_policy"
  role   = aws_iam_role.aws_config_snitch_role.id
  policy = data.aws_iam_policy_document.aws_config_notification_role_policy_doc.json
}