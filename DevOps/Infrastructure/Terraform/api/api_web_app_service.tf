resource "azurerm_linux_web_app" "api" {
  name                = var.api_app_service_name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = var.service_plan_id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      dotnet_version = "10.0"
    }
    always_on = false

    # Configure App Service CORS origins to allow requests from the frontend web app
    cors {
      allowed_origins = [
        "https://${var.frontend_default_hostname}",
        "https://${var.frontend_default_hostname}"
      ]
      support_credentials = true
    }
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "FRONTEND_URL"             = "https://${var.frontend_default_hostname}"
    "RunWithAuth"              = "true"
    # Azure AD configuration for token validation
    "AzureAd__TenantId" = var.tenant_id
    "AzureAd__ClientId" = azuread_application.api_app_registration.client_id
    "AzureAd__Audience" = "api://${azuread_application.api_app_registration.client_id}"
    "AzureAd__Instance" = "https://login.microsoftonline.com/"
    "AzureAd__Scopes"   = "access_as_user"
  }
}
