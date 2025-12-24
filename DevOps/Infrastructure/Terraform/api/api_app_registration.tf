// Azure AD App Registration for the API
resource "azuread_application" "api_app_registration" {
	display_name     = "To Do API"
	sign_in_audience = var.sign_in_audience
	prevent_duplicate_names = true

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
