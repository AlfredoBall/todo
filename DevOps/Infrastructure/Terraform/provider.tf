terraform {
	required_version = ">= 1.0.0"

	required_providers {
		   azurerm = {
			   source  = "hashicorp/azurerm"
			   version = "4.56.0"
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
Note: Backend configuration is defined in backend.tf
- Install Terraform >= 1.0.0
- Authenticate before running `terraform init`:
  - az login (for Azure CLI auth), or
  - set environment variables: ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
- For CI/CD, keep backend credentials in pipeline secrets and use a dedicated service principal
*/
