# Generates a .env file for Angular from Terraform outputs
param(
    [string]$TerraformDir = "../../../../DevOps/Infrastructure/Terraform-Dev",
    [string]$EnvPath = "../../Services/Web/Angular/todo/.env"
)

Write-Host "[generate-angular-dev-env.ps1] Starting script..."
Write-Host "[generate-angular-dev-env.ps1] PWD: $PWD"
Write-Host "[generate-angular-dev-env.ps1] Script root: $PSScriptRoot"
Write-Host "[generate-angular-dev-env.ps1] TerraformDir: $TerraformDir"
Write-Host "[generate-angular-dev-env.ps1] EnvPath: $EnvPath"

# Get Terraform outputs as JSON
$tfStatePath = Join-Path $TerraformDir "terraform.tfstate"
Write-Host "[generate-angular-dev-env.ps1] Terraform state path: $tfStatePath"

try {
    $terraformOutput = terraform output -json -state "$tfStatePath" 2>&1
    Write-Host "[generate-angular-dev-env.ps1] terraform output result: $terraformOutput"
} catch {
    Write-Error "[generate-angular-dev-env.ps1] terraform output failed: $_"
    exit 1
}

if (-not $terraformOutput) {
    Write-Error "[generate-angular-dev-env.ps1] Failed to get Terraform outputs."
    exit 1
}

try {
    $json = $terraformOutput | ConvertFrom-Json
} catch {
    Write-Error "[generate-angular-dev-env.ps1] Failed to parse Terraform output as JSON: $_"
    exit 1
}

$envVars = @{
    "NG_APP_AzureAd__ClientID"      = $json.angular_client_id.value
    "NG_APP_AzureAd__TenantId"      = $json.tenant_id.value
    "NG_APP_apiScopes"              = $json.api_scope.value
    "NG_APP_AzureAd__Audience"      = $json.api_audience.value
    "NG_APP_AzureAd__Instance"      = "https://login.microsoftonline.com/"
    "NG_APP_RedirectUri"            = "https://localhost:4200"
    "NG_APP_PostLogoutRedirectUri"  = "https://localhost:4200"
    "NG_APP_API_BASE_URL"           = "/api"
    "NG_APP_AzureAd__Scopes"        = "access_as_user"
    "NG_APP_bypassAuthInDev"        = "false"
    "NG_APP_production"             = "false"
}

# Write to .env file
try {
    $lines = $envVars.GetEnumerator() | ForEach-Object { "{0}={1}" -f $_.Key, $_.Value }
    $lines | Set-Content -Path $EnvPath -Encoding UTF8
    Write-Host "[generate-angular-dev-env.ps1] .env file generated at $EnvPath"
} catch {
    Write-Error "[generate-angular-dev-env.ps1] Failed to write .env file: $_"
    exit 1
}
