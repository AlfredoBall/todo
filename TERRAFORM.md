## Terraform + Azure Backend (GitHub OIDC) — Documentation

## ⚠️ Important Security Note

**The `terraform.tfvars` file in this repository contains sensitive information and is checked into source control as an educational exception.**

In a production environment, `terraform.tfvars` should **NEVER** be committed to version control because it contains:
- Subscription IDs
- Tenant IDs  
- Resource names that could expose infrastructure details
- Potentially other sensitive configuration

**Best practices for production:**
- Add `terraform.tfvars` to `.gitignore`
- Use environment variables: `TF_VAR_*`
- Use Azure Key Vault or HashiCorp Vault for secrets
- Use Terraform Cloud/Enterprise for remote state and variable management
- Use CI/CD pipeline secrets for automated deployments

**Why this repo is different:** For demonstration and learning purposes, the maintainer has chosen to include this file to make the setup process clearer. This is a conscious trade-off between security and educational value.

---

This document describes Terraform configuration for **production** deployments using Azure Blob Storage backend and GitHub Actions OIDC authentication.

**Note**: For local development, see [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md) or [ASPIRE_TERRAFORM_SETUP.md](ASPIRE_TERRAFORM_SETUP.md). The Aspire AppHost handles Terraform automatically with local state.

---

### Development vs Production

| Aspect | Development (Aspire) | Production (CI/CD) |
|--------|---------------------|-------------------|
| **Terraform State** | Local file | Azure Blob Storage |
| **Authentication** | `az login` | GitHub OIDC |
| **Execution** | Aspire AppHost | GitHub Actions |
| **Variables** | Hardcoded in AppHost.cs | Passed via workflow |
| **Backend** | None | Required |

---

### ⚠️ IMPORTANT: Backend Storage Must Be Created First

**BEFORE running `terraform init` for the first time, you MUST manually create the Azure Storage backend.**

Terraform cannot create its own backend storage during initialization. This is a one-time manual setup step that must be completed either:

1. **Via PowerShell/Azure CLI** (recommended - see Quick CLI bootstrap section below)
2. **Via Azure Portal**:
   - Create a resource group (e.g., `rg-terraform-state`)
   - Create a Storage Account (StorageV2, LRS or GRS)
   - Create a blob container named `tfstate`
   - Grant your identity `Storage Blob Data Contributor` role on the storage account

**Why?** Terraform's backend configuration is evaluated during `terraform init` before any resources can be created. This creates a chicken-and-egg problem that requires the backend storage to exist beforehand.

**After creating the backend storage**, use the provided initialization scripts:
- PowerShell: `.\DevOps\Scripts\terraform-init.ps1`
- Bash: `./DevOps/Scripts/terraform-init.sh`

See `backend.env.example` for the required environment variables.

---

### Key Concepts
- Backend must be provisioned before `terraform init`. Terraform does not create the storage account/container during backend initialization.
- Authenticate with Azure AD (recommended) rather than passing storage access keys. When using AD auth, grant the identity `Storage Blob Data Contributor` on the storage account/container.
- Use OIDC federated credentials for GitHub Actions: create an app registration, add a federated credential scoped to your repo, and grant RBAC to that app's service principal.

---

### Quick CLI bootstrap (create RG, storage account, container)
**Run these commands ONCE before your first `terraform init`.**
Replace names and subscription values as needed.

PowerShell example:

```powershell
# create resource group
az group create --name rg-terraform-state --location centralus

# create storage account (name must be globally unique)
$sa = "tfstate$(Get-Random -Maximum 9999)"
az storage account create --name $sa --resource-group rg-terraform-state --location centralus --sku Standard_LRS --kind StorageV2 --https-only true

# create container
$key = (az storage account keys list -g rg-terraform-state -n $sa --query '[0].value' -o tsv)
az storage container create --name tfstate --account-name $sa --account-key $key

# enable blob versioning & soft-delete (recommended)
az storage account blob-service-properties update -g rg-terraform-state -n $sa --enable-versioning true --delete-retention-days 30
```

Notes:
- Prefer AD auth: if the identity that runs Terraform has RBAC on the storage account, you can omit `access_key` when running `terraform init`.

---

### Create App Registration + Federated Credential (example)
1. Create app registration and service principal

```powershell
# create app
APP_ID=$(az ad app create --display-name "github-actions-terraform" --query appId -o tsv)
# create SP
az ad sp create --id $APP_ID
```

2. Assign RBAC (least privilege) for backend and resource operations

```powershell
# grant storage blob data contributor on the storage account
az role assignment create --assignee $APP_ID --role "Storage Blob Data Contributor" --scope "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-terraform-state/providers/Microsoft.Storage/storageAccounts/<STORAGE_ACCOUNT>"

# grant contributor on the target resource group (only if Terraform needs it)
az role assignment create --assignee $APP_ID --role "Contributor" --scope "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<TARGET_RG>"
```

3. Add federated credential allowing GitHub OIDC tokens

**For production (main branch):**
```powershell
az ad app federated-credential create --id $APP_ID --parameters '{
  "name":"github-oidc-main",
  "issuer":"https://token.actions.githubusercontent.com",
  "subject":"repo:<GITHUB_ORG>/<REPO_NAME>:ref:refs/heads/main",
  "audiences":["api://AzureADTokenExchange"]
}'
```

**For development/testing (development branch - optional):**
```powershell
az ad app federated-credential create --id $APP_ID --parameters '{
  "name":"github-oidc-development",
  "issuer":"https://token.actions.githubusercontent.com",
  "subject":"repo:<GITHUB_ORG>/<REPO_NAME>:ref:refs/heads/development",
  "audiences":["api://AzureADTokenExchange"]
}'
```

**Subject pattern options:**
- Branch: `repo:OWNER/REPO:ref:refs/heads/BRANCH_NAME`
- Pull request: `repo:OWNER/REPO:pull_request`
- Environment: `repo:OWNER/REPO:environment:ENV_NAME`
- Tag: `repo:OWNER/REPO:ref:refs/tags/TAG_NAME`

For detailed information on configuring OIDC with Azure and security best practices, see:
- [GitHub Docs: Configuring OpenID Connect in Azure](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-azure)
- [Microsoft Docs: Workload identity federation](https://docs.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation)

---

### GitHub Actions (OIDC) skeleton
Use `azure/login@v2` with `id-token: write` permission in the job. Do NOT store client secrets.

```yaml
name: Terraform
on: [push]

jobs:
  terraform:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Azure login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}     # appId of the app registration
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2

      - name: Terraform Init
        run: |
          terraform init -backend-config="resource_group_name=rg-terraform-state" \
