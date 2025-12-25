output "frontend_app_registration_client_id" {
  description = "Frontend app registration client ID"
  value       = azuread_application.react_dev.client_id
}

output "api_scope_uri" {
  description = "API scope for authentication"
  value       = "api://${azuread_application.api_dev.client_id}/access_as_user"
}

output "api_audience" {
  description = "API audience URI"
  value       = "api://${azuread_application.api_dev.client_id}"
}

# GitHub OIDC outputs are not applicable for local development
# GitHub Actions integration is configured in the production Terraform directory only
