terraform {
  backend "s3" {
    bucket               = "ujr-terraform-state"
    key                  = "tfstate"
    workspace_key_prefix = "terraform-aws-snitcher"
    region               = "eu-west-1"
    encrypt              = true
    dynamodb_table       = "terraform-state-lock"
  }
}