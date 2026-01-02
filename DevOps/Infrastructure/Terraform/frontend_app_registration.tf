resource "azuread_application" "frontend_app" {
	display_name            = "${"To Do Frontend App"} - ${title(var.target_env)}"
	sign_in_audience        = var.sign_in_audience
	prevent_duplicate_names = true

	api {
		requested_access_token_version = 2
	}

	single_page_application {
		redirect_uris = [
			"https://${azurerm_linux_web_app.frontend.default_hostname}/todo/react",
			"https://${azurerm_linux_web_app.frontend.default_hostname}/todo/angular"
			# Add additional redirect URIs as needed for your Angular/React apps
		]
	}

	required_resource_access {
		resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

		resource_access {
			id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
			type = "Scope"
		}
	}

	required_resource_access {
		resource_app_id = azuread_application.api_app_registration.client_id

		resource_access {
			id   = tolist(azuread_application.api_app_registration.api[0].oauth2_permission_scope)[0].id
			type = "Scope"
		}
	}

	feature_tags {
		enterprise = false
		hide       = false
	}
}
