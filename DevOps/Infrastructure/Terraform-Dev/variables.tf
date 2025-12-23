variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
}

variable "api_redirect_uri" {
  description = "API redirect URI for local development"
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

# GitHub OIDC is NOT configured for local development
# GitHub Actions integration is only in the production Terraform directory
# Local development uses Aspire to manage app registrations dynamically
