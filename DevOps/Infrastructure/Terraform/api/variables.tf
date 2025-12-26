variable "frontend_default_hostname" {
  type        = string
  description = "Default hostname of the frontend web app for CORS and URLs"
}
variable "api_app_service_name" {
  type        = string
  description = "Name of the Azure App Service for the Todo API"
}

variable "api_app_registration_name" {
  type        = string
  description = "Name of the Azure AD App Registration for the Todo API"
}

variable "sign_in_audience" {
  type        = string
  description = "Sign-in audience for Azure AD applications"
}

variable "location" {
  type        = string
  description = "Azure location for resources"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "service_plan_id" {
  type        = string
  description = "ID of the Azure App Service Plan"
}

variable "api_build_configuration" {
  description = "Build configuration for the API project"
  type        = string
}

variable "visual_studio_version" {
  description = "Version of Visual Studio to use for building the projects"
  type        = string
}

variable "target_env" {
  description = "ASP.NET Core environment (e.g., Development, Staging, Production)"
  type        = string
}