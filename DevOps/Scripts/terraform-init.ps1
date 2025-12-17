<#
Wraps `terraform init` and reads backend configuration from environment
variables. Useful for local shells or CI agents where you can set env vars
instead of passing many `-backend-config` CLI args.

Environment variables used (all required):
  TF_RESOURCE_GROUP
  TF_STORAGE_ACCOUNT
  TF_CONTAINER
  TF_KEY
  TF_SUBSCRIPTION_ID
  TF_TENANT_ID

Usage:
  # PowerShell
  $env:TF_RESOURCE_GROUP = 'todo-rg'
  $env:TF_STORAGE_ACCOUNT = 'todo-tfstatestorage-15243'
  $env:TF_CONTAINER = 'tfstate'
  $env:TF_KEY = 'todo.terraform.tfstate'
  $env:TF_SUBSCRIPTION_ID = 'da348b35-29b6-4906-85ec-4a097aa5fe04'
  $env:TF_TENANT_ID = 'bf451fd9-d382-4da8-9c1a-179a96a4d2f3'
  .\DevOps\Scripts\terraform-init.ps1 -WorkingDir 'DevOps/Infrastructure/Terraform'
#>

param(
  [string]$WorkingDir = 'DevOps/Infrastructure/Terraform'
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

if (-not $rg) { Fail 'TF_RESOURCE_GROUP is not set' }
if (-not $acct) { Fail 'TF_STORAGE_ACCOUNT is not set' }
if (-not $container) { Fail 'TF_CONTAINER is not set' }
if (-not $key) { Fail 'TF_KEY is not set' }
if (-not $sub) { Fail 'TF_SUBSCRIPTION_ID is not set' }
if (-not $tenant) { Fail 'TF_TENANT_ID is not set' }

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
