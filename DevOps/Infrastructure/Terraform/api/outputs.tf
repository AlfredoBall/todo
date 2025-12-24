output "api_app_service_default_url" {
  description = "Default URL for the API App Service"
  value       = "https://${azurerm_linux_web_app.api.name}.azurewebsites.net"
}

output "api_app_registration_client_id" {
  value = azuread_application.api_app_registration.client_id
}

output "api_scope" {
  description = "API scope for authentication (format: api://client-id/scope)"
  value       = "api://${azuread_application.api_app_registration.client_id}/access_as_user"
}

output "api_scope_id" {
  value = tolist(azuread_application.api_app_registration.api.oauth2_permission_scope)[0].id
  description = "The UUID of the API scope for delegated permission. Use this for advanced authentication scenarios."
}

output "api_service_principal_id" {
  value = azuread_service_principal.api_sp.object_id
}
