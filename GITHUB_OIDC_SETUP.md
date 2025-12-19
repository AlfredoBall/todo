# GitHub OIDC Setup for Production CI/CD

## Overview

This guide explains how to set up GitHub Actions OIDC authentication for deploying to Azure **production environments**. This configuration is in `DevOps/Infrastructure/Terraform` (production), NOT in `Terraform-Dev` (local development).

Terraform automatically creates:
- Azure AD app registration for GitHub Actions
- Federated identity credential (no client secret needed!)
- GitHub environment with secrets and variables

## Prerequisites

### Required Azure Permissions

**CRITICAL**: The Azure account used to run this initial Terraform setup must have:
- **Owner** or **User Access Administrator** role on the subscription (to grant RBAC roles to the OIDC principal)
- **Application Administrator** or **Global Administrator** role in Azure AD (to create app registrations)

This is a **one-time bootstrap process**. After initial setup, the OIDC principal can manage future deployments.

### Required Azure Resources

**Azure Subscription**: You must have an **existing Azure subscription**. Terraform does not create subscriptions because they involve billing and financial commitments. The subscription ID must be provided in `terraform.tfvars`.

### Tools

1. **GitHub CLI** installed and authenticated (for local Terraform execution)
   ```bash
   winget install GitHub.cli
   gh auth login
   ```
   
   **Alternative**: Set `GITHUB_TOKEN` environment variable with a Personal Access Token (useful for CI/CD pipelines)
   ```bash
   export GITHUB_TOKEN="ghp_your_token_here"
   ```

2. **Azure CLI** installed and authenticated with privileged account
   ```bash
   az login  # Must authenticate as user with Owner + App Admin roles
   ```

3. **Terraform** configured with required variables

## Required Terraform Variables

Add these to your Terraform configuration (via `terraform.tfvars` or environment variables):

**⚠️ Security Note**: The `terraform.tfvars` file in this repository is checked in for educational purposes only. In production, NEVER commit this file - use environment variables, Azure Key Vault, or Terraform Cloud instead. See [TERRAFORM.md](TERRAFORM.md) for details.

```hcl
# GitHub Configuration
github_repo_owner = "your-github-username-or-org"
github_repo_name  = "your-repo-name"
github_branch     = "main"  # Branch for OIDC federation

# Azure Configuration  
subscription_id                  = "your-subscription-id"  # PREREQUISITE: Must exist (billing)
tenant_id                        = "your-tenant-id"
resource_group_name              = "your-resource-group-name"
api_app_service_name             = "your-api-app-service-name"
angular_static_web_app_name      = "your-angular-swa-name"
react_static_web_app_name        = "your-react-swa-name"
```

### Getting Your Values

**GitHub Repo Owner/Name**: From your repo URL `https://github.com/OWNER/REPO`

**Azure Subscription ID**: **REQUIRED PREREQUISITE**
```bash
az account show --query id -o tsv
```
**Important**: Terraform does NOT create Azure subscriptions because they involve billing and cost management. You must have an existing subscription before running this Terraform configuration. The subscription ID is provided in `terraform.tfvars`.

**Resource Names**: Use the names you plan to create in Azure (or existing ones)

## What Gets Created

### 1. Azure AD App Registration
- **Name**: `github-actions-oidc-{repo-name}`
- **Purpose**: Allows GitHub to authenticate to Azure without secrets
- **Federated Credential**: Scoped to your repo and branch

### 2. GitHub Environment
- **Name**: `development`
- **Secrets** (automatically set):
  - `AZURE_CLIENT_ID` - From the OIDC app registration
  - `AZURE_SUBSCRIPTION_ID` - Your Azure subscription
  - `AZURE_TENANT_ID` - Your Azure tenant

- **Variables** (automatically set):
  - `AZURE_API_APP_SERVICE_NAME` - API deployment target
  - `AZURE_RESOURCE_GROUP` - Resource group for deployments
  - `AZURE_STATIC_WEBAPP_NAME_ANGULAR` - Angular SWA name
  - `AZURE_STATIC_WEBAPP_NAME_REACT` - React SWA name

## Initial Bootstrap Process

**This is a ONE-TIME setup that must be run locally before the GitHub Actions workflow can execute.**

### Step 1: Run Terraform Locally

```powershell
# Authenticate with your privileged Azure account (Owner + App Admin)
az login

# Authenticate with GitHub
gh auth login

# Navigate to production Terraform directory
cd DevOps/Infrastructure/Terraform

# Initialize and apply
terraform init -upgrade
terraform plan
terraform apply
```

This creates:
- Azure AD app registration for GitHub OIDC
- Federated identity credential
- GitHub environment with secrets and variables

### Step 2: Grant Azure RBAC Permissions

The OIDC service principal needs permissions to deploy Azure resources:

```powershell
# Get the client ID that Terraform created
$clientId = terraform output -raw github_oidc_client_id

# Grant Contributor role on the resource group
az role assignment create `
  --assignee $clientId `
  --role "Contributor" `
  --scope "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>"

# Or grant specific roles per resource type as needed
```

### Step 3: Verify GitHub Secrets

Check that Terraform created the GitHub environment secrets:
- Go to `https://github.com/<owner>/<repo>/settings/environments`
- Select the environment (e.g., "development")
- Verify secrets: `AZURE_CLIENT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_TENANT_ID`
- Verify variables: Resource group and app service names

### Step 4: GitHub Actions Can Now Run

After this one-time setup, the GitHub Actions workflows can use the OIDC credentials for all future deployments.

## Usage in Aspire AppHost

The AppHost can be enhanced to pass GitHub-related variables to Terraform:

```csharp
var terraformApply = builder.AddExecutable("terraform-setup", "terraform", terraformDir, "apply", "-auto-approve")
    .WithEnvironment("TF_VAR_tenant_id", tenantId)
    .WithEnvironment("TF_VAR_github_repo_owner", "your-org")
    .WithEnvironment("TF_VAR_github_repo_name", "your-repo")
    // ... other variables
```

Or configure these in `terraform.tfvars` to keep them separate from the AppHost.

## Usage in GitHub Actions Workflows

Your workflow can now use the OIDC credentials:

```yaml
name: Deploy to Azure
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: development  # Uses the environment created by Terraform
    permissions:
      id-token: write  # Required for OIDC
      contents: read

    steps:
      - uses: actions/checkout@v4

      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Deploy API
        uses: azure/webapps-deploy@v2
        with:
          app-name: ${{ vars.AZURE_API_APP_SERVICE_NAME }}
          # ... deployment configuration

      - name: Deploy Angular
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN_ANGULAR }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          app_location: "/Services/Web/Angular/todo"
          # ... more configuration
```

## Azure RBAC Permissions

After Terraform creates the app registration, you need to assign Azure RBAC roles:

```bash
# Get the client ID from Terraform outputs
CLIENT_ID=$(cd DevOps/Infrastructure/Terraform-Dev && terraform output -raw github_oidc_client_id)

# Assign Contributor role on the resource group
az role assignment create \
  --assignee $CLIENT_ID \
  --role "Contributor" \
  --scope "/subscriptions/{subscription-id}/resourceGroups/{resource-group}"

# Or assign specific roles per resource
az role assignment create \
  --assignee $CLIENT_ID \
  --role "Website Contributor" \
  --scope "/subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.Web/sites/{app-service-name}"
```

**Note**: These role assignments are NOT managed by Terraform in the dev environment. You can add them manually or create a separate Terraform configuration for production that includes both the app registration and RBAC assignments.

## Verifying the Setup

### 1. Check Terraform Outputs
```bash
cd DevOps/Infrastructure/Terraform-Dev
terraform output
```

You should see:
- `github_oidc_client_id`
- `github_oidc_app_id`
- `github_environment_name`
- `github_oidc_subject`

### 2. Check Azure Portal
1. Go to **Azure Active Directory** → **App registrations**
2. Find `github-actions-oidc-{repo-name}`
3. Navigate to **Certificates & secrets** → **Federated credentials**
4. Verify the credential is scoped to your repo/branch

### 3. Check GitHub
1. Go to your repo → **Settings** → **Environments**
2. Click on **development**
3. Verify secrets and variables are present

## Troubleshooting

### "GitHub provider authentication failed"
**Solution**: Run `gh auth login` and ensure you're authenticated

### "Permission denied to create environment"
**Solution**: Ensure your GitHub account has admin access to the repository

### "OIDC token validation failed in workflow"
**Solution**: 
- Verify the federated credential subject matches your repo/branch
- Check workflow permissions include `id-token: write`
- Ensure the workflow is running on the correct branch

### "Azure role assignment required"
**Solution**: The GitHub OIDC app needs permissions to deploy. Assign appropriate RBAC roles (see section above)

## Security Best Practices

1. **Branch Protection**: Limit OIDC federation to protected branches (e.g., `main`)
2. **Environment Protection**: Configure GitHub environment protection rules
3. **Least Privilege**: Assign minimal Azure RBAC roles needed for deployment
4. **Audit Logs**: Monitor Azure AD sign-in logs for the GitHub app
5. **Rotation**: No secrets to rotate! OIDC tokens are short-lived by design
6. **Token Scoping**: GitHub Provider tokens should have `repo`, `admin:org`, and `workflow` scopes for full functionality

## CI/CD Considerations

When running Terraform in CI/CD pipelines (e.g., GitHub Actions, Azure DevOps):

**Option 1: GITHUB_TOKEN Environment Variable**
```yaml
- name: Terraform Apply
  env:
    GITHUB_TOKEN: ${{ secrets.GH_PAT }}
  run: terraform apply -auto-approve
```

**Option 2: GitHub App Authentication** (more secure for organizations)
```hcl
provider "github" {
  owner = var.github_repo_owner
  app_auth {
    id              = var.github_app_id
    installation_id = var.github_app_installation_id
    pem_file        = var.github_app_pem_file
  }
}
```

## Multiple Environments

To create separate environments (staging, production):

```hcl
# In terraform.tfvars or pass as variables
github_branch = "main"  # For production

# Or create multiple federated credentials for different branches
```

You can create separate Terraform configurations or use workspaces for different environments.

## Additional Resources

- [GitHub OIDC with Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [Azure Workload Identity Federation](https://learn.microsoft.com/azure/active-directory/develop/workload-identity-federation)
- [Terraform GitHub Provider](https://registry.terraform.io/providers/integrations/github/latest/docs)
