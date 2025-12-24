resource "azurerm_application_insights" "api" {
  name                = "${var.api_app_service_name}-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
}
