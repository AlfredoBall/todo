// App Service for the combined frontend (Angular + React)
resource "azurerm_linux_web_app" "frontend" {
	name                = var.frontend_app_service_name
	location            = var.location
	resource_group_name = var.resource_group_name
	service_plan_id     = var.service_plan_id

	site_config {
		always_on = false
		
		application_stack {
			docker_image_name = "${var.dockerhub_username}/${var.frontend_image}"
    		docker_registry_url = "https://index.docker.io"
		}
	}

	app_settings = {
		WEBSITES_PORT = 80
		DOCKER_ENABLE_CI = "true"
		API_BASE_URL = "todo-api-app-service-development.azurewebsites.net"
	}
}
