# Angular App Registration (Development)
resource "azuread_application" "angular_dev" {
  display_name = "todo-angular-dev"
  owners       = [data.azuread_client_config.current.object_id]
	sign_in_audience = var.sign_in_audience

  api {
    requested_access_token_version = 2
  }

  single_page_application {
    redirect_uris = [
      var.angular_redirect_uri,
      "${var.angular_redirect_uri}/redirect"
    ]
  }

  required_resource_access {
    resource_app_id = azuread_application.api_dev.client_id

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

resource "azuread_service_principal" "angular_dev_sp" {
  client_id   = azuread_application.angular_dev.client_id
  owners      = [data.azuread_client_config.current.object_id]
}

# Grant admin consent for Microsoft Graph User.Read to todo-angular-dev service principal
resource "azuread_service_principal_delegated_permission_grant" "angular_dev_graph_user_read" {
  service_principal_object_id           = azuread_service_principal.angular_dev_sp.object_id
  resource_service_principal_object_id  = data.azuread_service_principal.microsoft_graph.object_id
  claim_values                         = ["openid","User.Read"]
}

# Grant admin consent for API access_as_user to todo-angular-dev service principal
resource "azuread_service_principal_delegated_permission_grant" "angular_dev_api_access_as_user" {
  service_principal_object_id           = azuread_service_principal.angular_dev_sp.object_id
  resource_service_principal_object_id  = azuread_service_principal.api_dev_sp.object_id
  claim_values                         = ["access_as_user"]
  
  # Enforce the order you observed to ensure openid is applied correctly
  depends_on = [azuread_service_principal_delegated_permission_grant.angular_dev_api_access_as_user]
}