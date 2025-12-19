// Azure AD App Registration for the API
resource "azuread_application" "api_app_registration" {
  display_name     = "To Do API"
  sign_in_audience = "AzureADMyOrg"
  
  identifier_uris = ["api://${azuread_application.api_app_registration.client_id}"]

  # Expose an API scope so other apps can request consent
  api {
    oauth2_permission_scope {
      admin_consent_description  = "Allow the app to access the To Do API on behalf of the signed-in user."
      admin_consent_display_name = "Access To Do API"
      id                         = "b3a1d2e4-9c3f-4d1b-8a2f-1d2e3f4a5b6c"
      type                       = "User"
      value                      = "access_as_user"
      user_consent_description   = "Allow the application to access the To Do API on your behalf."
      user_consent_display_name  = "Access To Do API"
    }
    
    # CRITICAL: Set this to 2 to ensure tokens have the api:// prefix in the aud claim
    requested_access_token_version = 2
  }

  feature_tags {
    enterprise = false
    hide       = false
  }
  
  lifecycle {
    ignore_changes = [identifier_uris]
  }

  # Optional: add web redirect URIs, owners, or additional settings as needed.
  # reply_urls = ["https://your-app/callback"]
}


resource "azuread_service_principal" "api_sp" {
  client_id = azuread_application.api_app_registration.client_id
  
  feature_tags {
    enterprise = false
  }
}


