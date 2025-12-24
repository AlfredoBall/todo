output "api_app_service_default_url" {
  description = "Default URL for the API App Service"
  value       = "https://${azurerm_linux_web_app.api.name}.azurewebsites.net"
}


output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Name of the todo resource group"
}

output "resource_group_location" {
  value       = azurerm_resource_group.rg.location
  description = "Location of the todo resource group"
}

output "api_app_registration_app_id" {
  description = "The Application (client) ID for the API app registration"
  value       = azuread_application.api_app_registration.client_id
}

output "api_app_service_principal_id" {
  description = "Object ID of the service principal for the API app registration"
  value       = azuread_service_principal.api_sp.id
}

output "frontend_app_service_default_url" {
  description = "Default URL for the combined frontend App Service (Angular + React)"
  value       = "https://${azurerm_linux_web_app.frontend.name}.azurewebsites.net"
}

output "tenant_id" {
  description = "Azure AD Tenant ID"
  value       = var.tenant_id
}

output "api_scope" {
  description = "API scope for authentication (format: api://client-id/scope)"
  value       = "api://${azuread_application.api_app_registration.client_id}/access_as_user"
}

# Outputs for DNS TXT validation tokens for custom domains (for manual DNS setup)
