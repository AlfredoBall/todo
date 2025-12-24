resource "azuread_service_principal" "frontend_sp" {
	client_id = azuread_application.frontend_app.client_id
	feature_tags {
		enterprise = false
	}
}

data "azuread_service_principal" "microsoft_graph" {
	client_id    = "00000003-0000-0000-c000-000000000000"
}

# Grant admin consent for API access_as_user to the frontend app service principal
resource "azuread_service_principal_delegated_permission_grant" "frontend_api_access_as_user" {
	service_principal_object_id          = azuread_service_principal.frontend_sp.object_id
	resource_service_principal_object_id = var.api_service_principal_id
	claim_values                         = ["access_as_user"]
}

# Grant admin consent for Microsoft Graph User.Read to the frontend app service principal
resource "azuread_service_principal_delegated_permission_grant" "frontend_graph_user_read" {
	service_principal_object_id          = azuread_service_principal.frontend_sp.object_id
	resource_service_principal_object_id = data.azuread_service_principal.microsoft_graph.object_id
	claim_values                         = ["User.Read", "openid"]

	# Enforce the order to ensure openid is applied correctly
	depends_on = [azuread_service_principal_delegated_permission_grant.frontend_api_access_as_user]
}
