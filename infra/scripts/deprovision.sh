#!/usr/bin/env bash
# Usuwa środowisko użytkownika i jego stan Terraform.
# Użycie: deprovision.sh <nazwa>
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Użycie: $0 <nazwa>" >&2
  exit 1
fi

ENV_NAME="$1"
REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TF_DIR="$REPO_DIR/infra/terraform/environments"

T0=$(date +%s)
cd "$TF_DIR"
terraform workspace select "$ENV_NAME"

# Wartości zmiennych odczytywane ze stanu środowiska.
VM_ID=$(terraform output -raw vm_id)
IP=$(terraform output -raw ip)

echo "==> Usuwanie środowiska $ENV_NAME (VMID $VM_ID, $IP)"
terraform destroy -auto-approve \
  -var "env_name=$ENV_NAME" \
  -var "vm_id=$VM_ID" \
  -var "ip_address=$IP/24"

terraform workspace select default
terraform workspace delete "$ENV_NAME"
ssh-keygen -R "$IP" >/dev/null 2>&1 || true
T1=$(date +%s)

echo "==> Środowisko $ENV_NAME usunięte w $((T1 - T0)) s"
