variable "api_app_registration_client_id" {
  description = "Client ID of the API app registration"
  type        = string
}

variable "api_app_registration_service_principal_id" {
  description = "Object ID of the API app registration service principal"
  type        = string
}

variable "react_redirect_uri" {
  description = "React app redirect URI for local development"
  type        = string
}

variable "angular_redirect_uri" {
  description = "Angular app redirect URI for local development"
  type        = string
}

variable "sign_in_audience" {
  description = "Sign-in audience for Azure AD applications"
  type        = string
}
