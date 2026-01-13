// App container for the combined frontend (Angular + React)

resource "azurerm_container_app" "frontend_app" {
  name                         = var.frontend_container_app_name
  container_app_environment_id = var.todo_environment_id
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
      latest_revision  = true
    }
  }

  template {
    min_replicas = 0
    max_replicas = 1

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
    value = "${ var.dockerhub_password }"
  }
}