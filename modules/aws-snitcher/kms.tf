resource "aws_kms_key" "config" {
  description = "KMS key for encryption of the AWS Config bucket"
  enable_key_rotation = true
  policy = data.aws_iam_policy_document.kms_key_policy.json

  tags = var.common_tags
}

locals {
  alias_cmk = "alias/cmk-${local.bucket_name}"
}

resource "aws_kms_alias" "config" {
  name = local.alias_cmk
  target_key_id = aws_kms_key.config.key_id
}

data "aws_iam_policy_document" "kms_key_policy" {
    
  statement {
    sid = "AllowAWSConfig"
    effect = "Allow"
    actions = [ "kms:*" ]  # TODO make more restrict this later
    resources = [ "*" ]
    principals {
      type = "Service"
      identifiers = [ "config.amazonaws.com" ]
    }
  }

  statement {
    sid = "AllowTrustedRoles"
    effect = "Allow"
    actions = [ "kms:*" ]
    resources = [ "*" ]
    principals { 
      type = "AWS"
      identifiers = var.config.whitelisted_principals
    }
  }

}
