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

output "tenant_id" {
  description = "Azure AD Tenant ID"
  value       = var.tenant_id
}

output "api_scope" {
  description = "API scope for authentication (format: api://client-id/scope)"
  value       = "api://${azuread_application.api_app_registration.client_id}/access_as_user"
}

// GitHub OIDC outputs
output "github_oidc_client_id" {
  description = "Client ID for GitHub OIDC app registration (used in workflows)"
  value       = azuread_application.github_oidc.client_id
}

output "github_oidc_app_id" {
  description = "Object ID of the GitHub OIDC app registration"
  value       = azuread_application.github_oidc.id
}

output "github_environment_name" {
  description = "Name of the created GitHub environment"
  value       = github_repository_environment.production.environment
}

output "github_oidc_subject" {
  description = "Subject claim used in the federated credential"
  value       = "repo:${var.github_repo_owner}/${var.github_repo_name}:ref:refs/heads/${var.github_branch}"
}

# Outputs for DNS TXT validation tokens for custom domains (for manual DNS setup)
