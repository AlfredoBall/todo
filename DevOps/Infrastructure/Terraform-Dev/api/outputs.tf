output "app_registration_client_id" {
  description = "API app registration client ID"
  value       = azuread_application.api_app_registration.client_id
}

output "app_registration_service_principal_id" {
  description = "API app registration service principal ID"
  value       = azuread_service_principal.app_registration_sp.id
}

output "app_registration_scope_uri" {
  description = "API scope for authentication"
  value       = "api://${azuread_application.api_app_registration.client_id}/access_as_user"
}

output "app_registration_audience" {
  description = "API audience URI"
  value       = "api://${azuread_application.api_app_registration.client_id}"
}