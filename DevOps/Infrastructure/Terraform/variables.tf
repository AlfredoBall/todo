variable "api_container_app_name" {
  type        = string
  description = "Name of the Azure Container App for the Todo API"
}

variable "api_container_name" {
  description = "Name of the Azure Container for the Todo API"
  type        = string
}

variable "api_image" {
  type        = string
  description = "Docker image name for the Todo API"
}

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

variable "api_app_registration_name" {
  description = "Name of the Azure AD App Registration for the Todo API"
  type        = string
  default     = "To Do API"
}

variable "frontend_container_app_name" {
  description = "Name of the Azure Container App for the combined frontend (Angular + React)"
  type        = string
}

variable "frontend_container_name" {
  description = "Name of the Azure Container for the combined frontend (Angular + React)"
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

variable "dockerhub_username" {
  type        = string
  description = "Docker Hub username for pulling the frontend image"
}

variable "dockerhub_password" {
  type        = string
  description = "Docker Hub password for pulling the frontend image"
  sensitive   = true
}

variable "frontend_image" {
  type        = string
  description = "Docker image name for the Todo frontend"
}