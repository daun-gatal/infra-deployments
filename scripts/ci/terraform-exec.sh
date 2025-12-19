#!/usr/bin/env bash
set -euo pipefail

# -------- Defaults (backward compatible) --------
TF_ACTION="${TF_ACTION:?TF_ACTION is required}"
MODULE_NAME="${MODULE_NAME:?MODULE_NAME is required}"
OUTPUT_DIR="${OUTPUT_DIR:-/opt/terraform-outputs}"
DESTROY_ENABLED="${DESTROY_ENABLED:-false}"
IGNORE_PLAN="${IGNORE_PLAN:-false}"

echo "▶ Terraform action: ${TF_ACTION}"
echo "▶ Module: ${MODULE_NAME}"

# Generate .tfvars explicitly to avoid passing it as artifact
if [ -f .tf.env ]; then
  echo "Generating .tfvars from .tf.env..."
  envsubst < .tf.env > "${MODULE_NAME}/.tfvars"
else
  echo "⚠️ .tf.env not found!"
fi

cd "${MODULE_NAME}"

# -------- Init --------
if [ ! -f .backend.hcl ]; then
  echo "Generating .backend.hcl..."
  STATE_NAME=$(basename ${MODULE_NAME})
  cat > .backend.hcl <<EOF
address         = "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${STATE_NAME}"
lock_address    = "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${STATE_NAME}/lock"
unlock_address  = "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${STATE_NAME}/lock"
lock_method     = "POST"
unlock_method   = "DELETE"
retry_wait_min  = 5
username        = "${GITLAB_USERNAME}"
password        = "${GITLAB_TOKEN}"
EOF
fi

terraform init -backend-config=.backend.hcl

# -------- Helper function for apply outputs --------
push_outputs() {
  terraform output -json > outputs.json
  tailscale ssh root@"${TAILSCALE_SERVER}" -- "mkdir -p ${OUTPUT_DIR}/${MODULE_NAME} && cat > ${OUTPUT_DIR}/${MODULE_NAME}/outputs.json" < outputs.json
}

# -------- Execute --------
case "${TF_ACTION}" in
  apply)
    if [ "${IGNORE_PLAN}" = "true" ]; then
      echo "▶ IGNORE_PLAN=true → Running direct apply..."
      terraform apply -auto-approve -compact-warnings -var-file=.tfvars
      push_outputs
      exit 0
    fi

    echo "▶ Applying from tfplan..."
    terraform apply -auto-approve -compact-warnings tfplan
    push_outputs
    ;;

  refresh)
    terraform apply -refresh-only -auto-approve -compact-warnings -var-file=.tfvars
    ;;

  destroy)
    if [ "${DESTROY_ENABLED}" != "true" ]; then
      echo "❌ Destroy disabled! Set DESTROY_ENABLED=true to allow destroy."
      exit 1
    fi

    echo "▶ Destroy enabled. Proceeding..."
    terraform destroy -auto-approve -compact-warnings -var-file=.tfvars
    ;;

  *)
    echo "❌ Unknown TF_ACTION=${TF_ACTION}"
    exit 1
    ;;
esac