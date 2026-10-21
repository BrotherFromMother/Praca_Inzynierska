#!/usr/bin/env bash
# Tworzy i konfiguruje środowisko użytkownika: Terraform -> cloud-init -> Ansible.
# Użycie: provision.sh <nazwa> <vmid> <adres_ip>
# Przykład: provision.sh env-002 2002 192.168.1.202
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Użycie: $0 <nazwa> <vmid> <adres_ip>" >&2
  exit 1
fi

ENV_NAME="$1"
VM_ID="$2"
IP="$3"

REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TF_DIR="$REPO_DIR/infra/terraform/environments"
ANSIBLE_DIR="$REPO_DIR/infra/ansible"
SSH_KEY="${PORTAL_SSH_KEY:-$HOME/.ssh/portal_automation_ed25519}"
SSH_USER="ansible"
SSH_OPTS=(-i "$SSH_KEY" -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new)

T0=$(date +%s)

echo "==> [1/3] Terraform: tworzenie maszyny $ENV_NAME"
cd "$TF_DIR"
terraform workspace select -or-create "$ENV_NAME"
terraform plan -out=tfplan \
  -var "env_name=$ENV_NAME" \
  -var "vm_id=$VM_ID" \
  -var "ip_address=$IP/24"
terraform apply tfplan
rm -f tfplan
T1=$(date +%s)

echo "==> [2/3] Oczekiwanie na SSH i zakończenie cloud-init"

# a) Oczekiwanie, aż maszyna przyjmie połączenie SSH.
for i in $(seq 1 60); do
  if ssh "${SSH_OPTS[@]}" "$SSH_USER@$IP" true >/dev/null 2>&1; then
    break
  fi
  if [ "$i" -eq 60 ]; then
    echo
    echo "Maszyna nie odpowiada przez SSH" >&2
    exit 1
  fi
  printf "."
  sleep 5
done
echo

# b) Oczekiwanie na zakończenie cloud-init (najwyżej 10 minut).
# Kody wyjścia: 0 - sukces, 2 - zakończony z ostrzeżeniami, inne - błąd.
RC=0
timeout 600 ssh "${SSH_OPTS[@]}" "$SSH_USER@$IP" 'cloud-init status --wait' >/dev/null 2>&1 || RC=$?
if [ "$RC" -ne 0 ] && [ "$RC" -ne 2 ]; then
  echo "cloud-init zakończył się błędem lub przekroczył czas (kod $RC)" >&2
  exit 1
fi
T2=$(date +%s)

echo "==> [3/3] Ansible: konfiguracja systemu"
cd "$ANSIBLE_DIR"
ansible-playbook -i "$IP," -u "$SSH_USER" --private-key "$SSH_KEY" playbooks/provision.yml
T3=$(date +%s)

echo
echo "==> Środowisko $ENV_NAME gotowe: $SSH_USER@$IP"
echo "    Terraform:  $((T1 - T0)) s"
echo "    cloud-init: $((T2 - T1)) s"
echo "    Ansible:    $((T3 - T2)) s"
echo "    Razem:      $((T3 - T0)) s"