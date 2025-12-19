
variable "react_static_web_app_name" {
  description = "Name of the Azure Static Web App for the React app"
  type        = string
}

variable "angular_static_web_app_name" {
  description = "Name of the Azure Static Web App for the Angular app"
  type        = string
}

variable "api_service_plan_name" {
  description = "Name of the Azure App Service Plan for the Todo API"
  type        = string
}

variable "api_app_service_name" {
  description = "Name of the Azure App Service for the Todo API"
  type        = string
}
// Centralized Terraform variables for the Todo infrastructure

variable "location" {
  description = "Azure location for resources"
  type        = string
  default     = "centralus"
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-todo"
}

variable "resource_tags" {
  description = "Common tags applied to resources"
  type = map(string)
  default = {
    project = "todo"
  }
}

variable "tf_storage_account_name" {
  description = "Name of the Azure Storage Account for Terraform state"
  type        = string
}

variable "tf_container_name" {
  description = "Name of the Azure Storage Container for Terraform state"
  type        = string
}

variable "tf_state_key" {
  description = "Key (filename) for the Terraform state file"
  type        = string
}

variable "api_app_registration_name" {
  description = "Name of the Azure AD App Registration for the Todo API"
  type        = string
  default     = "To Do API"
}

variable "angular_app_registration_name" {
  description = "Name of the Azure AD App Registration for the Angular Todo app"
  type        = string
  default     = "To Do Angular"
}

variable "react_app_registration_name" {
  description = "Name of the Azure AD App Registration for the React Todo app"
  type        = string
  default     = "To Do React"
}

/*
Backend values (resource_group_name, storage_account_name, container_name, key)
should be supplied at `terraform init` with `-backend-config` or managed outside
of committed files. Do NOT store secrets or access keys in the repo.
Example:
  terraform init -backend-config="resource_group_name=rg-terraform-state" \
    -backend-config="storage_account_name=mystorageacct" \
    -backend-config="container_name=tfstate" \
    -backend-config="key=todo.terraform.tfstate"
*/
