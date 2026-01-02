variable "api_app_registration_client_id" {
  description = "Client ID of the API app registration"
  type        = string
}

variable "api_app_registration_service_principal_id" {
  description = "Object ID of the API app registration service principal"
  type        = string
}

variable "redirect_uri" {
  description = "Frontend app redirect URI for local development"
  type        = string
}

variable "sign_in_audience" {
  description = "Sign-in audience for Azure AD applications"
  type        = string
}

variable "azuread_client_config_id" {
  description = "The object ID of the Azure AD client configuration"
  type        = string
}