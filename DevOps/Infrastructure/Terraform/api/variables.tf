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

variable "dockerhub_username" {
  type       = string
  description = "Docker Hub username for pulling the API image"
}

variable "dockerhub_password" {
  type        = string
  description = "Docker Hub password for pulling the API image"
  sensitive   = true
}

variable "todo_environment_id" {
  type        = string
  description = "ID of the Azure Container App Environment"
}