# Generates a .env file for Angular from Terraform outputs
param(
    [string]$TerraformDir = "../../../../DevOps/Infrastructure/Terraform-Dev",
    [string]$EnvPath = "../../Services/Web/Angular/todo/src/environments/environment.development.ts"
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
    "NG_APP_AzureAd__ClientID"      = $json.frontend_app_registration_client_id.value
    "NG_APP_AzureAd__TenantId"      = $json.tenant_id.value
    "NG_APP_apiScopes"              = $json.api_scope_uri.value
    "NG_APP_AzureAd__Audience"      = $json.api_audience.value
    "NG_APP_AzureAd__Instance"      = "https://login.microsoftonline.com/"
    "NG_APP_RedirectUri"            = "https://localhost:4200"
    "NG_APP_PostLogoutRedirectUri"  = "https://localhost:4200"
    "NG_APP_API_BASE_URL"           = "/api"
    "NG_APP_AzureAd__Scopes"        = "access_as_user"
    "NG_APP_production"             = "false"
}

# Write to environment.development.ts file
try {
    $tsContent = @()
    $tsContent += "export const environment = {"
    foreach ($kvp in $envVars.GetEnumerator()) {
        $key = $kvp.Key
        $value = $kvp.Value
        if ($value -eq $null) { $value = '' }
        if ($value -eq 'true' -or $value -eq 'false') {
            $tsContent += "    $($key): $($value),"
        } elseif ($value -match '^[0-9]+$') {
            $tsContent += "    $($key): $($value),"
        } else {
            $escaped = $value.Replace("'", "\'")
            $tsContent += "    $($key): '$escaped',"
        }
    }
    $tsContent += "};"
    $tsContent | Set-Content -Path $EnvPath -Encoding UTF8
    Write-Host "[generate-angular-dev-env.ps1] environment.development.ts file generated at $EnvPath"
} catch {
    Write-Error "[generate-angular-dev-env.ps1] Failed to write environment.development.ts file: $_"
    exit 1
}
