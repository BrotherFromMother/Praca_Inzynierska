#!/usr/bin/env bash
# Pełne wdrożenie środowiska: Terraform (obrazy, platforma) -> Ansible (site.yml).
# Wdrożenie od zera, weryfikacja zgodności z kodem oraz odbudowa po awarii.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TF_DIR="$REPO_DIR/infra/terraform"
ANSIBLE_DIR="$REPO_DIR/infra/ansible"
ENV_DIR="$HOME/.config/homelab"
SSH_KEY="${PORTAL_SSH_KEY:-$HOME/.ssh/portal_automation_ed25519}"
SSH_OPTS=(-i "$SSH_KEY" -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new)
CREATED_FILE="$(mktemp)"
trap 'rm -f "$CREATED_FILE"' EXIT

declare -A VM_IP=( [dc1]=192.168.1.40 [svc01]=192.168.1.41 )

log() { echo "==> [$(date '+%H:%M:%S')] $*"; }

# --- Terraform: plan, a apply tylko wtedy, gdy są zmiany ---
terraform_stage() {
  local name="$1" envfile="$2"
  (
    cd "$TF_DIR/$name"
    # shellcheck disable=SC1090
    source "$envfile"
    terraform init -input=false >/dev/null
    local rc=0
    terraform plan -input=false -detailed-exitcode -out=tfplan >/dev/null || rc=$?
    case "$rc" in
      0)
        log "Terraform $name: brak zmian"
        ;;
      2)
        log "Terraform $name: zmiany do wprowadzenia:"
        terraform show -no-color tfplan | grep -E "will be (created|destroyed|updated|replaced)" || true
        terraform show -no-color tfplan \
          | grep -oE "module\.[a-z0-9_]+\.proxmox_virtual_environment_vm\.this will be created" \
          | cut -d. -f2 >> "$CREATED_FILE" || true
        terraform apply -input=false tfplan
        ;;
      *)
        log "BŁĄD: plan Terraform $name zakończył się błędem"
        exit 1
        ;;
    esac
    rm -f tfplan
  )
}

# --- Oczekiwanie na maszynę: SSH, potem cloud-init (kody 0 i 2 to sukces) ---
wait_for_vm() {
  local host="$1" ip="$2"
  log "Oczekiwanie na $host ($ip)"
  for i in $(seq 1 60); do
    if ssh "${SSH_OPTS[@]}" "ansible@$ip" true >/dev/null 2>&1; then
      break
    fi
    if [ "$i" -eq 60 ]; then
      log "BŁĄD: $host nie odpowiada przez SSH"
      exit 1
    fi
    sleep 5
  done
  local rc=0
  timeout 600 ssh "${SSH_OPTS[@]}" "ansible@$ip" 'cloud-init status --wait' >/dev/null 2>&1 || rc=$?
  if [ "$rc" -ne 0 ] && [ "$rc" -ne 2 ]; then
    log "BŁĄD: cloud-init na $host zakończył się kodem $rc"
    exit 1
  fi
}

for f in proxmox-images.env proxmox.env; do
  [ -r "$ENV_DIR/$f" ] || { log "BŁĄD: brak pliku $ENV_DIR/$f"; exit 1; }
done

T0=$(date +%s)

log "Etap 1/3: infrastruktura (Terraform)"
terraform_stage images "$ENV_DIR/proxmox-images.env"
terraform_stage platform "$ENV_DIR/proxmox.env"
T1=$(date +%s)

log "Etap 2/3: dostępność maszyn"
while read -r host; do
  [ -n "$host" ] || continue
  log "Maszyna $host utworzona od nowa: usunięcie starego klucza SSH"
  ssh-keygen -R "${VM_IP[$host]}" >/dev/null 2>&1 || true
done < "$CREATED_FILE"
for host in dc1 svc01; do
  wait_for_vm "$host" "${VM_IP[$host]}"
done
T2=$(date +%s)

log "Etap 3/3: konfiguracja i usługi (Ansible)"
cd "$ANSIBLE_DIR"
ansible-playbook playbooks/site.yml
T3=$(date +%s)

echo
log "Wdrożenie zakończone"
echo "    Terraform:     $((T1 - T0)) s"
echo "    Maszyny:       $((T2 - T1)) s"
echo "    Ansible:       $((T3 - T2)) s"
echo "    Razem:         $((T3 - T0)) s"