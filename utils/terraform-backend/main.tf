# terraform state file setup
# create an S3 bucket to store the state file in
resource "aws_s3_bucket" "terraform_state" {
    bucket = "ujr-terraform-state"

    versioning {
        enabled = true
    }

    lifecycle {
        prevent_destroy = false
    }

    tags = {Name = "Remote Terraform State Store"}
          
}


resource "aws_dynamodb_table" "terraform_state_lock" {
    name = "terraform-state-lock"
    hash_key = "LockID"
    read_capacity = 20
    write_capacity = 20

    attribute {
        name = "LockID"
        type = "S"
    }

    tags = {Name = "Remote Terraform State Store Lock"}
}