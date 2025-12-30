# API App Registration (Development)
resource "azuread_application" "app_registration" {
  display_name = "todo-api-dev"
  owners       = [var.azuread_client_config_id]
  sign_in_audience = var.sign_in_audience

  api {
    oauth2_permission_scope {
      admin_consent_description  = "Allows the app to access the API as the signed-in user"
      admin_consent_display_name = "Access API as user"
      enabled                    = true
      id                         = "00000000-0000-0000-0000-000000000001"
      type                       = "User"
      user_consent_description   = "Allow the application to access the API on your behalf"
      user_consent_display_name  = "Access API"
      value                      = "access_as_user"
    }
    requested_access_token_version = 2
  }

  lifecycle {
		# Prevents this resource from overwriting the URI managed below
		ignore_changes = [identifier_uris]
	}
}

resource "azuread_application_identifier_uri" "app_registration_uri" {
  application_id = azuread_application.app_registration.id
  identifier_uri = "api://${azuread_application.app_registration.client_id}"
}

resource "azuread_service_principal" "app_registration_sp" {
  client_id   = azuread_application.app_registration.client_id
  owners      = [var.azuread_client_config_id]
  use_existing = true
  depends_on  = [azuread_application_identifier_uri.app_registration_uri]
}
