terraform {
	required_version = ">= 1.0.0"

	required_providers {
		azurerm = {
			source  = "hashicorp/azurerm"
			version = ">= 3.0.0"
		}
		azuread = {
			source  = "hashicorp/azuread"
			version = ">= 2.0.0"
		}
	}
}

provider "azurerm" {
	tenant_id       = var.tenant_id
	subscription_id = var.subscription_id
	features {}
}

provider "azuread" {
	tenant_id = var.tenant_id
}

/*
Notes:
- Install Terraform >= 1.14.2.
- Authenticate before running `terraform init`:
	- az login (for Azure CLI auth), or
	- set environment variables: ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
- For CI, keep backend credentials in pipeline secrets and consider using a dedicated service principal.
- Backend configuration has been moved to backend.tf (do not commit secrets there).
*/


  # Backend configuration is defined in backend.tf to avoid duplicate backends.
  # Keep provider and required_providers here; backend belongs in backend.tf.
