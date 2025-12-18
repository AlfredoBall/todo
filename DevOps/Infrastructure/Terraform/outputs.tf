output "api_app_service_default_url" {
  description = "Default URL for the API App Service"
  value       = "https://${azurerm_linux_web_app.api.name}.azurewebsites.net"
}

output "react_static_web_app_default_url" {
  description = "Default URL for the React Static Web App"
  value       = "https://${azurerm_static_web_app.react.name}.azurestaticapps.net"
}

output "angular_static_web_app_default_url" {
  description = "Default URL for the Angular Static Web App"
  value       = "https://${azurerm_static_web_app.angular.name}.azurestaticapps.net"
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

output "angular_app_id" {
  description = "Application (client) ID for the Angular app registration"
  value       = azuread_application.angular_app.client_id
}

output "angular_sp_id" {
  description = "Object ID of the service principal for the Angular app"
  value       = azuread_service_principal.angular_sp.id
}

output "react_app_id" {
  description = "Application (client) ID for the React app registration"
  value       = azuread_application.react_app.client_id
}

output "react_sp_id" {
  description = "Object ID of the service principal for the React app"
  value       = azuread_service_principal.react_sp.id
}


# Outputs for DNS TXT validation tokens for custom domains (for manual DNS setup)
