# Delete all local and remote git branches except 'main' and 'development'
# Usage: Run this script from the root of your git repository

$protectedBranches = @('main', 'development')

# Delete local branches
$localBranches = git branch | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' -and $_ -notmatch '\*' }
foreach ($branch in $localBranches) {
    if ($protectedBranches -notcontains $branch) {
        git branch -D $branch
    }
}

# Fetch all remote branches
git fetch --prune
$remoteBranches = git branch -r | ForEach-Object { $_.Trim() -replace 'origin/', '' } | Where-Object { $_ -ne '' -and $protectedBranches -notcontains $_ }
foreach ($branch in $remoteBranches) {
    git push origin --delete $branch
}

Write-Host "Deleted all local and remote branches except: $($protectedBranches -join ', ')"
