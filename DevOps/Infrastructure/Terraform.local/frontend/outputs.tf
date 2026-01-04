output "frontend_client_id" {
  description = "Frontend app registration client ID"
  value       = azuread_application.app_registration.client_id
}