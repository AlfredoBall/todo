# Local Development App Registrations
# This creates Azure AD app registrations for local development only
# State is stored locally - do not commit terraform.tfstate

terraform {
  required_version = ">= 1.0"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }
}

provider "azuread" {
  tenant_id = var.tenant_id
}

# GitHub provider is NOT used for local development
# GitHub Actions integration is configured in the production Terraform directory

data "azuread_client_config" "current" {}

# API App Registration (Development)
resource "azuread_application" "api_dev" {
  display_name = "todo-api-dev"
  owners       = [data.azuread_client_config.current.object_id]

  api {
    oauth2_permission_scope {
      admin_consent_description  = "Allows the app to access the API as the signed-in user"
      admin_consent_display_name = "Access API as user"
      enabled                    = true
      id                         = "00000000-0000-0000-0000-000000000001"
      type                       = "User"
      user_consent_description   = "Allow the application to access the API on your behalf"
      user_consent_display_name  = "Access API"
      value                      = "access_as_user"
    }
  }

  web {
    redirect_uris = [var.api_redirect_uri]
  }
}

# Set identifier URI after app creation to avoid self-reference
resource "azuread_application_identifier_uri" "api_dev_uri" {
  application_id = azuread_application.api_dev.id
  identifier_uri = "api://${azuread_application.api_dev.client_id}"
}

resource "azuread_service_principal" "api_dev_sp" {
  client_id = azuread_application.api_dev.client_id
  owners    = [data.azuread_client_config.current.object_id]
  
  depends_on = [azuread_application_identifier_uri.api_dev_uri]
}

# React App Registration (Development)
resource "azuread_application" "react_dev" {
  display_name = "todo-react-dev"
  owners       = [data.azuread_client_config.current.object_id]

  single_page_application {
    redirect_uris = [
      var.react_redirect_uri,
      "${var.react_redirect_uri}/redirect"
    ]
  }

  required_resource_access {
    resource_app_id = azuread_application.api_dev.client_id

    resource_access {
      id   = "00000000-0000-0000-0000-000000000001"
      type = "Scope"
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "react_dev_sp" {
  client_id = azuread_application.react_dev.client_id
  owners    = [data.azuread_client_config.current.object_id]
}

# Angular App Registration (Development)
resource "azuread_application" "angular_dev" {
  display_name = "todo-angular-dev"
  owners       = [data.azuread_client_config.current.object_id]

  single_page_application {
    redirect_uris = [
      var.angular_redirect_uri,
      "${var.angular_redirect_uri}/redirect"
    ]
  }

  required_resource_access {
    resource_app_id = azuread_application.api_dev.client_id

    resource_access {
      id   = "00000000-0000-0000-0000-000000000001"
      type = "Scope"
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "angular_dev_sp" {
  client_id = azuread_application.angular_dev.client_id
  owners    = [data.azuread_client_config.current.object_id]
}
