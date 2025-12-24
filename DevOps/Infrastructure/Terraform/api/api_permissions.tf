resource "azuread_application_oauth2_permission_scope" "api_access_as_user" {
  application_object_id          = azuread_application.api_app_registration.object_id
  admin_consent_description      = "Allow the app to access the To Do API on behalf of the signed-in user."
  admin_consent_display_name     = "Access To Do API"
  type                           = "User"
  value                          = "access_as_user"
  user_consent_description       = "Allow the application to access the To Do API on your behalf."
  user_consent_display_name      = "Access To Do API"
  enabled                        = true
  requested_access_token_version = 2
}
