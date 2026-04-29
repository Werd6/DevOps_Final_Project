#!/usr/bin/env bash
set -euo pipefail

export ARM_SUBSCRIPTION_ID="${INPUT_ARM_SUBSCRIPTION_ID:-}"
export ARM_TENANT_ID="${INPUT_ARM_TENANT_ID:-}"
export ARM_CLIENT_ID="${INPUT_ARM_CLIENT_ID:-}"
export ARM_CLIENT_SECRET="${INPUT_ARM_CLIENT_SECRET:-}"

STATE_KEY="${INPUT_STATE_KEY:-}"
TF_STAGE="${INPUT_TF_STAGE:-}"
DJANGO_SECRET_KEY_PROD="${INPUT_DJANGO_SECRET_KEY_PROD:-}"

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

cd /github/workspace

if [ ! -d "${TF_STAGE}" ]; then
  echo "Stage directory '${TF_STAGE}' not found in repository root."
  exit 1
fi

if [ ! -f "${TF_STAGE}/main.tf" ]; then
  echo "Expected Terraform file '${TF_STAGE}/main.tf' was not found."
  exit 1
fi

PLAN_FILE="${TF_STAGE}.tfplan"

if [ "${TF_STAGE}" = "stage1" ]; then
  terraform -chdir="${TF_STAGE}" init \
    -backend-config="key=${STATE_KEY}.tfstate" \
    -backend-config="use_azuread_auth=true"
  terraform -chdir="${TF_STAGE}" plan -out="${PLAN_FILE}"
  terraform -chdir="${TF_STAGE}" apply -auto-approve "${PLAN_FILE}"
elif [ "${TF_STAGE}" = "stage2" ]; then
  if [ -z "${DJANGO_SECRET_KEY_PROD}" ]; then
    echo "Missing required input for stage2: django_secret_key_prod"
    exit 1
  fi

  terraform -chdir="${TF_STAGE}" init \
    -backend-config="key=${STATE_KEY}.tfstate" \
    -backend-config="use_azuread_auth=true"
  terraform -chdir="${TF_STAGE}" apply -auto-approve \
    -var="django_secret_key_prod=${DJANGO_SECRET_KEY_PROD}" \
    -var="arm_client_id=${ARM_CLIENT_ID}" \
    -var="arm_client_secret=${ARM_CLIENT_SECRET}"
elif [ "${TF_STAGE}" = "stage3" ]; then
  terraform -chdir="${TF_STAGE}" init \
    -backend-config="key=${STATE_KEY}.tfstate" \
    -backend-config="use_azuread_auth=true"
  terraform -chdir="${TF_STAGE}" plan -out="${PLAN_FILE}"
  terraform -chdir="${TF_STAGE}" apply -auto-approve "${PLAN_FILE}"
else
  echo "Unsupported tf_stage '${TF_STAGE}'. Supported values: stage1, stage2, stage3"
  exit 1
fi
