variable "service_plan_linux_name" {
  description = "Name of the Linux Azure App Service Plan for the Todo Web App Services"
  type        = string
}

variable "service_plan_windows_name" {
  description = "Name of the Windows Azure App Service Plan for the Todo Web App Services"
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
  sensitive   = true
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "resource_tags" {
  description = "Common tags applied to resources"
  type        = map(string)
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

variable "frontend_app_service_name" {
  description = "Name of the Azure App Service for the combined frontend (Angular + React)"
  type        = string
}

variable "sign_in_audience" {
  description = "Sign-in audience for Azure AD applications"
  type        = string
}

variable "api_build_configuration" {
  description = "Build configuration for the API project"
  type        = string
  default     = "Release"
}

variable "visual_studio_version" {
  description = "Version of Visual Studio to use for building the projects"
  type        = string
  default     = "VS2022"
}

variable "target_env" {
  description = "ASP.NET Core environment (e.g., Development, Staging, Production)"
  type        = string
}