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
      dotnet_version = "v10.0"
    }
    remote_debugging_enabled = var.api_build_configuration == "Debug" ? true : false
    # remote_debugging_version = var.visual_studio_version
    health_check_path = "/healthz"
    health_check_eviction_time_in_min = 2
    always_on = true
  }

  app_settings = merge(
  {
    "ASPNETCORE_ENVIRONMENT"                      = title(var.target_env)
    "FRONTEND_URL"                                = "https://${var.frontend_default_hostname}"
    "WEBSITES_DISABLE_APP_SERVICE_AUTHENTICATION" = "true"
    "AzureAd__TenantId"                           = data.azuread_client_config.current.tenant_id
    "AzureAd__ClientId"                           = azuread_application.api_app_registration.client_id
    "AzureAd__Audience"                           = "api://${azuread_application.api_app_registration.client_id}"
    "AzureAd__Instance"                           = "https://login.microsoftonline.com/"
    "AzureAd__Scopes"                             = "access_as_user"
    "ApplicationInsightsAgent_EXTENSION_VERSION"  = "~3"
  },
  # Only add this map if target_env is production
  var.target_env == "production" ? {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.api[0].connection_string
  } : {}
)
}

data "azuread_client_config" "current" {}