resource "azuread_application" "github_oidc" {
  display_name = "github-oidc-${var.github_repo}"
}

resource "azuread_service_principal" "github_oidc_sp" {
  client_id = azuread_application.github_oidc.client_id
}

resource "azuread_application_federated_identity_credential" "github_oidc_credentials" {
  for_each = toset(var.environments)

  application_id = azuread_application.github_oidc.id
  display_name   = "github-${each.key}"
  description    = "OIDC trust for environment: ${each.key}"

  audiences = ["api://AzureADTokenExchange"]
  issuer    = "https://token.actions.githubusercontent.com"

  subject = "repo:${var.github_org}/${var.github_repo}:environment:${each.key}"
}

resource "azurerm_role_assignment" "subscription_contributor" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_oidc_sp.id
}

resource "azuread_directory_role_assignment" "cloud_app_admin" {
  role_id             = data.azuread_directory_role.cloud_app_admin.id
  principal_object_id = azuread_service_principal.github_oidc_sp.id
}


data "azuread_directory_role" "cloud_app_admin" {
  display_name = "Cloud Application Administrator"
}