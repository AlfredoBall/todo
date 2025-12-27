output "api_app_service_default_url" {
  description = "Default URL for the API App Service"
  value       = "https://${azurerm_windows_web_app.api.name}.azurewebsites.net"
}

output "api_app_registration_client_id" {
  value = azuread_application.api_app_registration.client_id
}

output "api_scope_uri" {
  description = "API scope URI for authentication (format: api://client-id/scope), used by client apps."
  value       = "api://${azuread_application.api_app_registration.client_id}/access_as_user"
}

output "api_scope_uuid" {
  value = azuread_application.api_app_registration.api[0].oauth2_permission_scope[0].id
  description = "The UUID (GUID) of the API scope for delegated permission. Used for Azure AD wiring and automation."
}

output "api_service_principal_id" {
  value = azuread_service_principal.api_sp.object_id
}