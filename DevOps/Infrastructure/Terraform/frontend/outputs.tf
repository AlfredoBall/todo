output "frontend_app_service_default_url" {
  description = "Default URL for the combined frontend Container App (Angular + React)"
  value       = "https://${azurerm_container_app.frontend_app.ingress.fqdn}"
}

output "frontend_app_registration_client_id" {
  value = azuread_application.frontend_app_registration.client_id
}

output "frontend_service_principal_id" {
  value = azuread_service_principal.frontend_sp.object_id
}
