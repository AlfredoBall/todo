terraform {
	required_version = ">= 1.14.3, < 2.0.0"

	required_providers {
		azurerm = {
			   source  = "hashicorp/azurerm"
			   version = "4.56.0"
		   }
		azuread = {
			source  = "hashicorp/azuread"
			version = "3.7.0"
		}
        tfe = {
            source = "hashicorp/tfe"
            version = "~> 0.72.0" # Constrain the version for production use
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

provider "tfe" {
  hostname = "app.terraform.io"
}