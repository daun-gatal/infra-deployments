#!/usr/bin/env bash
set -euo pipefail

# -------- Defaults (backward compatible) --------
TF_ACTION="${TF_ACTION:-apply}"
MODULE_NAME="${MODULE_NAME:?MODULE_NAME is required}"
OUTPUT_DIR="${OUTPUT_DIR:-/opt/terraform-outputs}"

echo "▶ Terraform action: ${TF_ACTION}"
echo "▶ Module: ${MODULE_NAME}"

cd "${MODULE_NAME}"

# -------- Init --------
terraform init -backend-config=.backend.hcl

# -------- Execute --------
case "${TF_ACTION}" in
  apply)
    if [ ! -f tfplan ]; then
      echo "❌ tfplan not found. Apply must be plan-driven."
      exit 1
    fi

    terraform apply -auto-approve -compact-warnings tfplan

    terraform output -json > outputs.json
    tailscale ssh root@"${TAILSCALE_SERVER}" -- "mkdir -p ${OUTPUT_DIR}/${MODULE_NAME} && cat > ${OUTPUT_DIR}/${MODULE_NAME}/outputs.json" < outputs.json
    ;;

  refresh)
    terraform apply -refresh-only -auto-approve -compact-warnings 
    ;;

  destroy)
    terraform destroy -auto-approve -compact-warnings
    ;;

  *)
    echo "❌ Unknown TF_ACTION=${TF_ACTION}"
    exit 1
    ;;
esac
