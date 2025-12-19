# Development Environment Setup Guide

This guide explains how to set up your local development environment for the Todo application. The Aspire AppHost automatically runs Terraform to create Azure AD app registrations and configures all services.

---

## Prerequisites

- **Azure subscription** with permission to create app registrations
- **Azure CLI** installed and authenticated (`az login`)
- **Terraform** (>= 1.0) installed and in PATH
- **.NET SDK** (>= 10.0)
- **Node.js** (>= 18.x)
- **Docker Desktop** running



---

## Quick Start (Recommended)

The easiest way to get started is to run the Aspire AppHost:

### 1. Login to Azure
```bash
az login
```

### 2. Configure Tenant ID

**Option A: User Secrets (Recommended)**
```bash
cd Services/Aspire/Todo.AppHost
dotnet user-secrets set "Azure:TenantId" "your-tenant-id-guid"
```

**Option B: Configuration File**
Add to `Services/Aspire/Todo.AppHost/appsettings.Development.json`:
```json
{
  "Azure": {
    "TenantId": "your-tenant-id-guid"
  }
}
```

**Get your tenant ID:**
```bash
az account show --query tenantId -o tsv
```

### 3. Run Aspire AppHost
```bash
cd Services/Aspire/Todo.AppHost
dotnet run
```

That's it! The AppHost will automatically:
1. ✅ Run `terraform init` (first time only)
2. ✅ Run `terraform apply -auto-approve` to create Azure AD app registrations
3. ✅ Extract configuration from Terraform outputs
4. ✅ Inject environment variables into API, React, and Angular
5. ✅ Start all services with proper authentication
6. ✅ Open the Aspire dashboard in your browser

**No .env files or manual configuration needed for local development!**

---

## Manual Setup (Not Recommended)

If you need to run services independently without Aspire:

### 1. Run Terraform Manually

```bash
cd DevOps/Infrastructure/Terraform-Dev

# Initialize (first time only)
terraform init

# Create app registrations
terraform apply \
  -var="tenant_id=your-tenant-id" \
  -var="api_redirect_uri=https://localhost:7258/" \
  -var="react_redirect_uri=https://localhost:5173/" \
  -var="angular_redirect_uri=https://localhost:4200/"

# Get outputs
terraform output -json
```

### 2. Configure Services Manually

You'll need to create configuration files and set environment variables based on the Terraform outputs. This is tedious and error-prone - **use Aspire instead!**

---

## What Gets Created

### Azure AD App Registrations

When you first run the application, Terraform creates three app registrations in your Azure AD tenant:

| Name | Type | Redirect URI | Scopes | Purpose |
|------|------|-------------|--------|----------|
| `todo-api-dev` | Web API | `https://localhost:7258/` | `access_as_user` | Backend API |
| `todo-react-dev` | SPA | `https://localhost:5173/` | User.Read, API access | React frontend |
| `todo-angular-dev` | SPA | `https://localhost:4200/` | User.Read, API access | Angular frontend |

### How Configuration Works

**No .env files in development!** Aspire injects configuration at runtime:

**API Configuration** (injected via `WithEnvironment`):
```csharp
context.EnvironmentVariables["AzureAd__ClientId"] = outputs.ApiClientId;
context.EnvironmentVariables["AzureAd__TenantId"] = outputs.TenantId;
context.EnvironmentVariables["AzureAd__Audience"] = outputs.ApiAudience;
```

**React Configuration** (injected via `WithEnvironment`):
```csharp
context.EnvironmentVariables["VITE_CLIENT_ID"] = outputs.ReactClientId;
context.EnvironmentVariables["VITE_TENANT_ID"] = outputs.TenantId;
context.EnvironmentVariables["VITE_API_SCOPES"] = $"[\"{outputs.ApiScope}\"]";
// ... all other VITE_* variables
```

**Angular Configuration** (injected via `WithEnvironment`):
```csharp
context.EnvironmentVariables["NG_APP_AzureAd__ClientID"] = outputs.AngularClientId;
context.EnvironmentVariables["NG_APP_AzureAd__TenantId"] = outputs.TenantId;
context.EnvironmentVariables["NG_APP_apiScopes"] = outputs.ApiScope;
// ... all other NG_APP_* variables
```

---

## Starting the Applications

### With Aspire (Recommended)

```bash
cd Services/Aspire/Todo.AppHost
dotnet run
```

Access the Aspire dashboard to view all services, logs, and status.

### Running Services Individually (Without Aspire)

Only do this if you can't use Aspire:

```bash
# Start API (requires manual Azure AD config)
cd Services/API/Todo.API
dotnet run

# Start React
cd Services/Web/React/todo
npm install
npm run dev

# Start Angular  
cd Services/Web/Angular/todo
npm install
npm start
```

**Note**: When running without Aspire, you must manually configure Azure AD settings for each service.

---

## Troubleshooting

### "Azure:TenantId configuration is required"
**Solution**: Set your tenant ID using User Secrets or appsettings.Development.json (see Quick Start section)

### "terraform not found"
**Solution**: Install Terraform and ensure it's in your PATH. Restart your terminal/IDE after installation.

### "az command not found"  
**Solution**: Install Azure CLI, run `az login`, and restart your terminal/IDE.

### Terraform apply fails
**Solutions**:
- Ensure you're logged in: `az login`
- Check you have permissions to create app registrations in Azure AD
- View detailed error messages in the Aspire dashboard

### Services won't start
**Solutions**:
- Ensure Docker Desktop is running
- Check the Aspire dashboard for detailed error logs
- Verify all prerequisites are installed

---

## Development Workflow

### Daily Development
```bash
# Just run Aspire - everything is automatic!
cd Services/Aspire/Todo.AppHost
dotnet run
```

### Clean Slate (Delete and Recreate)
```bash
# Destroy Azure AD app registrations
cd DevOps/Infrastructure/Terraform-Dev
terraform destroy

# Next time you run Aspire, it will recreate everything
cd Services/Aspire/Todo.AppHost
dotnet run
```

### View Terraform State
```bash
cd DevOps/Infrastructure/Terraform-Dev
terraform show
terraform output -json
```
