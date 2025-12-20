# Aspire + Terraform Development Setup

## Overview

The Aspire AppHost automatically provisions Azure AD app registrations using Terraform and injects the configuration into all services at runtime. This eliminates manual configuration and ensures consistent environments across all developers.

## How It Works

### 1. Aspire Startup Process

When you run `dotnet run` in the AppHost:

```
1. Read Azure:TenantId from User Secrets or appsettings
2. Run terraform init (first time only)
3. Run terraform apply with tenant ID and redirect URIs
4. Wait for Terraform to complete
5. Extract outputs using terraform output -json
6. Inject environment variables into each service
7. Start services with proper configuration
```

### 2. Terraform as an Executable Resource

The AppHost uses `AddExecutable` to run Terraform as part of the orchestration:

```csharp
var terraformInit = builder.AddExecutable("terraform-init", "terraform", terraformDir, "init")
    .WithEnvironment("TF_CLI_ARGS", "-no-color");

var terraformApply = builder.AddExecutable("terraform-setup", "terraform", terraformDir, "apply", "-auto-approve")
    .WaitForCompletion(terraformInit)
    .WithEnvironment("TF_CLI_ARGS", "-no-color")
    .WithEnvironment("TF_VAR_tenant_id", tenantId)
    .WithEnvironment("TF_VAR_api_redirect_uri", "https://localhost:7258/")
    .WithEnvironment("TF_VAR_react_redirect_uri", "https://localhost:5173/")
    .WithEnvironment("TF_VAR_angular_redirect_uri", "https://localhost:4200/");
```

Benefits:
- ✅ Terraform logs appear in Aspire dashboard
- ✅ Services can depend on Terraform completion
- ✅ All orchestration in one place

### 3. Configuration Injection

Services wait for Terraform to complete, then read outputs and configure themselves:

**API** configuration:
```csharp
var api = builder.AddProject<Todo_API>("API")
    .WaitForCompletion(terraformApply, 0)  // Wait for Terraform
    .WithEnvironment(async context =>
    {
        var outputs = await GetTerraformOutputs(terraformDir);
        context.EnvironmentVariables["AzureAd__ClientId"] = outputs.ApiClientId;
        context.EnvironmentVariables["AzureAd__TenantId"] = outputs.TenantId;
        context.EnvironmentVariables["AzureAd__Audience"] = outputs.ApiAudience;
    });
```


**Angular** configuration:

> **Why is generate-angular-dev-env.ps1 needed?**
>
> The Angular app registration client ID and related values are not known until after Terraform has run and created the Azure resources. The script `generate-angular-dev-env.ps1` is run after Terraform completes, reads the outputs, and generates a `.env` file for the Angular app. This ensures the Angular app always receives the correct, dynamically-generated values for authentication and API access, without manual intervention.
> The Angular app registration client ID and related values are not known until after Terraform has run and created the Azure resources. The script `generate-angular-dev-env.ps1` is run after Terraform completes, reads the outputs, and generates a `.env` file for the Angular app. This ensures the Angular app always receives the correct, dynamically-generated values for authentication and API access, without manual intervention.

```csharp
// After Terraform completes, generate .env for Angular:
    var generateAngularEnv = builder.AddExecutable(
        "generate-angular-dev-env",
        "pwsh",
        "-File",
        Path.GetFullPath(Path.Combine(builder.AppHostDirectory, "../../../DevOps/Scripts/generate-angular-dev-env.ps1")),
        "-TerraformDir", terraformDir,
        "-EnvPath", Path.GetFullPath(Path.Combine(builder.AppHostDirectory, "../../../Services/Web/Angular/todo/.env"))
    ).WaitForCompletion(terraformApply);

builder.AddNpmApp("Todo-Angular", "../../Web/Angular/todo")
    .WithReference(api)
    .WaitFor(api)
    .WaitForCompletion(generateAngularEnv);
```

**React** configuration:
```csharp
builder.AddNpmApp("Todo-React", "../../Web/React/todo", "dev")
    .WithReference(api)
    .WaitFor(api)
    .WithEnvironment(async context =>
    {
        cachedOutputs ??= await GetTerraformOutputs(terraformDir);
        context.EnvironmentVariables["VITE_CLIENT_ID"] = cachedOutputs.ReactClientId;
        context.EnvironmentVariables["VITE_TENANT_ID"] = cachedOutputs.TenantId;
        // ... all other VITE_* variables
    });
```

### 4. Output Caching

Terraform outputs are cached to avoid multiple calls:

```csharp
TerraformOutputs? cachedOutputs = null;

// First service to start fetches the outputs
cachedOutputs ??= await GetTerraformOutputs(terraformDir);

// Subsequent services reuse the cached value
```

## Developer Experience

### First Time Setup
```bash
# 1. Login to Azure
az login

# 2. Set tenant ID
cd Services/Aspire/Todo.AppHost
dotnet user-secrets set "Azure:TenantId" "your-tenant-id-guid"

# 3. Run Aspire
dotnet run
```

### Daily Development
```bash
# Just run Aspire - everything is automatic!
cd Services/Aspire/Todo.AppHost
dotnet run
```

### Clean Slate
```bash
# Delete app registrations and start fresh
cd DevOps/Infrastructure/Terraform-Dev
terraform destroy

# Next time you run Aspire, it will recreate everything
cd Services/Aspire/Todo.AppHost
dotnet run
```

## Key Features

### No .env Files in Development
- ❌ **Local Dev**: No .env files needed - Aspire injects environment variables at runtime
- ✅ **Production**: .env files can be generated from Terraform outputs for deployed environments

### Configuration Priority
1. **User Secrets** (recommended for sensitive data like tenant ID)
2. **appsettings.Development.json** (simple but less secure)
3. **Environment Variables** (for CI/CD)

### Port Configuration
Default redirect URIs are hardcoded in AppHost.cs for consistency:
- API: `https://localhost:7258/`
- React: `https://localhost:5173/`
- Angular: `https://localhost:4200/`

These match the ports in the respective `launch.json` files to ensure predictable behavior.

## Benefits

1. **Zero Manual Configuration**: No copying .env.example files or editing configuration
2. **Automatic Provisioning**: App registrations created on first run
3. **Idempotent**: Can run multiple times safely - Terraform handles state
4. **Isolated**: Each developer gets their own app registrations
5. **Fast**: Local Terraform state, no backend complexity for development
6. **Consistent**: Same setup process for all developers
7. **Visible**: Terraform logs in Aspire dashboard for debugging
8. **Orchestrated**: Services wait for Terraform before starting

## Architecture

```
┌───────────────────────────────────────────────────────┐
│         Aspire AppHost (Program.cs)                   │
├───────────────────────────────────────────────────────┤
│                                                       │
│  1. Read Azure:TenantId from User Secrets/Config     │
│  2. AddExecutable("terraform-init", "terraform init") │
│  3. AddExecutable("terraform-setup", "apply")         │
│     - Pass TF_VAR_tenant_id                          │
│     - Pass TF_VAR_*_redirect_uri                     │
│  4. Services WaitForCompletion(terraformApply)       │
│  5. GetTerraformOutputs() via "terraform output"     │
│  6. Inject env vars via WithEnvironment callbacks    │
│                                                       │
└────────────────┬──────────────────────────────────────┘
                 │
                 ├──► API (.NET project)
                 │    - AzureAd__ClientId
                 │    - AzureAd__TenantId
                 │    - AzureAd__Audience
                 │
                 ├──► React (NPM app)
                 │    - VITE_CLIENT_ID
                 │    - VITE_TENANT_ID
                 │    - VITE_API_SCOPES
                 │
                 └──► Angular (NPM app)
                      - NG_APP_AzureAd__ClientID
                      - NG_APP_AzureAd__TenantId
                      - NG_APP_apiScopes
```

## CI/CD Flow (Production)

Production deployments don't use Aspire for orchestration. Instead:

```
Terraform (Production) → Generate Config Files → Deploy Apps
        │                        │                    │
        │                        │                    │
    Creates Azure          Writes .env files    Deployed with
    resources              from outputs         environment config
```

The development and production flows are intentionally different:
- **Development**: Aspire orchestrates Terraform + service startup with runtime injection
- **Production**: Terraform provisions infrastructure, outputs are written to config files, apps are deployed separately

## Troubleshooting

**"terraform command not found"**
- Install Terraform: `winget install Hashicorp.Terraform`
- Ensure it's in PATH
- Restart terminal/IDE

**"az command not found"**
- Install Azure CLI: `winget install Microsoft.AzureCLI`
- Run `az login`
- Restart terminal/IDE

**"Azure:TenantId configuration is required"**
- Set via User Secrets: `dotnet user-secrets set "Azure:TenantId" "your-guid"`
- OR add to appsettings.Development.json
- Get tenant ID: `az account show --query tenantId -o tsv`

**"Terraform apply failed"**
- Check you're logged in: `az account show`
- Verify permissions to create app registrations in Azure AD
- Check detailed logs in Aspire dashboard
- Try manually: `cd DevOps/Infrastructure/Terraform-Dev && terraform plan`

**"Configuration not updating"**
- Terraform state might be stale
- Delete `terraform.tfstate` and run again
- Or run `terraform apply` manually to see errors

**Services won't start**
- Ensure Docker Desktop is running
- Check Aspire dashboard for detailed error logs
- Verify Terraform completed successfully (check dashboard logs)
