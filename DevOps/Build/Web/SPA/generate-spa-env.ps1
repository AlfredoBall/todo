param(
    [string]$InputJson = "{}",
    [string]$OutputPath = "./env.js"
)

Write-Host "[generate-spa-env.ps1] Generating env.js..."

# Parse JSON
try {
    $vars = $InputJson | ConvertFrom-Json -ErrorAction Stop
} catch {
    Write-Error "Invalid JSON in InputJson: $_"
    exit 1
}

# Convert JSON back to pretty JS object literal
$jsObject = ($vars | ConvertTo-Json -Depth 10)

# Wrap in window.__ENV__
$final = "window.__ENV__ = $jsObject;"

# Write file
try {
    Set-Content -Path $OutputPath -Value $final
    Write-Host "[generate-spa-env.ps1] Done."
} catch {
    Write-Error "Failed to write env.js: $_"
    exit 1
}
