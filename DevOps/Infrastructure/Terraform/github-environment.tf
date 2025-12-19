// GitHub Environment Configuration for Production Deployments
// Creates a GitHub environment with secrets and variables needed for deploying to Azure.
// The secrets reference the GitHub OIDC app registration created in github-oidc.tf.

resource "github_repository_environment" "production" {
  repository  = var.github_repo_name
  environment = var.github_environment_name

  # Optional: Configure deployment protection rules
  # deployment_branch_policy {
  #   protected_branches     = false
  #   custom_branch_policies = true
  # }
}

// Azure credentials for OIDC authentication (no client secret required)
resource "github_actions_environment_secret" "azure_client_id" {
  repository      = var.github_repo_name
  environment     = github_repository_environment.production.environment
  secret_name     = "AZURE_CLIENT_ID"
  plaintext_value = azuread_application.github_oidc.client_id
}

resource "github_actions_environment_secret" "azure_subscription_id" {
  repository      = var.github_repo_name
  environment     = github_repository_environment.production.environment
  secret_name     = "AZURE_SUBSCRIPTION_ID"
  plaintext_value = var.subscription_id
}

resource "github_actions_environment_secret" "azure_tenant_id" {
  repository      = var.github_repo_name
  environment     = github_repository_environment.production.environment
  secret_name     = "AZURE_TENANT_ID"
  plaintext_value = var.tenant_id
}

// Azure resource names as variables (not sensitive, can be public)
resource "github_actions_environment_variable" "azure_resource_group" {
  repository    = var.github_repo_name
  environment   = github_repository_environment.production.environment
  variable_name = "AZURE_RESOURCE_GROUP"
  value         = var.resource_group_name
}

resource "github_actions_environment_variable" "azure_api_app_service_name" {
  repository    = var.github_repo_name
  environment   = github_repository_environment.production.environment
  variable_name = "AZURE_API_APP_SERVICE_NAME"
  value         = var.api_app_service_name
}

resource "github_actions_environment_variable" "azure_static_webapp_name_angular" {
  repository    = var.github_repo_name
  environment   = github_repository_environment.production.environment
  variable_name = "AZURE_STATIC_WEBAPP_NAME_ANGULAR"
  value         = var.angular_static_web_app_name
}

resource "github_actions_environment_variable" "azure_static_webapp_name_react" {
  repository    = var.github_repo_name
  environment   = github_repository_environment.production.environment
  variable_name = "AZURE_STATIC_WEBAPP_NAME_REACT"
  value         = var.react_static_web_app_name
}
