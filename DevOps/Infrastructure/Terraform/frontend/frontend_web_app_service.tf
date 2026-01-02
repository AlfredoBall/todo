// App Service for the combined frontend (Angular + React)
resource "azurerm_linux_web_app" "frontend" {
	name                = var.frontend_app_service_name
	location            = var.location
	resource_group_name = var.resource_group_name
	service_plan_id     = var.service_plan_id

	site_config {
		always_on = false
		
		linux_fx_version = "DOCKER|${var.dockerhub_username}/${var.frontend_image}"
	}

	app_settings = {
		WEBSITES_PORT = 80
	}
}
