# Local Development App Registrations
# This creates Azure AD app registrations for local development only
# State is stored locally - do not commit terraform.tfstate

terraform {
  required_version = "1.14.2"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.7.0"
    }
  }
}

provider "azuread" {
  tenant_id = var.tenant_id
}

# GitHub provider is NOT used for local development
# GitHub Actions integration is configured in the production Terraform directory

data "azuread_client_config" "current" {}

