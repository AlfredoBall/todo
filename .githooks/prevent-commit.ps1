#!/usr/bin/env pwsh
try {
  $branch = git rev-parse --abbrev-ref HEAD 2>$null
} catch {
  Write-Error "Unable to determine current branch."
  exit 1
}
if ($branch -eq 'main' -or $branch -eq 'master') {
  Write-Error "ERROR: Direct commits to '$branch' are disabled. Create a branch and open a PR instead."
  exit 1
}
exit 0
