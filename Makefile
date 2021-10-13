.DEFAULT_GOAL:=help
SHELL:=/bin/bash
ANSIBLEDIR:=./ansible
.PHONY: help build test upgrade run

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[33m\n\nTargets:\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-30s\033[33m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

init: check-tools workspace_current ## Init terraform plan, firing: "terraform init"
	terraform init 

plan: check-tools workspace_current ## terraform plan
	terraform plan -out tfplan

apply: check-tools workspace_current plan ## Create or update infrastructure "terraform apply"
	 terraform apply "tfplan"

show: workspace_current ## Show the current state or a saved plan "terraform show"
	terraform show

output: workspace_current ## Show all the outputs of this Terraform script (main structure)
	terraform output

refresh: workspace_current ## Refresh the values of output with the AWS state
	terraform refresh

validate: workspace_current ## Check whether the configuration is valid
	terraform validate

destroy: workspace_current ## Destroy previously-created infrastructure "terraform destroy"
	terraform destroy

workspace_ls: ## List Terraform workspaces
	terraform workspace list

workspace_dev: ## Select Terraform Workspace Dev
	terraform workspace select dev

workspace_new_dev: ## Create Terraform Workspace Dev
	terraform workspace new dev

check-env: check-tools ## Check environment tooling
	@echo ""; \
	printf "\033[33m OK!\033[0m\n"; \
	echo ""

workspace_current: ## Show current Terraform Workspace
	@echo ""; \
	echo "*********************************************************"; \
	printf "* \033[36mTERRAFORM\033[0m workspace selected --> \033[33m$$(terraform workspace show)\033[0m\n"; \
	echo "*********************************************************"; \
	echo ""
	
check-tools: # Check if the necessary tools are installed
ifneq (,$(which terraform))
	$(error "Terraform not installed!")
endif
ifneq (,$(which aws))
	$(error "AWSCLI not installed!")
endif