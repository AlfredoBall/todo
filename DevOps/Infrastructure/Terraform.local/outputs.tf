output "tenant_id" {
  description = "Azure AD Tenant ID"
  value       = data.azuread_client_config.current.tenant_id
}

output "frontend_app_registration_client_id" {
  description = "Frontend app registration client ID"
  value       = module.frontend.frontend_client_id
}

output "api_app_registration_client_id" {
  description = "API app registration client ID"
  value       = module.api.app_registration_client_id
}

output "api_scope_uri" {
  description = "API scope for authentication"
  value       = module.api.app_registration_scope_uri
}

output "api_audience" {
  description = "API audience URI"
  value       = module.api.app_registration_audience
}

# GitHub OIDC outputs are not applicable for local development
# GitHub Actions integration is configured in the production Terraform directory only
