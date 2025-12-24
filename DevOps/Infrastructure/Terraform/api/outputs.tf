output "api_app_service_default_url" {
  description = "Default URL for the API App Service"
  value       = "https://${azurerm_linux_web_app.api.name}.azurewebsites.net"
}

output "api_app_registration_client_id" {
  value = azuread_application.api_app_registration.client_id
}

output "api_scope_string" {
  description = "API scope string for authentication (format: api://client-id/scope), used by client apps."
  value       = "api://${azuread_application.api_app_registration.client_id}/access_as_user"
}

output "api_scope_uuid" {
  value = "b7e7e8e2-8c2a-4e2a-9e2a-123456789abc"
  description = "The UUID (GUID) of the API scope for delegated permission. Used for Azure AD wiring and automation."
}

output "api_service_principal_id" {
  value = azuread_service_principal.api_sp.object_id
}
