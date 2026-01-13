function Write-Info($msg) {
    Write-Host $msg -ForegroundColor Cyan
}

function Write-Step($msg) {
    Write-Host $msg -ForegroundColor Green
}

function Write-Warn($msg) {
    Write-Host $msg -ForegroundColor Yellow
}

function Write-ErrorMsg($msg) {
    Write-Host $msg -ForegroundColor Red
}

function Show-Banner {
@"
████████╗   ██████╗       ██████╗    ██████╗ 
╚══██╔══╝  ██╔═══██╗      ██╔══██╗  ██╔═══██╗
   ██║     ██║   ██║      ██║  ██║  ██║   ██║
   ██║     ██║   ██║      ██║  ██║  ██║   ██║
   ██║     ██╚═══██║      ██╚══██║  ██╚═══██║
   ██║     ╚██████╔╝      ██████╔╝  ╚██████╔╝
   ╚═╝      ╚═════╝       ╚═════╝    ╚═════╝
                T O D O
"@ | Write-Host -ForegroundColor Cyan
}

function Ensure-Login {
    param(
        [Parameter(Mandatory)]
        [string]$ToolName,          # e.g., "az", "aws", "gcloud"
        
        [Parameter(Mandatory)]
        [string]$LoginCommand,      # e.g., "az login", "aws configure", "gcloud auth login"
        
        [string]$StatusCommand,     # optional: e.g., "az account show"
        
        [string]$CredFilePath       # optional: fallback credential file path
    )

    Write-Step "Checking authentication for $ToolName..."

    # Check if the CLI exists
    if (-not (Get-Command $ToolName -ErrorAction SilentlyContinue)) {
        Write-ErrorMsg "$ToolName CLI is not installed."
        return
    }

    # If a status command exists, try it
    if ($StatusCommand) {
        $null = Invoke-Expression $StatusCommand 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Info "$ToolName is already authenticated."
            return
        }
        Write-Warn "$ToolName authentication not found."
    }

    # Optional: check for fallback credential file
    if ($CredFilePath -and (Test-Path $CredFilePath)) {
        Write-Info "Found credential file at $CredFilePath"
        Write-Info "Attempting to use existing credentials..."
        
        $null = Invoke-Expression $StatusCommand 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Info "Authentication restored from credential file."
            return
        }

        Write-Warn "Credential file exists but is invalid or expired."
    }

    # Perform login
    Write-Step "Running '$LoginCommand'..."
    Invoke-Expression $LoginCommand

    if ($LASTEXITCODE -eq 0) {
        Write-Info "$ToolName authentication completed successfully."
    } else {
        Write-ErrorMsg "$ToolName authentication failed."
    }
}

#!/usr/bin/env pwsh
Show-Banner
$ErrorActionPreference = "Stop"

Write-Info "=== Infrastructure Bootstrap Starting ==="

# Resolve script root so relative paths always work
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- Step 1: Ensure Azure, GitHub, and Terraform login ---
Write-Step "Checking Azure, GitHub, and Terraform login..."

Ensure-Login `
    -ToolName "az" `
    -LoginCommand "az login" `
    -StatusCommand "az account show"

Ensure-Login `
    -ToolName "gh" `
    -LoginCommand "gh auth login" `
    -StatusCommand "gh auth status" `
    -CredFilePath "$HOME/.config/gh/hosts.yml"

Ensure-Login `
    -ToolName "terraform" `
    -LoginCommand "terraform login" `
    -StatusCommand "" `
    -CredFilePath "$HOME/.terraform.d/credentials.tfrc.json"

# --- Step 2: Initialize Layer ---
Write-Info "`n=== Running Initialize Layer ==="
$InitPath = Join-Path $ScriptRoot "../Infrastructure/Terraform/Bootstrap"
Set-Location $InitPath

terraform init
terraform apply -auto-approve

# --- Step 3: Ecosystem Layer ---
Write-Info "`n=== Running Ecosystem Layer ==="
$EcoPath = Join-Path $ScriptRoot "../Infrastructure/Terraform/Ecosystem"
Set-Location $EcoPath

terraform init
terraform apply -auto-approve

Write-Step "`n=== Bootstrap Complete ==="
