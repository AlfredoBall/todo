# GitHub OIDC Setup for Production CI/CD

## Overview

This guide explains how to set up GitHub Actions OIDC authentication for deploying to Azure **production environments**. 

**CRITICAL**: Both the Azure AD app registration and GitHub environment must be **created manually** as prerequisites. This avoids the chicken-and-egg problem where GitHub Actions needs the environment and credentials that would be created by Terraform running in that environment.

### What You Create Manually
1. Azure AD app registration for GitHub OIDC
2. Federated identity credential (no client secret needed!)
3. GitHub environment with secrets and variables

### What Terraform Creates
- Azure resources (Resource Group, App Services, Static Web Apps, etc.)
- Azure AD app registrations for the applications (API, Angular, React)

## Prerequisites

### Required Azure Permissions

**CRITICAL**: The Azure account used to create the OIDC app registration must have:
- **Owner** or **User Access Administrator** role on the subscription (to grant RBAC roles to the OIDC principal)
- **Application Administrator** or **Global Administrator** role in Azure AD (to create app registrations)

This is a **one-time bootstrap process**. After initial setup, the OIDC principal can manage future deployments.

### Tools

1. **Azure CLI** installed and authenticated with privileged account
   ```bash
   az login  # Must authenticate as user with Owner + App Admin roles
   ```

2. **Terraform** configured with required variables (for Azure resource deployment)

## Step 1: Create OIDC App Registration Manually

### Why Manual Creation?

Creating the OIDC app registration and GitHub environment manually avoids the chicken-and-egg problem:
- GitHub Actions workflows need the environment and Azure credentials to run
- If Terraform created the environment, the workflow couldn't run to create it
- By creating both manually first, GitHub Actions can authenticate and deploy from the start

### Option A: Azure Portal

1. Navigate to **Azure AD** → **App registrations** → **New registration**

2. Configure the application:
   - **Name**: `github-actions-oidc-{your-repo-name}` (e.g., `github-actions-oidc-todo`)
   - **Supported account types**: **Accounts in this organizational directory only** (Single tenant)
   - **Redirect URI**: Leave blank
   - Click **Register**

3. Note the **Application (client) ID** - you'll need this for `terraform.tfvars`

4. Add Federated Identity Credential:
   - Go to **Certificates & secrets** → **Federated credentials** tab
   - Click **Add credential**
   - **Federated credential scenario**: Select **GitHub Actions deploying Azure resources**
   - **Organization**: Your GitHub username or organization (e.g., `AlfredoBall`)
   - **Repository**: Your repo name (e.g., `todo`)
   - **Entity type**: Select **Branch**
   - **Branch name**: The branch that will deploy (e.g., `main`)
   - **Name**: `github-{branch}-credential` (e.g., `github-main-credential`)
   - Click **Add**

### Option B: Azure CLI

```bash
# Set your values
REPO_OWNER="your-github-username"
REPO_NAME="your-repo-name"
BRANCH="main"
APP_NAME="github-actions-oidc-${REPO_NAME}"

# Create the app registration
APP_ID=$(az ad app create \
  --display-name "$APP_NAME" \
  --query appId -o tsv)

echo "Application (Client) ID: $APP_ID"
echo "Save this value for terraform.tfvars!"

# Get the object ID (different from app ID)
OBJECT_ID=$(az ad app show --id $APP_ID --query id -o tsv)

# Create federated identity credential
az ad app federated-credential create \
  --id $OBJECT_ID \
  --parameters @- <<EOF
{
  "name": "github-${BRANCH}-credential",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:${REPO_OWNER}/${REPO_NAME}:ref:refs/heads/${BRANCH}",
  "audiences": [
    "api://AzureADTokenExchange"
  ]
}
EOF

echo "OIDC app registration created successfully!"
echo "Client ID: $APP_ID"
```

### Grant RBAC Permissions

The OIDC service principal needs permissions to manage your Azure resources:

```bash
# Get your subscription and resource group
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
RESOURCE_GROUP="your-resource-group-name"

# Grant Contributor role on the resource group
az role assignment create \
  --assignee $APP_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
```

**Note**: If the resource group doesn't exist yet, you can grant Contributor at the subscription level (less secure) or create the resource group first.

## Step 2: Create GitHub Environment Manually

### Why Manual Creation?

The GitHub environment must exist before the workflow runs. If Terraform tried to create it, the workflow would need to run inside an environment that doesn't exist yet (chicken-and-egg).

### Create the Environment

1. Go to your GitHub repository
2. Navigate to **Settings** → **Environments**
3. Click **New environment**
4. Name it `production` (or your preferred name)
5. Click **Configure environment**

### Add Required Secrets

Click **Add secret** for each of these:

1. **AZURE_CLIENT_ID**
   - Value: The Application (Client) ID from Step 1

2. **AZURE_SUBSCRIPTION_ID**
   - Value: Your Azure subscription ID
   ```bash
   az account show --query id -o tsv
   ```

3. **AZURE_TENANT_ID**
   - Value: Your Azure tenant ID
   ```bash
   az account show --query tenantId -o tsv
   ```

### Add Required Variables

Click **Add variable** for each of these (these must match your `terraform.tfvars` values):

1. **AZURE_RESOURCE_GROUP**
   - Value: Your resource group name (e.g., `todo-rg`)

2. **AZURE_API_APP_SERVICE_NAME**
   - Value: Your API app service name (e.g., `todo-api-app-service`)

3. **AZURE_STATIC_WEBAPP_NAME_REACT**
   - Value: Your React static web app name (e.g., `todo-react-swa`)

4. **AZURE_STATIC_WEBAPP_NAME_ANGULAR**
   - Value: Your Angular static web app name (e.g., `todo-angular-swa`)

**CRITICAL**: These variable values **must exactly match** the corresponding values in your `terraform.tfvars` file. The GitHub Actions workflows will use these to deploy to the resources that Terraform creates.

## Step 3: Configure Terraform Variables

Add these to your `terraform.tfvars` file:

**⚠️ Security Note**: The `terraform.tfvars` file in this repository is checked in for educational purposes only. In production, NEVER commit this file - use environment variables, Azure Key Vault, or Terraform Cloud instead. See [TERRAFORM.md](TERRAFORM.md) for details.

```hcl
# Azure Configuration  
subscription_id                  = "your-subscription-id"
tenant_id                        = "your-tenant-id"
resource_group_name              = "todo-rg"                          # MUST match GitHub environment variable
api_app_service_name             = "todo-api-app-service"             # MUST match GitHub environment variable
angular_static_web_app_name      = "todo-angular-swa"                # MUST match GitHub environment variable
react_static_web_app_name        = "todo-react-swa"                  # MUST match GitHub environment variable
```

### Getting Your Values

**Azure Subscription ID**: **REQUIRED**
```bash
az account show --query id -o tsv
```

**Azure Tenant ID**: **REQUIRED**
```bash
az account show --query tenantId -o tsv
```

**Resource and App Names**: These values **must exactly match** the GitHub environment variables you created in Step 2. The GitHub Actions workflows will use the environment variables to deploy to the resources that Terraform creates with these names.

## Step 4: Run Terraform to Create Azure Resources

Now that the OIDC app registration and GitHub environment exist, you can run Terraform to create the Azure resources:

```powershell
# Authenticate with Azure
az login

# Navigate to production Terraform directory
cd DevOps/Infrastructure/Terraform

# Initialize and apply
terraform init -upgrade
terraform plan
terraform apply
```

### What Terraform Creates

- **Azure Resource Group** (if it doesn't exist)
- **Azure AD App Registrations** for the applications:
  - To Do API
  - To Do Angular
  - To Do React
- **Azure App Service Plan** and **App Service** for the API
- **Azure Static Web Apps** for Angular and React frontends

## Step 5: Verify Setup

### Check Azure Portal
1. Go to **Azure Active Directory** → **App registrations**
2. Verify the OIDC app registration from Step 1
3. Navigate to **Certificates & secrets** → **Federated credentials**
4. Verify the credential is scoped to your repo/branch

### Check GitHub Environment
1. Go to `https://github.com/<owner>/<repo>/settings/environments`
2. Select the environment (e.g., "production")
3. Verify secrets: `AZURE_CLIENT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_TENANT_ID`
4. Verify variables: `AZURE_RESOURCE_GROUP`, `AZURE_API_APP_SERVICE_NAME`, `AZURE_STATIC_WEBAPP_NAME_ANGULAR`, `AZURE_STATIC_WEBAPP_NAME_REACT`

### GitHub Actions Can Now Run

After this setup, GitHub Actions workflows can use the OIDC credentials and environment to deploy applications. No bootstrap catch-22!

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

## Troubleshooting

### "OIDC token validation failed in workflow"
**Solution**: 
- Verify the federated credential subject matches your repo/branch exactly: `repo:owner/name:ref:refs/heads/branch`
- Check workflow permissions include `id-token: write`
- Ensure the workflow is running on the correct branch specified in the federated credential
- Verify audiences is set to `["api://AzureADTokenExchange"]`

### "GitHub environment not found in workflow"
**Solution**: The environment must be created manually in GitHub (Step 2). Verify it exists at `Settings` → `Environments`.

### "Resource names don't match between Terraform and GitHub"
**Solution**: The resource names in `terraform.tfvars` **must exactly match** the GitHub environment variables created in Step 2. Check for typos or case differences.
**Solution**: This is the chicken-and-egg problem! The OIDC app registration must be created manually BEFORE running Terraform in CI/CD. Follow Step 1 to create it manually.

### "Resource group already exists"
**Solution**: Import the existing resource group into Terraform state:
```bash
terraform import azurerm_resource_group.main /subscriptions/<SUB_ID>/resourceGroups/<RG_NAME>
```

## Security Best Practices

1. **Branch Protection**: Limit OIDC federation to protected branches (e.g., `main`)
2. **Environment Protection**: Configure GitHub environment protection rules (required reviewers, deployment branches)
3. **Least Privilege**: Assign minimal Azure RBAC roles needed for deployment
4. **Audit Logs**: Monitor Azure AD sign-in logs for the GitHub OIDC app
5. **Rotation**: No secrets to rotate! OIDC tokens are short-lived by design
6. **Environment Secrets**: Use GitHub environment secrets (not repository secrets) for better access control

## Multiple Environments

To create separate environments (e.g., staging, production):

1. **Create Multiple OIDC Apps**: One for each environment/branch
   ```bash
   # Production
   APP_ID_PROD=$(az ad app create --display-name "github-actions-oidc-todo-prod" --query appId -o tsv)
   
   # Staging
   APP_ID_STAGING=$(az ad app create --display-name "github-actions-oidc-todo-staging" --query appId -o tsv)
   ```

2. **Create Federated Credentials**: One for each branch
   - Production: subject = `repo:owner/name:ref:refs/heads/main`
   - Staging: subject = `repo:owner/name:ref:refs/heads/development`

3. **Create GitHub Environments**: One for each deployment target
   - Environment: `production` with secrets for production OIDC app
   - Environment: `staging` with secrets for staging OIDC app

4. **Configure Workflows**: Use different environments based on branch
   ```yaml
   jobs:
     deploy-staging:
       if: github.ref == 'refs/heads/development'
       environment: staging
     
     deploy-production:
       if: github.ref == 'refs/heads/main'
       environment: production
   ```

## Additional Resources

- [GitHub OIDC with Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [Azure Workload Identity Federation](https://learn.microsoft.com/azure/active-directory/develop/workload-identity-federation)
- [Terraform GitHub Provider](https://registry.terraform.io/providers/integrations/github/latest/docs)
