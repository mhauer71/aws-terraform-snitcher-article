.DEFAULT_GOAL:=help
SHELL:=/bin/bash
.PHONY: help build test upgrade run

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[33m\n\nTargets:\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-25s\033[33m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

create: check-tools ## Create backend environment (S3 Bucket, DynamoDB Table) to save Terraform's Project States (terraform init, plan and apply)
	terraform init -backend=false; \
	terraform plan -out tfplan; \
	terraform apply "tfplan"

init: check-tools ## Init terraform plan, firing: "terraform init"
	terraform init 

plan: check-tools ## terraform plan
	terraform plan -out tfplan

apply: check-tools plan ## Create or update infrastructure "terraform apply"
	 terraform apply "tfplan"

show: ## Show the current state or a saved plan "terraform show"
	terraform show

validate: ## Check whether the configuration is valid
	terraform validate

destroy: ## Destroy previously-created infrastructure "terraform destroy"
	terraform destroy

chk_bucket: ## Use "terraform console" to show some values of the state of our infrastructure
	echo "aws_s3_bucket.terraform_state.bucket_domain_name" | terraform console

chk_dynamodb: ## Use "terraform console" to check the state of the DynamoDB created with this terraform infrastructure state
	echo "aws_dynamodb_table.terraform_state_lock" | terraform console	

check-tools: # Check if the necessary tools are installed
ifneq (,$(which terraform))
	$(error "Terraform not installed!")
endif
ifneq (,$(which aws))
	$(error "AWSCLI not installed!")
endif