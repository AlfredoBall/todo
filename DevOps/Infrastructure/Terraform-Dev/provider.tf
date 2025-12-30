terraform {
	required_version = "1.14.3"

	required_providers {
		azurerm = {
			   source  = "hashicorp/azurerm"
			   version = "4.56.0"
		   }
		azuread = {
			source  = "hashicorp/azuread"
			version = "3.7.0"
		}
		time = {
			source  = "hashicorp/time"
			version = "~> 0.13"
		}
	}
}

provider "azuread" {}

/*
Note: Backend configuration is defined in backend.tf
- Install Terraform >= 1.0.0
- Authenticate before running `terraform init`:
  - az login (for Azure CLI auth), or
  - set environment variables: ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
- For CI/CD, keep backend credentials in pipeline secrets and use a dedicated service principal
*/
