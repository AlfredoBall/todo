// Azure AD App Registration for the API
resource "azuread_application" "api_app_registration" {
	display_name            = "To Do API"
	sign_in_audience        = var.sign_in_audience
	prevent_duplicate_names = true

    api {
        oauth2_permission_scope {
            admin_consent_description      = "Allow the app to access the To Do API on behalf of the signed-in user."
            admin_consent_display_name     = "Access To Do API"
            type                          = "User"
            value                         = "access_as_user"
            user_consent_description      = "Allow the application to access the To Do API on your behalf."
            user_consent_display_name     = "Access To Do API"
            enabled                       = true
            id                            = "b7e7e8e2-8c2a-4e2a-9e2a-123456789abc" # Example static UUID, replace as needed
	    }

        requested_access_token_version = 2
    }


	feature_tags {
		enterprise = false
		hide       = false
	}
}

resource "azuread_application_identifier_uri" "api_identifier_uri" {
	application_id = azuread_application.api_app_registration.id
	identifier_uri = "api://${azuread_application.api_app_registration.client_id}"
}

resource "azuread_service_principal" "api_sp" {
	client_id = azuread_application.api_app_registration.client_id
  
	feature_tags {
		enterprise = false
	}
}
