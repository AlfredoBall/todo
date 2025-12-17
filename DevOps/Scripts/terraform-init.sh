#!/usr/bin/env bash
set -euo pipefail

# Wrapper to run `terraform init` using environment variables for backend
# configuration. Useful in CI or local shells.

WORKING_DIR=${1:-DevOps/Infrastructure/Terraform}

: "${TF_RESOURCE_GROUP:?TF_RESOURCE_GROUP must be set}" 
: "${TF_STORAGE_ACCOUNT:?TF_STORAGE_ACCOUNT must be set}"
: "${TF_CONTAINER:?TF_CONTAINER must be set}"
: "${TF_KEY:?TF_KEY must be set}"
: "${TF_SUBSCRIPTION_ID:?TF_SUBSCRIPTION_ID must be set}"
: "${TF_TENANT_ID:?TF_TENANT_ID must be set}"

echo "Initializing Terraform in '$WORKING_DIR' using storage account '$TF_STORAGE_ACCOUNT' (container: $TF_CONTAINER)"

cd "$WORKING_DIR"

terraform init \
  -backend-config="resource_group_name=${TF_RESOURCE_GROUP}" \
  -backend-config="storage_account_name=${TF_STORAGE_ACCOUNT}" \
  -backend-config="container_name=${TF_CONTAINER}" \
  -backend-config="key=${TF_KEY}" \
  -backend-config="subscription_id=${TF_SUBSCRIPTION_ID}" \
  -backend-config="tenant_id=${TF_TENANT_ID}"
