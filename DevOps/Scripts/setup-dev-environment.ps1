#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Sets up local development Azure AD app registrations using Terraform
.DESCRIPTION
    This script initializes and applies Terraform configuration to create
    development-only Azure AD app registrations for the Todo application.
    It then generates environment configuration files with the app registration details.
.EXAMPLE
    .\setup-dev-environment.ps1
#>

param(
    [switch]$SkipTerraform,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$TerraformDir = "$PSScriptRoot\..\Infrastructure\Terraform-Dev"
$ApiDir = "$PSScriptRoot\..\Services\API\Todo.API"
$ReactDir = "$PSScriptRoot\..\Services\Web\React\todo"
$AngularDir = "$PSScriptRoot\..\Services\Web\Angular\todo"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Todo App - Development Environment Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Terraform is installed
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Terraform is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Install from: https://www.terraform.io/downloads" -ForegroundColor Red
    exit 1
}

# Check if Azure CLI is installed and logged in
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Azure CLI is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Install from: https://docs.microsoft.com/cli/azure/install-azure-cli" -ForegroundColor Red
    exit 1
}

$azAccount = az account show 2>$null | ConvertFrom-Json
if (-not $azAccount) {
    Write-Host "ERROR: Not logged into Azure CLI" -ForegroundColor Red
    Write-Host "Run: az login" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Terraform installed: $(terraform version -json | ConvertFrom-Json | Select-Object -ExpandProperty terraform_version)" -ForegroundColor Green
Write-Host "✓ Azure CLI logged in as: $($azAccount.user.name)" -ForegroundColor Green
Write-Host "✓ Tenant: $($azAccount.tenantId)" -ForegroundColor Green
Write-Host ""

# Check if terraform.tfvars exists
$tfvarsPath = "$TerraformDir\terraform.tfvars"
if (-not (Test-Path $tfvarsPath)) {
    Write-Host "Creating terraform.tfvars..." -ForegroundColor Yellow
    $tenantId = $azAccount.tenantId
    @"
# Azure AD Tenant ID
tenant_id = "$tenantId"
"@ | Out-File -FilePath $tfvarsPath -Encoding utf8
    Write-Host "✓ Created terraform.tfvars with tenant ID: $tenantId" -ForegroundColor Green
    Write-Host ""
}

if (-not $SkipTerraform) {
    # Initialize Terraform
    Write-Host "Initializing Terraform..." -ForegroundColor Yellow
    Push-Location $TerraformDir
    try {
        terraform init
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform init failed"
        }
        Write-Host "✓ Terraform initialized" -ForegroundColor Green
        Write-Host ""

        # Apply Terraform configuration
        Write-Host "Creating Azure AD app registrations..." -ForegroundColor Yellow
        Write-Host "(This will create: todo-api-dev, todo-react-dev, todo-angular-dev)" -ForegroundColor Cyan
        Write-Host ""
        
        terraform apply -auto-approve
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform apply failed"
        }
        Write-Host ""
        Write-Host "✓ App registrations created successfully" -ForegroundColor Green
        Write-Host ""

        # Get Terraform outputs
        Write-Host "Retrieving configuration values..." -ForegroundColor Yellow
        $outputs = terraform output -json | ConvertFrom-Json
        $apiClientId = $outputs.api_client_id.value
        $reactClientId = $outputs.react_client_id.value
        $angularClientId = $outputs.angular_client_id.value
        $tenantId = $outputs.tenant_id.value
        $apiScope = $outputs.api_scope.value
        $apiAudience = $outputs.api_audience.value

    } finally {
        Pop-Location
    }
} else {
    Write-Host "Skipping Terraform (using existing outputs)..." -ForegroundColor Yellow
    Push-Location $TerraformDir
    try {
        $outputs = terraform output -json | ConvertFrom-Json
        $apiClientId = $outputs.api_client_id.value
        $reactClientId = $outputs.react_client_id.value
        $angularClientId = $outputs.angular_client_id.value
        $tenantId = $outputs.tenant_id.value
        $apiScope = $outputs.api_scope.value
        $apiAudience = $outputs.api_audience.value
    } finally {
        Pop-Location
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Generating environment configuration files" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Generate API appsettings.Development.json
$apiSettingsPath = "$ApiDir\appsettings.Development.json"
if ((Test-Path $apiSettingsPath) -and -not $Force) {
    Write-Host "⚠ $apiSettingsPath already exists (use -Force to overwrite)" -ForegroundColor Yellow
} else {
    $apiSettings = @{
        RunWithAuth = $true
        Logging = @{
            LogLevel = @{
                Default = "Information"
                "Microsoft.AspNetCore" = "Warning"
            }
        }
        AzureAd = @{
            Instance = "https://login.microsoftonline.com/"
            TenantId = $tenantId
            ClientId = $apiClientId
            Audience = $apiAudience
        }
    }
    $apiSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath $apiSettingsPath -Encoding utf8
    Write-Host "✓ Created $apiSettingsPath" -ForegroundColor Green
}

# Generate React .env
$reactEnvPath = "$ReactDir\.env"
if ((Test-Path $reactEnvPath) -and -not $Force) {
    Write-Host "⚠ $reactEnvPath already exists (use -Force to overwrite)" -ForegroundColor Yellow
} else {
    @"
# Vite environment variables for local development
# Auto-generated by setup-dev-environment.ps1

# Set to "true" to bypass auth in development (convenience only)
VITE_BYPASS_AUTH_IN_DEV=false

# Azure Entra ID / Microsoft Identity values
VITE_CLIENT_ID=$reactClientId
VITE_TENANT_ID=$tenantId
VITE_REDIRECT_URI=https://localhost:5173
VITE_POST_LOGOUT_REDIRECT_URI=https://localhost:5173

# API settings (use /api for development proxy)
VITE_API_BASE_URL=/api

# Scopes as a JSON array string
VITE_API_SCOPES=["$apiScope"]
"@ | Out-File -FilePath $reactEnvPath -Encoding utf8
    Write-Host "✓ Created $reactEnvPath" -ForegroundColor Green
}

# Generate Angular .env
$angularEnvPath = "$AngularDir\.env"
if ((Test-Path $angularEnvPath) -and -not $Force) {
    Write-Host "⚠ $angularEnvPath already exists (use -Force to overwrite)" -ForegroundColor Yellow
} else {
    @"
# Angular environment variables for local development
# Auto-generated by setup-dev-environment.ps1

NG_APP_bypassAuthInDev=false
NG_APP_production=false

# Azure Entra ID / Microsoft Identity values
NG_APP_AzureAd__ClientID=$angularClientId
NG_APP_AzureAd__TenantId=$tenantId
NG_APP_AzureAd__Instance=https://login.microsoftonline.com/
NG_APP_RedirectUri=https://localhost:4200
NG_APP_PostLogoutRedirectUri=https://localhost:4200

# API settings (use /api for development proxy)
NG_APP_apiBaseUrl=https://localhost:4200/api/*
NG_APP_API_BASE_URL=/api

# API Scopes
NG_APP_AzureAd__Audience=$apiAudience
NG_APP_AzureAd__Scopes=access_as_user
NG_APP_apiScopes=$apiScope
"@ | Out-File -FilePath $angularEnvPath -Encoding utf8
    Write-Host "✓ Created $angularEnvPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✓ Development environment setup complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "App Registration Details:" -ForegroundColor Cyan
Write-Host "  API Client ID:     $apiClientId" -ForegroundColor White
Write-Host "  React Client ID:   $reactClientId" -ForegroundColor White
Write-Host "  Angular Client ID: $angularClientId" -ForegroundColor White
Write-Host "  Tenant ID:         $tenantId" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Start the API:     cd Services/API/Todo.API && dotnet run" -ForegroundColor White
Write-Host "  2. Start React:       cd Services/Web/React/todo && npm run dev" -ForegroundColor White
Write-Host "  3. Start Angular:     cd Services/Web/Angular/todo && npm start" -ForegroundColor White
Write-Host ""
Write-Host "Note: You may need to grant admin consent for API permissions:" -ForegroundColor Yellow
Write-Host "  Azure Portal > Entra ID > App Registrations > todo-react-dev/todo-angular-dev > API permissions > Grant admin consent" -ForegroundColor Yellow
Write-Host ""
