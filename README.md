# Todo Application

A full-stack todo application built with .NET 10, Angular, React, and Azure AD authentication, orchestrated with .NET Aspire and infrastructure managed by Terraform.

## Architecture

- **Backend API**: .NET 10 Web API with Azure AD authentication
- **Frontend**: Angular and React SPAs
- **Cache**: Redis with Commander UI and RedisInsight
- **Database**: In-memory EF Core (for Azure Free Tier demo)
- **Infrastructure**: Terraform for Azure AD app registrations
- **Orchestration**: .NET Aspire

## Prerequisites

Before running this application, ensure you have the following tools installed and configured:

### Required Tools

1. **[.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0)**
   ```bash
   dotnet --version  # Verify installation
   ```

2. **[Docker Desktop](https://www.docker.com/products/docker-desktop)**
   ```bash
   docker --version  # Verify installation
   ```
   - **Required for .NET Aspire** - Must be running before starting the application
   - Used for Redis and other containerized services

3. **[Terraform](https://www.terraform.io/downloads)** (v1.0+)
   ```bash
   terraform version  # Verify installation
   winget install Hashicorp.Terraform
   ```
   - **Must be in your system PATH**

4. **[Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)**
   ```bash
   az --version      # Verify installation
   az login          # Authenticate
   winget install Microsoft.AzureCLI
   ```
   - **Must be in your system PATH**

5. **[GitHub CLI](https://cli.github.com/)** - For GitHub OIDC setup
   ```bash
   gh --version      # Verify installation
   gh auth login     # Authenticate with GitHub
   winget install GitHub.cli
   ```
   - **Required for Terraform to configure GitHub environments**
   - **Must be authenticated before running Terraform**

6. **[Node.js](https://nodejs.org/)** (v18+) - For Angular/React frontends
   ```bash
   node --version
   npm --version
   ```

### Optional Development Tools

- **[kubectl](https://kubernetes.io/docs/tasks/tools/)** - For Kubernetes deployments
- **[aztfexport](https://github.com/Azure/aztfexport)** - For exporting existing Azure resources to Terraform
- **Entity Framework Core Tools**:
  ```bash
  dotnet tool install --global dotnet-ef
  ```

## Environment Setup

### 1. Start Docker Desktop

**Before running the application, ensure Docker Desktop is running:**

- Windows: Start Docker Desktop from the Start menu
- Verify: `docker ps` should return without errors

### 2. Configure Azure Tenant ID

Your Azure AD tenant ID must be configured before running the application. The Aspire AppHost reads this from configuration.

**Recommended: User Secrets** (Best for development)
```bash
cd Services/Aspire/Todo.AppHost
dotnet user-secrets set "Azure:TenantId" "your-tenant-id-guid"
```

**Alternative: Configuration File** (Simpler but less secure)

Add to `Services/Aspire/Todo.AppHost/appsettings.Development.json`:
```json
{
  "Azure": {
    "TenantId": "your-tenant-id-guid"
  }
}
```

**Find your tenant ID:**
```bash
az login
az account show --query tenantId -o tsv
```

### 3. Run Aspire AppHost

That's it! Just run the AppHost and everything else is automatic:

```bash
cd Services/Aspire/Todo.AppHost
dotnet run
```

The AppHost will automatically:
1. ✅ Run `terraform init` (first time only)
2. ✅ Run `terraform apply` to create Azure AD app registrations
3. ✅ Extract client IDs and configuration from Terraform outputs
4. ✅ Inject all environment variables into API, React, and Angular
5. ✅ Start all services with correct configuration
6. ✅ Open the Aspire dashboard in your browser

### 3. Run Aspire AppHost

That's it! Just run the AppHost and everything else is automatic:

```bash
cd Services/Aspire/Todo.AppHost
dotnet run
```

The AppHost will automatically:
1. ✅ Run `terraform init` (first time only)
2. ✅ Run `terraform apply` to create Azure AD app registrations
3. ✅ Extract client IDs and configuration from Terraform outputs
4. ✅ Inject all environment variables into API, React, and Angular
5. ✅ Start all services with correct configuration
6. ✅ Open the Aspire dashboard in your browser

**No .env files or manual configuration needed!**

## What Gets Created in Azure

When you run the application for the first time, Terraform creates three Azure AD app registrations:

| Name | Type | Redirect URI | Purpose |
|------|------|-------------|----------|
| `todo-api-dev` | Web API | `https://localhost:7258/` | Backend API with `access_as_user` scope |
| `todo-react-dev` | SPA | `https://localhost:5173/` | React frontend |
| `todo-angular-dev` | SPA | `https://localhost:4200/` | Angular frontend |

All configuration is automatically managed - you don't need to touch the Azure portal!

### 4. Verify PATH Configuration

Ensure all required tools are accessible from your command line:

```cmd
where terraform    # Should show path to terraform.exe
where az           # Should show path to az.exe or az.cmd
where dotnet       # Should show path to dotnet.exe
where node         # Should show path to node.exe
where docker       # Should show path to docker.exe
```

**Important**: After installing tools, restart your terminal or IDE for PATH changes to take effect.

## How It Works

### Aspire + Terraform Integration

The Aspire AppHost uses `AddExecutable` to run Terraform as part of the orchestration:

```csharp
var terraformInit = builder.AddExecutable("terraform-init", "terraform", terraformDir, "init")
    .WithEnvironment("TF_CLI_ARGS", "-no-color");

var terraformApply = builder.AddExecutable("terraform-setup", "terraform", terraformDir, "apply", "-auto-approve")
    .WaitForCompletion(terraformInit)
    .WithEnvironment("TF_VAR_tenant_id", tenantId)
    .WithEnvironment("TF_VAR_api_redirect_uri", "https://localhost:7258/")
    .WithEnvironment("TF_VAR_react_redirect_uri", "https://localhost:5173/")
    .WithEnvironment("TF_VAR_angular_redirect_uri", "https://localhost:4200/");
```

### Configuration Flow

1. **Tenant ID** is read from User Secrets or appsettings
2. **Terraform runs** with the tenant ID and redirect URIs
3. **Outputs are extracted** using `terraform output -json`
4. **Environment variables** are injected into each service via `WithEnvironment` callbacks
5. **Services start** with proper Azure AD configuration

### Services Wait for Terraform

All services use `WaitForCompletion` to ensure Terraform finishes before they start:

```csharp
var api = builder.AddProject<Todo_API>("API")
    .WaitForCompletion(terraformApply, 0)  // Wait for Terraform
    .WithEnvironment(async context => {
        var outputs = await GetTerraformOutputs(terraformDir);
        context.EnvironmentVariables["AzureAd__ClientId"] = outputs.ApiClientId;
        // ... more configuration
    });
```

## Running the Application

### Using .NET Aspire (Recommended - One Command!)

1. **Ensure Docker Desktop is running**
   ```bash
   docker ps  # Should work without errors
   ```

2. **Run the AppHost**:
   ```bash
   cd Services/Aspire/Todo.AppHost
   dotnet run
   ```

3. **Access the Aspire Dashboard**
   - Opens automatically in your browser
   - Typically: `https://localhost:17XXX`
   - View all service logs and status in one place

4. **What You'll See**:
   - ✅ **terraform-init**: Initializes Terraform (first run only)
   - ✅ **terraform-setup**: Creates Azure AD app registrations
   - ✅ **cache (Redis)**: Starts via Docker
   - ✅ **API**: .NET API with Azure AD authentication
   - ✅ **Todo-Angular**: Angular SPA on https://localhost:4200
   - ✅ **Todo-React**: React SPA on https://localhost:5173 (if uncommented)

All services are monitored in the Aspire dashboard with live logs!

## Project Structure

```
todo/
??? Services/
?   ??? API/
?   ?   ??? Todo.API/              # .NET 10 Web API with Azure AD auth
?   ??? Aspire/
?   ?   ??? Todo.AppHost/          # Aspire orchestration (START HERE)
?   ?   ??? Todo.ServiceDefaults/  # Shared Aspire configuration
?   ??? Data/
?   ?   ??? Todo.Data.Entity/      # EF Core entities and DbContext
?   ?   ??? Todo.Data.Access/      # DTOs and data models
?   ?   ??? Todo.Data.Service/     # Business logic and services
?   ??? scripts/
?       ??? Set-AzureAdEnv.bat     # Batch script for env setup
?       ??? Set-AzureAdEnv.ps1     # PowerShell script for env setup
??? Web/
?   ??? Angular/todo/              # Angular 18+ SPA
?   ??? React/todo/                # React 18+ SPA
??? DevOps/
    ??? Infrastructure/
        ??? Terraform-Dev/         # Azure AD infrastructure as code
```

## Configuration

### Tenant ID Configuration (Required)

The only configuration you need to provide is your Azure tenant ID. Choose one method:

**Method 1: User Secrets (Recommended)**
```bash
cd Services/Aspire/Todo.AppHost
dotnet user-secrets set "Azure:TenantId" "your-tenant-id-guid"
```

**Method 2: appsettings.Development.json**
```json
{
  "Azure": {
    "TenantId": "your-tenant-id-guid"
  }
}
```

### Auto-Configured by Aspire

Everything else is automatically configured from Terraform outputs:

**API receives:**
- `AzureAd__ClientId` - API client ID
- `AzureAd__TenantId` - Tenant ID  
- `AzureAd__Audience` - API audience URI

**Angular receives:**
- `NG_APP_AzureAd__ClientID` - Angular client ID
- `NG_APP_AzureAd__TenantId` - Tenant ID
- `NG_APP_apiScopes` - API access scope
- All other NG_APP_* variables

**React receives:**
- `VITE_CLIENT_ID` - React client ID
- `VITE_TENANT_ID` - Tenant ID
- `VITE_API_SCOPES` - API access scope
- All other VITE_* variables

### Customizing Ports

To change the default ports, edit `AppHost.cs`:

```csharp
.WithEnvironment("TF_VAR_api_redirect_uri", "https://localhost:YOUR_PORT/")
.WithEnvironment("TF_VAR_react_redirect_uri", "https://localhost:YOUR_PORT/")
.WithEnvironment("TF_VAR_angular_redirect_uri", "https://localhost:YOUR_PORT/")
```

**Note**: You must also update the corresponding `launch.json` files for Angular/React to use the same ports.

## Troubleshooting

### "Docker is not running" or Aspire fails to start
**Cause**: Docker Desktop is not running  
**Solution**:
1. Start Docker Desktop from Windows Start menu
2. Wait for Docker to fully initialize (whale icon in system tray)
3. Verify with: `docker ps`
4. Restart Aspire AppHost

### "terraform not found"
**Cause**: Terraform is not installed or not in PATH  
**Solution**:
1. Install: `winget install Hashicorp.Terraform`
2. Verify PATH: `where terraform`
3. Restart terminal/IDE

### "az not found"
**Cause**: Azure CLI is not installed or not in PATH  
**Solution**:
1. Install: `winget install Microsoft.AzureCLI`
2. Login: `az login`
3. Verify: `az account show`
4. Restart terminal/IDE

### "Azure:TenantId configuration is required"
**Cause**: Tenant ID not configured  
**Solution**:
1. Set via User Secrets: `dotnet user-secrets set "Azure:TenantId" "your-guid"`
2. OR add to `appsettings.Development.json`
3. Get your tenant ID: `az account show --query tenantId -o tsv`
4. Restart the AppHost

### Terraform apply fails
**Possible causes**:
- Not logged into Azure: Run `az login`
- Insufficient permissions: Check Azure AD role assignments
- Existing resources: Review Terraform state and Azure portal

**Solution**:
- Check Aspire dashboard for detailed error messages
- Run `terraform plan` manually in `DevOps/Infrastructure/Terraform-Dev` to debug

### API returns 401 Unauthorized
**Possible causes**:
- Azure AD app registration not created
- Client IDs don't match
- Token not included in request
- Redirect URIs misconfigured

**Solution**:
1. Verify app registrations exist in Azure portal
2. Check Aspire dashboard for Terraform output values
3. Confirm redirect URIs match between code and Azure portal
4. Test authentication flow in frontend app

### Redis connection fails
**Cause**: Docker/Redis not running  
**Solution**:
- Ensure Docker Desktop is running
- Check Aspire dashboard for Redis container status
- Verify no port conflicts on 6379
- Try: `docker ps` to see running containers

## Development Workflows

### Running Individual Services

**API only (without Aspire)**:
```bash
cd Services/API/Todo.API
dotnet run
```
*Note: You'll need to manually configure Azure AD settings*

**Angular frontend**:
```bash
cd Web/Angular/todo
npm install
npm start
```

**React frontend**:
```bash
cd Web/React/todo
npm install
npm run dev
```

### Working with Terraform Directly

To manually manage infrastructure:

```bash
cd DevOps/Infrastructure/Terraform-Dev

# Initialize
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# View outputs
terraform output -json

# Destroy resources
terraform destroy
```

### Database Migrations (For Production)

This demo uses in-memory database. For real deployments:

1. **Replace in `Program.cs`**:
   ```csharp
   // Remove:
   options.UseInMemoryDatabase("TodoDB");
   
   // Add:
   options.UseSqlServer(builder.Configuration.GetConnectionString("TodoDB"));
   ```

2. **Add migration**:
   ```bash
   cd Services/API/Todo.API
   dotnet ef migrations add InitialCreate
   ```

3. **Update database**:
   ```bash
   dotnet ef database update
   ```

## CI/CD Setup (Optional)

Want to deploy to Azure production using GitHub Actions? See [GITHUB_OIDC_SETUP.md](GITHUB_OIDC_SETUP.md) for setting up secure, secret-less authentication with Azure.

The production Terraform configuration (`DevOps/Infrastructure/Terraform`) can automatically create:
- Azure AD app registration for GitHub OIDC
- GitHub environment with deployment secrets/variables
- No client secrets needed - uses OpenID Connect!

**Note:** This is separate from local development (`Terraform-Dev`) and only needed for CI/CD deployments.

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit changes: `git commit -am 'Add my feature'`
4. Push to branch: `git push origin feature/my-feature`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Additional Resources

- [.NET Aspire Documentation](https://learn.microsoft.com/dotnet/aspire/)
- [Terraform Azure AD Provider](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs)
- [Azure AD Authentication](https://learn.microsoft.com/azure/active-directory/develop/)
- [Angular with MSAL](https://github.com/AzureAD/microsoft-authentication-library-for-js/tree/dev/lib/msal-angular)
- [React with MSAL](https://github.com/AzureAD/microsoft-authentication-library-for-js/tree/dev/lib/msal-react)
- [GitHub OIDC with Azure](GITHUB_OIDC_SETUP.md)