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