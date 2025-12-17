
/*
backend configuration and usage
-------------------------------

This file intentionally does not contain variable interpolation. Use one
of the provided options below to initialize the backend so Terraform can
read/write remote state.

Recommended (secure, CI-friendly):
- Use the helper scripts which read environment variables and pass
	`-backend-config` values to `terraform init`:
	- PowerShell:  `DevOps/Scripts/terraform-init.ps1`
	- Bash:        `DevOps/Scripts/terraform-init.sh`
	- Example env file: `DevOps/Infrastructure/Terraform/backend.env.example`

Local one-shot (explicit literals):
- You can also hard-code literal values here, but avoid committing secrets.

Why this approach: Terraform evaluates the backend during `terraform
init` before module variables (TF_VAR_*) are available, so variables
cannot be used directly inside the backend block.

Example (PowerShell):
	$env:TF_RESOURCE_GROUP = 'todo-rg'
	$env:TF_STORAGE_ACCOUNT = 'todo-tfstatestorage-15243'
	$env:TF_CONTAINER = 'tfstate'
	$env:TF_KEY = 'todo.terraform.tfstate'
	$env:TF_SUBSCRIPTION_ID = 'da348b35-29b6-4906-85ec-4a097aa5fe04'
	$env:TF_TENANT_ID = 'bf451fd9-d382-4da8-9c1a-179a96a4d2f3'
	.\DevOps\Scripts\terraform-init.ps1

Example (bash):
	source DevOps/Infrastructure/Terraform/backend.env.example
	DevOps/Scripts/terraform-init.sh

*/


