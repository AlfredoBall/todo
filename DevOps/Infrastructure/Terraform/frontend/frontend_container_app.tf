// App Service for the combined frontend (Angular + React)

resource "azurerm_container_app_environment" "frontend_environment" {
  name                       = "Environment-${title(var.target_env)}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
}

resource "azurerm_container_app" "frontend_app" {
  name                         = var.frontend_container_app_name
  container_app_environment_id = azurerm_container_app_environment.frontend_environment.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  registry {
    server = "docker.io"
    username = var.dockerhub_username
    password_secret_name  = "dockerhub-password"
  }

  ingress {
    # For HTTP/HTTPS, specify the port your app listens on
    external_enabled = true
    target_port = 8080
    traffic_weight {
      percentage = 100
    }
  }

  template {
    min_replicas = 1
    max_replicas = 3

    container {
      name   = var.frontend_container_name
      image  = "${var.dockerhub_username}/${var.frontend_image}"
      cpu    = 0.25
      memory = "0.5Gi"
      liveness_probe {
        transport = "HTTP"
        port      = 8080
        path      = "/health"
        interval_seconds = 15
        failure_count_threshold = 3
        timeout = 5
        initial_delay = 3

        header {
          name  = "Custom-Header"
          value = "HealthCheck"
        }
      }
    }
  }

  secret {
    name  = "dockerhub-password"
    value = "${secret.dockerhub_password}"
  }
}

# resource "azurerm_linux_web_app" "frontend" {
# 	name                = var.frontend_container_app_name
# 	location            = var.location
# 	resource_group_name = var.resource_group_name
# 	service_plan_id     = var.service_plan_id

# 	site_config {
# 		always_on = false
		
# 		application_stack {
# 			docker_image_name = "${var.dockerhub_username}/${var.frontend_image}"
#     		docker_registry_url = "https://index.docker.io"
# 		}
# 	}

# 	app_settings = {
# 		WEBSITES_PORT = 80
# 		DOCKER_ENABLE_CI = "true"
# 	}
# }