#!/usr/bin/env bash
# Generic Terraform backend initialization script for Bash.
# Reads backend config from environment variables and runs `terraform init` with the correct -backend-config args.
#
# Required environment variables:
#   TF_RESOURCE_GROUP        # Resource group for the storage account
#   TF_STORAGE_ACCOUNT       # Storage account name (must be globally unique)
#   TF_CONTAINER             # Blob container name (e.g. tfstate)
#   TF_KEY                   # State file name/key (e.g. todo.terraform.tfstate)
#   TF_SUBSCRIPTION_ID       # Azure subscription ID (GUID)
#   TF_TENANT_ID             # Azure tenant ID (GUID)
#
# Usage:
#   export TF_RESOURCE_GROUP=<your-tfstate-resource-group>
#   export TF_STORAGE_ACCOUNT=<your-storage-account>
#   export TF_CONTAINER=tfstate
#   export TF_KEY=todo.terraform.tfstate
#   export TF_SUBSCRIPTION_ID=<your-subscription-id>
#   export TF_TENANT_ID=<your-tenant-id>
#   ./DevOps/Scripts/terraform-init.sh [working_dir]
#
# See backend.env.example for a template.

set -euo pipefail

WORKING_DIR=${1:-DevOps/Infrastructure/Terraform}

if [[ -z "${TF_RESOURCE_GROUP:-}" ]]; then echo "TF_RESOURCE_GROUP is not set"; exit 1; fi
if [[ -z "${TF_STORAGE_ACCOUNT:-}" ]]; then echo "TF_STORAGE_ACCOUNT is not set"; exit 1; fi
if [[ -z "${TF_CONTAINER:-}" ]]; then echo "TF_CONTAINER is not set"; exit 1; fi
if [[ -z "${TF_KEY:-}" ]]; then echo "TF_KEY is not set"; exit 1; fi
if [[ -z "${TF_SUBSCRIPTION_ID:-}" ]]; then echo "TF_SUBSCRIPTION_ID is not set"; exit 1; fi
if [[ -z "${TF_TENANT_ID:-}" ]]; then echo "TF_TENANT_ID is not set"; exit 1; fi

echo "Initializing Terraform in '$WORKING_DIR' using storage account '$TF_STORAGE_ACCOUNT' (container: $TF_CONTAINER)"

cd "$WORKING_DIR"

terraform init \
  -backend-config="resource_group_name=${TF_RESOURCE_GROUP}" \
  -backend-config="storage_account_name=${TF_STORAGE_ACCOUNT}" \
  -backend-config="container_name=${TF_CONTAINER}" \
  -backend-config="key=${TF_KEY}" \
  -backend-config="subscription_id=${TF_SUBSCRIPTION_ID}" \
  -backend-config="tenant_id=${TF_TENANT_ID}"
