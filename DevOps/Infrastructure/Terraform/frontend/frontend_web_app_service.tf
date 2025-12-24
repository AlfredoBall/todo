// App Service for the combined frontend (Angular + React)
resource "azurerm_linux_web_app" "frontend" {
	name                = var.frontend_app_service_name
	location            = azurerm_resource_group.rg.location
	resource_group_name = azurerm_resource_group.rg.name
	service_plan_id     = azurerm_service_plan.service_plan.id

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
