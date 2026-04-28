#!/usr/bin/env bash
set -euo pipefail

export ARM_SUBSCRIPTION_ID="${INPUT_ARM_SUBSCRIPTION_ID:-}"
export ARM_TENANT_ID="${INPUT_ARM_TENANT_ID:-}"
export ARM_CLIENT_ID="${INPUT_ARM_CLIENT_ID:-}"
export ARM_CLIENT_SECRET="${INPUT_ARM_CLIENT_SECRET:-}"

STATE_KEY="${INPUT_STATE_KEY:-}"
TF_STAGE="${INPUT_TF_STAGE:-}"
TF_BACKEND_RESOURCE_GROUP_NAME="${INPUT_TF_BACKEND_RESOURCE_GROUP_NAME:-}"
TF_BACKEND_STORAGE_ACCOUNT_NAME="${INPUT_TF_BACKEND_STORAGE_ACCOUNT_NAME:-}"
TF_BACKEND_CONTAINER_NAME="${INPUT_TF_BACKEND_CONTAINER_NAME:-}"

if [ -z "${ARM_SUBSCRIPTION_ID}" ] || [ -z "${ARM_TENANT_ID}" ] || [ -z "${ARM_CLIENT_ID}" ] || [ -z "${ARM_CLIENT_SECRET}" ]; then
  echo "Missing required Azure ARM credential inputs."
  exit 1
fi

if [ -z "${STATE_KEY}" ]; then
  echo "Missing required input: state_key"
  exit 1
fi

if [ -z "${TF_STAGE}" ]; then
  echo "Missing required input: tf_stage"
  exit 1
fi

if [ -z "${TF_BACKEND_RESOURCE_GROUP_NAME}" ] || [ -z "${TF_BACKEND_STORAGE_ACCOUNT_NAME}" ] || [ -z "${TF_BACKEND_CONTAINER_NAME}" ]; then
  echo "Missing one or more required backend inputs: tf_backend_resource_group_name, tf_backend_storage_account_name, tf_backend_container_name"
  exit 1
fi

cd /github/workspace

export TF_VAR_state_key="${STATE_KEY}"

if [ "${TF_STAGE}" != "stage1" ]; then
  echo "Unsupported tf_stage '${TF_STAGE}' for this step. Only 'stage1' is implemented right now."
  exit 1
fi

if [ ! -d "${TF_STAGE}" ]; then
  echo "Stage directory '${TF_STAGE}' not found in repository root."
  exit 1
fi

if [ ! -f "${TF_STAGE}/main.tf" ]; then
  echo "Expected Terraform file '${TF_STAGE}/main.tf' was not found."
  exit 1
fi

PLAN_FILE="${TF_STAGE}.tfplan"

terraform -chdir="${TF_STAGE}" init \
  -backend-config="resource_group_name=${TF_BACKEND_RESOURCE_GROUP_NAME}" \
  -backend-config="storage_account_name=${TF_BACKEND_STORAGE_ACCOUNT_NAME}" \
  -backend-config="container_name=${TF_BACKEND_CONTAINER_NAME}" \
  -backend-config="key=${STATE_KEY}.tfstate" \
  -backend-config="use_azuread_auth=true"
terraform -chdir="${TF_STAGE}" plan -out="${PLAN_FILE}"
terraform -chdir="${TF_STAGE}" apply -auto-approve "${PLAN_FILE}"
