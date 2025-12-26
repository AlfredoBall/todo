  # Create 1 instance if production, 0 if development

resource "azurerm_log_analytics_workspace" "api" {
  count               = var.target_env == "production" ? 1 : 0
  
  name                = "${var.api_app_service_name}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "api" {
  count               = var.target_env == "production" ? 1 : 0

  name                = "${var.api_app_service_name}-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id  = azurerm_log_analytics_workspace.api.id
}