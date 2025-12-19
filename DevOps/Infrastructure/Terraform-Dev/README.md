# Development App Registrations - Terraform Configuration

This directory contains Terraform configuration for creating **development-only** Azure AD app registrations.

## Purpose

- Creates 3 app registrations: `todo-api-dev`, `todo-react-dev`, `todo-angular-dev`
- Configured with `localhost` redirect URIs for local development
- State stored locally (not in Azure Storage)
- Completely separate from production infrastructure

## Quick Start

Run the setup script from the repository root:

**Windows**:
```powershell
.\DevOps\Scripts\setup-dev-environment.ps1
```

**Linux/macOS**:
```bash
./DevOps/Scripts/setup-dev-environment.sh
```

## Manual Usage

If you prefer to run Terraform manually:

1. **Copy terraform.tfvars.example**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars and add your tenant ID
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Apply configuration**:
   ```bash
   terraform apply
   ```

4. **View outputs**:
   ```bash
   terraform output
   ```

## Outputs

- `api_client_id` - API app registration client ID
- `react_client_id` - React app registration client ID
- `angular_client_id` - Angular app registration client ID
- `tenant_id` - Azure AD tenant ID
- `api_scope` - Full API scope URI
- `api_audience` - API audience URI

## Important Notes

⚠️ **Local State Only**
- State files are stored locally in this directory
- Do not commit `terraform.tfstate` or `terraform.tfvars`
- Each developer has their own isolated app registrations

⚠️ **Development Only**
- These app registrations use `localhost` redirect URIs
- Only for local development - not for production
- Production uses separate Terraform config in `../Terraform/`

## Cleanup

To delete the development app registrations:

```bash
terraform destroy
```

This will remove all 3 app registrations from Azure AD.
