#!/usr/bin/env bash
# Testy akceptacyjne środowiska: każda usługa sprawdzana z zewnątrz, z weryfikacją TLS.
# Użycie: verify.sh            jednorazowe sprawdzenie
#         verify.sh --wait N   powtarzaj co 10 s, aż wszystko przejdzie (najwyżej N sekund)
set -uo pipefail

SSH_KEY="${PORTAL_SSH_KEY:-$HOME/.ssh/portal_automation_ed25519}"
DC1=192.168.1.40
SVC01=192.168.1.41

check() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    printf '  [ OK ] %s\n' "$name"
    return 0
  fi
  printf '  [BŁĄD] %s\n' "$name"
  return 1
}

dns_ok()      { [ "$(dig @"$DC1" +short git.homelab.internal)" = "$SVC01" ]; }
ldaps_ok()    { echo | openssl s_client -connect "$DC1:636" -verify_return_error 2>&1 | grep -q "Verify return code: 0"; }
ca_ok()       { curl -sf https://ca.homelab.internal:9000/health | grep -q ok; }
gitea_ok()    { curl -sf https://git.homelab.internal/api/healthz | grep -q pass; }
wiki_ok()     { curl -sf -o /dev/null https://wiki.homelab.internal/login; }
zabbix_ok()   { curl -sf -H "Content-Type: application/json-rpc" \
                  -d '{"jsonrpc":"2.0","method":"apiinfo.version","params":{},"id":1}' \
                  https://zabbix.homelab.internal/api_jsonrpc.php | grep -q '"result"'; }
containers_ok() {
  local expected="step-ca traefik gitea gitea-db bookstack bookstack-db zabbix-db zabbix-server zabbix-web"
  local running
  running=$(ssh -i "$SSH_KEY" -o BatchMode=yes -o ConnectTimeout=5 "ansible@$SVC01" \
    'docker ps --filter status=running --format "{{.Names}}"')
  for c in $expected; do
    echo "$running" | grep -qx "$c" || return 1
  done
}

run_all() {
  local fail=0
  check "DNS: git.homelab.internal przez dc1"          dns_ok        || fail=1
  check "LDAPS dc1: certyfikat zweryfikowany"          ldaps_ok      || fail=1
  check "Urząd certyfikacji step-ca"                   ca_ok         || fail=1
  check "Gitea (HTTPS, healthz)"                       gitea_ok      || fail=1
  check "BookStack (HTTPS, strona logowania)"          wiki_ok       || fail=1
  check "Zabbix (HTTPS, API)"                          zabbix_ok     || fail=1
  check "Kontenery na svc01: wszystkie działają"       containers_ok || fail=1
  return "$fail"
}

if [ "${1:-}" = "--wait" ]; then
  limit="${2:-900}"
  start=$(date +%s)
  while true; do
    echo "=== $(date '+%H:%M:%S')"
    if run_all; then
      echo "Środowisko sprawne po $(( $(date +%s) - start )) s oczekiwania"
      exit 0
    fi
    if [ $(( $(date +%s) - start )) -ge "$limit" ]; then
      echo "Przekroczono limit $limit s"
      exit 1
    fi
    sleep 10
  done
else
  echo "=== $(date '+%H:%M:%S')"
  if run_all; then echo "Wszystkie testy przeszły"; else echo "Są błędy"; exit 1; fi
fi