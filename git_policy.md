# Git Branching & Commit Policy

Policy: never commit directly to `main`.

This repository uses a branch-per-feature workflow. Do not push commits directly to `main`; create a feature branch and open a pull request for review.

Local enforcement (optional but recommended)

- We provide local Git hooks in `.githooks/` to help prevent accidental commits to `main` or `master`.
- To enable these hooks for your local clone, run:

```bash
git config core.hooksPath .githooks
```

- On Windows PowerShell, ensure execution policy allows running the hook script or use the POSIX hook if you have a Unix shell.

Example workflow

```powershell
# create a feature branch
git checkout -b feature/terraform-azure

# stage and commit
git add -A
git commit -m "Add Terraform backend and resource group"

# push and create PR
git push -u origin feature/terraform-azure
```

Repository admins: Consider adding branch protection rules in your Git hosting provider (GitHub/GitLab/Azure DevOps) to block direct pushes and require pull requests and reviews.

Notes
- Git hooks are local (not enforced on CI) — set server-side protection in your Git host for guaranteed enforcement.
- The provided hooks are minimal and intended to prevent accidents; adapt as needed for your team.
