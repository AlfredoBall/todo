# Delete Azure Resource Groups and App Registrations
# Usage: Run this script in a PowerShell terminal with Azure CLI installed and logged in.

# Resource groups to delete
$resourceGroups = @(
    "todo-rg-production",
    "todo-rg-development"
)

# App registration display names to delete
$appRegistrations = @(
    "To Do API - Production",
    "To Do API - Development",
    "To Do Frontend App - Production",
    "To Do Frontend App - Development"
)

# Delete resource groups
foreach ($rg in $resourceGroups) {
    Write-Host "Deleting resource group: $rg"
    az group delete --name $rg --yes --no-wait
}

# Delete app registrations
foreach ($appName in $appRegistrations) {
    $app = az ad app list --display-name "$appName" | ConvertFrom-Json | Select-Object -First 1
    if ($app -and $app.appId) {
        Write-Host "Deleting app registration: $appName ($($app.appId))"
        az ad app delete --id $app.appId
    } else {
        Write-Host "App registration not found: $appName"
    }
}
