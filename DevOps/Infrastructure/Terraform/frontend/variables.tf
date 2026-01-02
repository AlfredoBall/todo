variable "frontend_app_service_name" {
  type        = string
  description = "Name of the Azure App Service for the combined frontend (Angular + React)"
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

variable "api_app_registration_client_id" {
  type        = string
  description = "Client ID of the API app registration"
}

variable "api_scope_uri" {
  type        = string
  description = "API scope URI for authentication (format: api://client-id/scope), used by client apps."
}

variable "api_scope_uuid" {
  type        = string
  description = "UUID (GUID) of the API scope for delegated permission. Used for Azure AD wiring and automation."
}

variable "api_service_principal_id" {
  type        = string
  description = "Object ID of the API service principal"
}

variable "target_env" {
  type        = string
  description = "Environment (e.g., Development, Staging, Production)"
}

variable "dockerhub_username" {
  type       = string
  description = "Docker Hub username for pulling the frontend image"
}

variable "frontend_image" {
  type        = string
  description = "Docker image name for the Todo frontend"
}