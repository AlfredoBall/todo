# React App Registration (Development)
resource "azuread_application" "app_registration" {
  display_name = "todo-frontend-dev"
  owners       = [var.azuread_client_config_id]
  sign_in_audience = var.sign_in_audience

  api {
    requested_access_token_version = 2
  }

  single_page_application {
    redirect_uris = [
      var.redirect_uri
    ]
  }

  required_resource_access {
    resource_app_id = var.api_app_registration_client_id

    resource_access {
      id   = "00000000-0000-0000-0000-000000000001"
      type = "Scope"
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "service_principal" {
  client_id   = azuread_application.app_registration.client_id
  owners      = [var.azuread_client_config_id]
}

# Grant admin consent for API access_as_user to frontend service principal
resource "azuread_service_principal_delegated_permission_grant" "api_access_as_user" {
  service_principal_object_id           = azuread_service_principal.service_principal.object_id
  resource_service_principal_object_id  = var.api_app_registration_service_principal_id
  claim_values                         = ["access_as_user"]
}

# Grant admin consent for Microsoft Graph User.Read to todo-react-dev service principal
resource "azuread_service_principal_delegated_permission_grant" "frontend_graph_user_read" {
  service_principal_object_id           = azuread_service_principal.service_principal.object_id
  resource_service_principal_object_id  = data.azuread_service_principal.microsoft_graph.object_id
  claim_values                         = ["openid","User.Read"]

   # Enforce the order to ensure openid is applied correctly
  depends_on = [azuread_service_principal_delegated_permission_grant.api_access_as_user]
}

