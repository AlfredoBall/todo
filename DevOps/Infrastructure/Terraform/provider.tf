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
		github = {
			source  = "integrations/github"
			version = "~> 6.0"
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

// GitHub provider for managing environments, secrets, and variables
// Authentication options (in order of precedence):
//   1. GitHub CLI: gh auth login (recommended for local development)
//   2. Personal Access Token: Set GITHUB_TOKEN environment variable
//   3. GitHub App: Configure app_auth block with GITHUB_APP_ID, GITHUB_APP_INSTALLATION_ID, GITHUB_APP_PEM_FILE
// See: https://registry.terraform.io/providers/integrations/github/latest/docs#authentication
provider "github" {
  owner = var.github_repo_owner
}

/*
Note: Backend configuration is defined in backend.tf
- Install Terraform >= 1.0.0
- Authenticate before running `terraform init`:
  - az login (for Azure CLI auth), or
  - set environment variables: ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
- For CI/CD, keep backend credentials in pipeline secrets and use a dedicated service principal
- GitHub provider authentication: gh auth login or set GITHUB_TOKEN environment variable
*/
