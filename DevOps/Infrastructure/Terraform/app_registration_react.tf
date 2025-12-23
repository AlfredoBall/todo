// Azure AD App Registration for the React client
resource "azuread_application" "react_app" {
  display_name     = "To Do React App"
  sign_in_audience = var.sign_in_audience
  prevent_duplicate_names = true

  api {
    requested_access_token_version = 2
  }

  single_page_application {
    redirect_uris = [
      "https://${azurerm_static_web_app.react.default_host_name}/"
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

  feature_tags {
    enterprise = false
    hide       = false
  }
}

resource "azuread_service_principal" "react_sp" {
  client_id = azuread_application.react_app.client_id
  
  feature_tags {
    enterprise = false
  }
}

# Grant admin consent for API access_as_user to To Do React App service principal
resource "azuread_service_principal_delegated_permission_grant" "react_api_access_as_user" {
  service_principal_object_id           = azuread_service_principal.react_sp.object_id
  resource_service_principal_object_id  = azuread_service_principal.api_sp.object_id
  claim_values                         = ["access_as_user"]
}

# Grant admin consent for Microsoft Graph User.Read to To Do React App service principal
resource "azuread_service_principal_delegated_permission_grant" "react_graph_user_read" {
  service_principal_object_id          = azuread_service_principal.react_sp.object_id
  resource_service_principal_object_id = data.azuread_service_principal.microsoft_graph.object_id
  claim_values                        = ["User.Read", "openid"]

  # Enforce the order to ensure openid is applied correctly
  depends_on = [azuread_service_principal_delegated_permission_grant.react_api_access_as_user]
}