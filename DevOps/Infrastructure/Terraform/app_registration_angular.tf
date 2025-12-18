// Azure AD App Registration for the Angular client
resource "azuread_application" "angular_app" {
  display_name     = "To Do Angular App"
  sign_in_audience = "AzureADMyOrg"

  single_page_application {
    redirect_uris = [
      "http://localhost:4200/",
      "https://${var.angular_static_web_app_name}.azurestaticapps.net/"
    ]
  }

  # Microsoft Graph API permissions
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }

  # Custom API permissions
  required_resource_access {
    resource_app_id = azuread_application.api_app_registration.client_id

    resource_access {
      id   = "b3a1d2e4-9c3f-4d1b-8a2f-1d2e3f4a5b6c"
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "angular_sp" {
  client_id = azuread_application.angular_app.client_id
}


