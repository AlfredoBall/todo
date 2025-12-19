// Static Web App for React
resource "azurerm_static_web_app" "react" {
  name                = var.react_static_web_app_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_tier            = "Free"
  sku_size            = "Free"
  # Managed identity is not supported on Free tier and not required for AAD authentication
  # See documentation for configuring authentication and custom domains
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/static_web_app
}


// Static Web App for Angular
resource "azurerm_static_web_app" "angular" {
  name                = var.angular_static_web_app_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_tier            = "Free"
  sku_size            = "Free"
  # Managed identity is not supported on Free tier and not required for AAD authentication
  # See documentation for configuring authentication and custom domains
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/static_web_app
}


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

    # Configure App Service CORS origins to allow requests from the Static Web Apps
    cors {
      allowed_origins = [
        "https://${azurerm_static_web_app.react.default_host_name}",
        "https://${azurerm_static_web_app.angular.default_host_name}"
      ]
      support_credentials = true
    }
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "REACT_URL"                = "https://${azurerm_static_web_app.react.default_host_name}"
    "ANGULAR_URL"              = "https://${azurerm_static_web_app.angular.default_host_name}"
    "RunWithAuth"              = "true"
    # Add other settings as needed
  }

  # App Service "Easy Auth" (auth_settings) removed so the application can handle authentication and CORS
  # auth_settings {
  #   enabled = true
  #   issuer  = "https://sts.windows.net/${var.tenant_id}/"
  # }
  # Authentication is handled by the application (Microsoft.Identity.Web) and CORS is configured in Program.cs.
}

// Terraform resources for the Todo infrastructure

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.resource_tags
}

