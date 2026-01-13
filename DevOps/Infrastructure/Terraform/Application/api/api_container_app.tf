data "azuread_client_config" "current" {}

// App container for the combined frontend (Angular + React)

resource "azurerm_container_app" "api_app" {
  name                         = var.api_container_app_name
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
      name   = var.api_container_name
      image  = "${var.dockerhub_username}/${var.api_image}"
      cpu    = 0.25
      memory = "0.5Gi"
      liveness_probe {
        transport = "HTTP"
        port      = 8080
        path      = "/healthz"
        interval_seconds = 15
        failure_count_threshold = 3
        timeout = 5
        initial_delay = 3

        header {
          name  = "Custom-Header"
          value = "HealthCheck"
        }
      }

      env {
        name  = "ASPNETCORE_ENVIRONMENT"
        value = var.target_env == "prod" ? "Production" : "Development"
      }

      env {
        name  = "WEBSITES_DISABLE_APP_SERVICE_AUTHENTICATION"
        value = "true"
      }

      env {
        name  = "AzureAd__TenantId"
        value = data.azuread_client_config.current.tenant_id
      }

      env {
        name  = "AzureAd__ClientId"
        value = azuread_application.api_app_registration.client_id
      }

      env {
        name  = "AzureAd__Audience"
        value = "api://${azuread_application.api_app_registration.client_id}"
      }

      env {
        name  = "AzureAd__Instance"
        value = "https://login.microsoftonline.com/"
      }

      env {
        name  = "AzureAd__Scopes"
        value = "access_as_user"
      }
    }
  }

  secret {
    name  = "dockerhub-password"
    value = "${ var.dockerhub_password }"
  }
}