output "api_app_registration_client_id" {
  value = azuread_application.api_app_registration.client_id
}

output "api_scope_id" {
  value = azuread_application_oauth2_permission_scope.api_access_as_user.id
}

output "api_service_principal_id" {
  value = azuread_service_principal.api_sp.object_id
}
