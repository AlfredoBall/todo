# PowerShell script to delete all GitHub Actions workflow runs except the latest one

# Ensure GitHub CLI is authenticated
gh auth status
if ($LASTEXITCODE -ne 0) {
    Write-Host "Please authenticate with 'gh auth login' before running this script."
    exit 1
}

$repo = gh repo view --json nameWithOwner -q .nameWithOwner
Write-Host "Deleting all workflow runs for repository (except for the last one): $repo"

# Fetch all run IDs, latest first
$runIds = gh api --paginate "repos/$repo/actions/runs" --jq ".workflow_runs[].id"
$runIds = $runIds | Where-Object { $_ -match '^[0-9]+$' }
$runIds = $runIds | Select-Object -Unique

if ($runIds.Count -le 1) {
    Write-Host "Zero or one workflow run found. Nothing to delete."
    exit 0
}

Write-Host "Found $($runIds.Count) runs. Keeping the latest: $($runIds[0])"

# Delete all except the first (latest)
foreach ($id in $runIds[1..($runIds.Count-1)]) {
    Write-Host "Deleting run ID: $id"
    gh api -X DELETE "repos/$repo/actions/runs/$id" | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Deleted run $id"
    } else {
        Write-Host "✗ Failed to delete run $id"
    }
    # Optional: Start-Sleep -Milliseconds 500
}

Write-Host "Done!"
