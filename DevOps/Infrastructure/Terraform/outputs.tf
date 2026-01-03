output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Name of the todo resource group"
}

output "resource_group_location" {
  value       = azurerm_resource_group.rg.location
  description = "Location of the todo resource group"
}

output "api_app_service_default_url" {
  description = "Default URL for the API App Service"
  value       = module.api.api_app_service_default_url
}

output "api_app_registration_client_id" {
  description = "The Application (client) ID for the API app registration"
  value       = module.api.api_app_registration_client_id
}

output "api_app_service_principal_id" {
  description = "Object ID of the service principal for the API app registration"
  value       = module.api.api_service_principal_id
}

output "api_scope_uri" {
  description = "API scope URI for authentication (format: api://client-id/scope)"
  value       = module.api.api_scope_uri
}

output "frontend_app_service_default_url" {
  description = "Default URL for the combined frontend App Service (Angular + React)"
  value       = module.frontend.frontend_app_service_default_url
}

output "frontend_app_registration_client_id" {
  description = "The Application (client) ID for the Frontend app registration"
  value       = module.frontend.frontend_app_registration_client_id
}