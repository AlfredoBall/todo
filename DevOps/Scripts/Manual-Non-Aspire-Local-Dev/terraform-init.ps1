<#
Generic Terraform backend initialization script for PowerShell.
Reads backend config from environment variables and runs `terraform init` with the correct -backend-config args.

Required environment variables:
  TF_RESOURCE_GROUP        # Resource group for the storage account
  TF_STORAGE_ACCOUNT       # Storage account name (must be globally unique)
  TF_CONTAINER             # Blob container name (e.g. tfstate)
  TF_KEY                   # State file name/key (e.g. todo.terraform.tfstate)
  TF_SUBSCRIPTION_ID       # Azure subscription ID (GUID)
  TF_TENANT_ID             # Azure tenant ID (GUID)

Usage:
  # PowerShell (set variables in your shell or via a .env file)
  $env:TF_RESOURCE_GROUP = '<your-tfstate-resource-group>'
  $env:TF_STORAGE_ACCOUNT = '<your-storage-account>'
  $env:TF_CONTAINER = 'tfstate'
  $env:TF_KEY = 'todo.terraform.tfstate'
  $env:TF_SUBSCRIPTION_ID = '<your-subscription-id>'
  $env:TF_TENANT_ID = '<your-tenant-id>'
  .\Manual-Non-Aspire-Local-Dev\terraform-init.ps1 -WorkingDir 'Manual-Non-Aspire-Local-Dev/Infrastructure/Terraform'

See backend.env.example for a template.
#>

param(
  [string]$WorkingDir = 'Manual-Non-Aspire-Local-Dev/Infrastructure/Terraform'
)

function Fail([string]$msg) {
  Write-Error $msg
  exit 1
}

$rg = $env:TF_RESOURCE_GROUP
$acct = $env:TF_STORAGE_ACCOUNT
$container = $env:TF_CONTAINER
$key = $env:TF_KEY
$sub = $env:TF_SUBSCRIPTION_ID
$tenant = $env:TF_TENANT_ID

if (-not $rg)      { Fail 'TF_RESOURCE_GROUP is not set' }
if (-not $acct)    { Fail 'TF_STORAGE_ACCOUNT is not set' }
if (-not $container) { Fail 'TF_CONTAINER is not set' }
if (-not $key)     { Fail 'TF_KEY is not set' }
if (-not $sub)     { Fail 'TF_SUBSCRIPTION_ID is not set' }
if (-not $tenant)  { Fail 'TF_TENANT_ID is not set' }

Write-Host "Initializing Terraform in '$WorkingDir' using backend storage account '$acct' (container: $container)"

Push-Location $WorkingDir
try {
  $args = @(
    'init',
    "-backend-config=resource_group_name=$rg",
    "-backend-config=storage_account_name=$acct",
    "-backend-config=container_name=$container",
    "-backend-config=key=$key",
    "-backend-config=subscription_id=$sub",
    "-backend-config=tenant_id=$tenant"
  )

  Write-Host "Running: terraform $($args -join ' ')"
  terraform @args
  $exit = $LASTEXITCODE
  if ($exit -ne 0) { Fail "terraform init failed with exit code $exit" }
}
finally {
  Pop-Location
}
