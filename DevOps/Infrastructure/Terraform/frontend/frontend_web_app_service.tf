// App Service for the combined frontend (Angular + React)
resource "azurerm_linux_web_app" "frontend" {
	name                = var.frontend_app_service_name
	location            = var.location
	resource_group_name = var.resource_group_name
	service_plan_id     = var.service_plan_id

	site_config {
		always_on = false
		
		application_stack {
      		node_version = "22-lts"
    	}
	}

	app_settings = {
		WEBSITE_RUN_FROM_PACKAGE = 1
		# Add any environment variables needed for your frontend
		# e.g., "POLICIES_PATH" = "/policies"
	}
}
