#!/usr/bin/env bash
set -euo pipefail

# -------- Defaults (backward compatible) --------
TF_ACTION="${TF_ACTION:?TF_ACTION is required}"
MODULE_NAME="${MODULE_NAME:?MODULE_NAME is required}"
OUTPUT_DIR="${OUTPUT_DIR:-/opt/terraform-outputs}"

echo "▶ Terraform action: ${TF_ACTION}"
echo "▶ Module: ${MODULE_NAME}"

cd "${MODULE_NAME}"

# -------- Init --------
terraform init -backend-config=.backend.hcl

# -------- Helper function for apply outputs --------
push_outputs() {
  terraform output -json > outputs.json
  tailscale ssh root@"${TAILSCALE_SERVER}" -- "mkdir -p ${OUTPUT_DIR}/${MODULE_NAME} && cat > ${OUTPUT_DIR}/${MODULE_NAME}/outputs.json" < outputs.json
}

# -------- Execute --------
case "${TF_ACTION}" in
  apply)
    if [ ! -f tfplan ]; then
      echo "❌ tfplan not found. Apply must be plan-driven. Use 'apply-direct' for direct apply."
      exit 1
    fi
    echo "▶ Applying from tfplan..."
    terraform apply -auto-approve -compact-warnings tfplan
    push_outputs
    ;;

  apply-direct)
    echo "▶ Applying directly..."
    terraform apply -auto-approve -compact-warnings -var-file=.tfvars
    push_outputs
    ;;

  refresh)
    terraform apply -refresh-only -auto-approve -compact-warnings -var-file=.tfvars
    ;;

  destroy)
    terraform destroy -auto-approve -compact-warnings -var-file=.tfvars
    ;;

  *)
    echo "❌ Unknown TF_ACTION=${TF_ACTION}"
    exit 1
    ;;
esac