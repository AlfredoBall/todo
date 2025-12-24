output "frontend_app_service_default_url" {
  description = "Default URL for the combined frontend App Service (Angular + React)"
  value       = "https://${azurerm_linux_web_app.frontend.name}.azurewebsites.net"
}
output "frontend_app_registration_client_id" {
  value = azuread_application.frontend_app.client_id
}

output "frontend_service_principal_id" {
  value = azuread_service_principal.frontend_sp.object_id
}
