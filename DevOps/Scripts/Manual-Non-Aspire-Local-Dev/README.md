# Manual/Non-Aspire Local Dev Scripts

This folder contains scripts for setting up the development environment and initializing Terraform **outside** of the Aspire/AppHost workflow. These scripts are only needed if you want to:

- Run Terraform and generate environment files manually (not via Aspire/AppHost)
- Bootstrap the environment for local development without using Aspire orchestration
- Support legacy or non-standard workflows

> **Note:** The PowerShell and Bash scripts (`setup-dev-environment.ps1` and `setup-dev-environment.sh`) are functionally equivalent and provide the same setup steps for different platforms.

## When to Use These Scripts
- **Use these scripts** if you are not using Aspire/AppHost to orchestrate your local development environment.
- **Do NOT use these scripts** if you are running the project via Aspire/AppHost, as all Terraform provisioning and .env file generation is handled automatically.

## Scripts
- `setup-dev-environment.ps1` / `setup-dev-environment.sh`: Initializes Terraform, creates Azure AD app registrations, and generates .env files for API, React, and Angular apps.
- `terraform-init.ps1` / `terraform-init.sh`: Initializes the Terraform backend for state storage.

## Important
- All internal paths in these scripts are relative to this subfolder. If you move these scripts, update the paths accordingly.
- For most developers, **Aspire/AppHost is the recommended and automated way to set up and run the project**.

---

**If you are using Aspire/AppHost, you do NOT need to run these scripts manually.**
