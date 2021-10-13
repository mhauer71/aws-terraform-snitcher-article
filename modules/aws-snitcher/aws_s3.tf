data "aws_region" "current_region" {}

locals {
  bucket_name = "aws-config-${var.config.service_name}-${var.config.stage}-${data.aws_region.current_region.name}-${random_string.bucket_suffix.result}"
}

resource "random_string" "bucket_suffix" {
  length  = 6
  special = false
  number  = false
  upper   = false
  lower   = true
 }

resource "aws_s3_bucket" "config" {
    bucket = local.bucket_name
    acl = "private"

    force_destroy = true

    versioning {
      enabled = true
    }

    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "aws:kms"
                kms_master_key_id = aws_kms_key.config.arn
            }
        }
    }

    lifecycle_rule {
        enabled = true
        prefix = var.key_prefix

        expiration {
          days = var.history_days
        }

        noncurrent_version_expiration {
          days = var.history_days
        }
    }

    tags = var.common_tags
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket = aws_s3_bucket.config.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [aws_s3_bucket_policy.config]
}

resource "aws_s3_bucket_policy" "config" {
  depends_on = [aws_s3_bucket.config]
  bucket = aws_s3_bucket.config.id
  policy = data.aws_iam_policy_document.config_bucket_policy.json
}

data "aws_iam_policy_document" "config_bucket_policy" {
  statement {
    sid = "AllowAWSConfig"
    effect = "Allow"
    actions = [
      "s3:GetBucketAcl",
      "s3:PutObject",
    ]
    principals {
      type = "Service"
      identifiers = [ "config.amazonaws.com" ]
    }
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.config.id}",
      "arn:aws:s3:::${aws_s3_bucket.config.id}/${var.key_prefix}*",
    ]
  }
}
