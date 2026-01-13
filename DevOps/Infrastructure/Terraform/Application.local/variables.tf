variable "tenant_id" {
  description = "Azure AD Tenant ID for local development"
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