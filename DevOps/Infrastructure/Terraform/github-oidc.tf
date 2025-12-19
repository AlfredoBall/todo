// GitHub OIDC App Registration for Production CI/CD
// This creates an Azure AD app registration with federated identity credentials
// that allows GitHub Actions workflows to authenticate to Azure without client secrets.
//
// The federated credential uses OIDC token exchange where GitHub Actions requests
// a short-lived token scoped to the specific repository and branch.

resource "azuread_application" "github_oidc" {
  display_name = var.github_oidc_app_name

  sign_in_audience = "AzureADMyOrg"

  tags = ["HideApp", "GitHubActions", "OIDC"]
}

resource "azuread_service_principal" "github_oidc_sp" {
  client_id = azuread_application.github_oidc.client_id

  tags = ["HideApp", "GitHubActions", "OIDC"]
}

// Federated identity credential that trusts GitHub Actions from the specified repository
resource "azuread_application_federated_identity_credential" "github_actions" {
  application_id = azuread_application.github_oidc.id
  display_name   = "GitHub Actions - ${var.github_repo_name}"
  description    = "Allows GitHub Actions workflows from ${var.github_repo_owner}/${var.github_repo_name} on branch ${var.github_branch} to authenticate to Azure"
  audiences      = ["api://AzureADTokenExchange"]

  # Subject format: repo:<owner>/<repo>:ref:refs/heads/<branch>
  # This scopes the credential to a specific repository and branch
  subject = "repo:${var.github_repo_owner}/${var.github_repo_name}:ref:refs/heads/${var.github_branch}"
  issuer  = "https://token.actions.githubusercontent.com"
}
