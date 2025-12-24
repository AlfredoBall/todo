// App Service Plan for the API
resource "azurerm_service_plan" "api_service_plan" {
  name                = var.api_service_plan_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "F1"
}

// App Service for the API
resource "azurerm_linux_web_app" "api" {
  name                = var.api_app_service_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.api_service_plan.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      dotnet_version = "10.0"
    }
    always_on = false

    # Configure App Service CORS origins to allow requests from the frontend web app
    # (Update this if you use custom domains)
    cors {
      allowed_origins = [
        "https://${azurerm_linux_web_app.frontend.default_hostname}",
        "https://${azurerm_linux_web_app.frontend.default_hostname}"
      ]
      support_credentials = true
    }
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "FRONTEND_URL"             = "https://${azurerm_linux_web_app.frontend.default_hostname}"
    "RunWithAuth"              = "true"
    # Azure AD configuration for token validation
    "AzureAd__TenantId" = var.tenant_id
    "AzureAd__ClientId" = azuread_application.api_app_registration.client_id
    "AzureAd__Audience" = "api://${azuread_application.api_app_registration.client_id}"
    "AzureAd__Instance" = "https://login.microsoftonline.com/"
    "AzureAd__Scopes"   = "access_as_user"
  }
}

// Terraform resources for the Todo infrastructure

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.resource_tags
}