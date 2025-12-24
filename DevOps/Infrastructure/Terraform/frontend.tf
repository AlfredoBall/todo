resource "azuread_application" "frontend_app" {
  display_name            = "To Do Frontend App"
  sign_in_audience        = var.sign_in_audience
  prevent_duplicate_names = true

  api {
    requested_access_token_version = 2
  }

  single_page_application {
    redirect_uris = [
      "https://${azurerm_linux_web_app.frontend.default_hostname}/todo/react",
      "https://${azurerm_linux_web_app.frontend.default_hostname}/todo/angular"
      # Add additional redirect URIs as needed for your Angular/React apps
    ]
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }

  required_resource_access {
    resource_app_id = azuread_application.api_app_registration.client_id

    resource_access {
      id   = "b3a1d2e4-9c3f-4d1b-8a2f-1d2e3f4a5b6c" # access_as_user
      type = "Scope"
    }
  }

  feature_tags {
    enterprise = false
    hide       = false
  }
}

resource "azuread_service_principal" "frontend_sp" {
  client_id = azuread_application.frontend_app.client_id
  feature_tags {
    enterprise = false
  }
}
// App Service for the combined frontend (Angular + React)
resource "azurerm_linux_web_app" "frontend" {
  name                = var.frontend_app_service_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.api_service_plan.id

  site_config {
    always_on = false
    # Add custom site_config as needed (e.g., for static file serving)
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    # Add any environment variables needed for your frontend
    # e.g., "POLICIES_PATH" = "/policies"
  }
}

data "azuread_service_principal" "microsoft_graph" {
  client_id    = "00000003-0000-0000-c000-000000000000"
}

# Grant admin consent for API access_as_user to the frontend app service principal
resource "azuread_service_principal_delegated_permission_grant" "frontend_api_access_as_user" {
  service_principal_object_id          = azuread_service_principal.api_sp.object_id
  resource_service_principal_object_id = azuread_service_principal.api_sp.object_id
  claim_values                         = ["access_as_user"]
}

# Grant admin consent for Microsoft Graph User.Read to the frontend app service principal
resource "azuread_service_principal_delegated_permission_grant" "frontend_graph_user_read" {
  service_principal_object_id          = azuread_service_principal.api_sp.object_id
  resource_service_principal_object_id = data.azuread_service_principal.microsoft_graph.object_id
  claim_values                         = ["User.Read", "openid"]

  # Enforce the order to ensure openid is applied correctly
  depends_on = [azuread_service_principal_delegated_permission_grant.frontend_api_access_as_user]
}
