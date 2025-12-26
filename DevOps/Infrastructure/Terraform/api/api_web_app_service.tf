resource "azurerm_windows_web_app" "api" {
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
    # remote_debugging_enabled = var.api_build_configuration == "Debug" ? true : false
    # remote_debugging_version = var.visual_studio_version
    health_check_path = "/healthz"
    health_check_eviction_time_in_min = 1
    always_on = true
  }

  app_settings = {
    # "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "FRONTEND_URL"             = "https://${var.frontend_default_hostname}"
    "WEBSITES_DISABLE_APP_SERVICE_AUTHENTICATION" = "true"
    # Azure AD configuration for token validation
    "AzureAd__TenantId" = data.azuread_client_config.current.tenant_id
    "AzureAd__ClientId" = azuread_application.api_app_registration.client_id
    "AzureAd__Audience" = "api://${azuread_application.api_app_registration.client_id}"
    "AzureAd__Instance" = "https://login.microsoftonline.com/"
    "AzureAd__Scopes"   = "access_as_user"
    # Application Insights connection string now set in app_settings
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.api.connection_string
  }
}

data "azuread_client_config" "current" {}