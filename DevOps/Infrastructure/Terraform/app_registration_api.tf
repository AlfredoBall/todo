// Azure AD App Registration for the API
resource "azuread_application" "api_app_registration" {
  display_name     = "To Do API"
  sign_in_audience = "AzureADMyOrg"
  prevent_duplicate_names = true

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

  # Optional: add web redirect URIs, owners, or additional settings as needed.
  # reply_urls = ["https://your-app/callback"]
}

# Set identifier URI after app is created using time_sleep for replication
resource "time_sleep" "wait_for_api_app" {
  depends_on = [azuread_application.api_app_registration]
  create_duration = "60s"
}

resource "azuread_application_identifier_uri" "api_identifier_uri" {
  application_id = azuread_application.api_app_registration.id
  identifier_uri = "api://${azuread_application.api_app_registration.client_id}"
  
  depends_on = [time_sleep.wait_for_api_app]
}

resource "time_sleep" "wait_for_api_sp" {
  depends_on = [azuread_application_identifier_uri.api_identifier_uri]
  create_duration = "30s"
}

resource "azuread_service_principal" "api_sp" {
  client_id = azuread_application.api_app_registration.client_id
  
  feature_tags {
    enterprise = false
  }
  
  depends_on = [time_sleep.wait_for_api_sp]
}


