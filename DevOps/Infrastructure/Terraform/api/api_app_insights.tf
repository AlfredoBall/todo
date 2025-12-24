resource "azurerm_application_insights" "api" {
  name                = "${var.api_app_service_name}-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
}

output "api_app_insights_instrumentation_key" {
  value = azurerm_application_insights.api.instrumentation_key
}

output "api_app_insights_connection_string" {
  value = azurerm_application_insights.api.connection_string
}
