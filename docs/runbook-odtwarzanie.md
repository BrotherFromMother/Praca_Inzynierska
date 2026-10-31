# Procedura odtwarzania

Dokument dla administratora. Konfiguracja odtwarzana jest z repozytorium
Git (Terraform, Ansible), dane z kopii restic na Synology (udział
homelab-backup) lub kopii vzdump (magazyn nas-backup).

| Sekcja | Zakres | Stan weryfikacji |
|---|---|---|
| 2 | jedna usługa na svc01 | przetestowana (2026-10-25, 2026-10-27) |
| 3 | katalog Samby AD na dc1 | **nieprzetestowana** |
| 4 | cały svc01 z kodu i restic | przetestowana (2026-10-31, RTO 11 min 18 s) |
| 5 | cały svc01 z vzdump | przetestowana (2026-10-31, RTO ok. 1 min 7 s) |
| 6 | stacja robocza administratora | sekrety zweryfikowane odtworzeniem (2026-10-31) |
| 7 | weryfikacja po odtworzeniu | infra/scripts/verify.sh |

## 1. Informacje wstępne

| Element | Wartość |
|---|---|
| Repozytoria restic | /mnt/homelab-backup/restic/<host> (dc1, svc01) |
| Plik z hasłem | /etc/restic/password (źródło: sejf Ansible, menedżer haseł) |
| Kopie svc01 | osobne dla usług: tagi step-ca, gitea, bookstack, zabbix |
| Kopie dc1 | archiwum samba-tool, tag samba |
| Kopie maszyn | vzdump w magazynie nas-backup |

Przed pracą z restic na danym hoście (jako root):

```bash
export RESTIC_REPOSITORY=/mnt/homelab-backup/restic/$(hostname)
export RESTIC_PASSWORD_FILE=/etc/restic/password
export RESTIC_CACHE_DIR=/var/cache/restic
mountpoint /mnt/homelab-backup     # musi być punktem montowania
restic snapshots                   # lista dostępnych kopii
```

**Przed odtwarzaniem wstrzymać kopie automatyczne**, aby nie zapisały
stanu uszkodzonego jako najnowszego:
`systemctl disable --now homelab-backup.timer`
(rola backup włączy je ponownie przy najbliższym wdrożeniu).

## 2. Odtworzenie jednej usługi na svc01

| Usługa | Katalog projektu | Wolumeny |
|---|---|---|
| step-ca | /opt/stack/step-ca | step-ca_step-ca-data |
| gitea | /opt/stack/gitea | gitea_gitea-data, gitea_gitea-db |
| bookstack | /opt/stack/bookstack | bookstack_bookstack-config, bookstack_bookstack-db |
| zabbix | /opt/stack/zabbix | zabbix_zabbix-db |

```bash
odtworz() {
  local katalog="$1" kopia="$2"
  shift 2
  docker compose --project-directory "$katalog" stop
  for v in "$@"; do
    rm -rf /var/lib/docker/volumes/$v/_data.przed-odtworzeniem
    mv /var/lib/docker/volumes/$v/_data /var/lib/docker/volumes/$v/_data.przed-odtworzeniem
  done
  restic restore "$kopia" --target /
  docker compose --project-directory "$katalog" start
}

odtworz /opt/stack/bookstack <id-kopii> bookstack_bookstack-config bookstack_bookstack-db
```

Identyfikator kopii z `restic snapshots --tag <usługa>`. **Jeśli
najnowsza kopia mogła powstać po uszkodzeniu danych, wskazać
identyfikator ostatniej dobrej kopii zamiast latest** (INC-01).

Weryfikacja: verify.sh i sprawdzenie danych w usłudze; następnie
usunięcie katalogów `_data.przed-odtworzeniem`.

Wycofanie: zatrzymać usługę, usunąć odtworzone `_data`, przywrócić
nazwy `_data.przed-odtworzeniem` na `_data`, uruchomić usługę.

## 3. Odtworzenie katalogu Samby AD na dc1 (niezweryfikowane)

```bash
systemctl stop samba-ad-dc
restic restore latest --tag samba --host dc1 --target /tmp/odtworzenie
ARCHIWUM=$(ls /tmp/odtworzenie/var/backups/homelab/samba-backup-*.tar.bz2)
mv /var/lib/samba /var/lib/samba.przed-odtworzeniem
mkdir -p /var/lib/samba
samba-tool domain backup restore --backup-file="$ARCHIWUM" \
  --newservername=dc1 --targetdir=/var/lib/samba/restore
```

Następnie wskazać katalogi odtworzonej bazy zgodnie z komunikatem
narzędzia i uruchomić samba-ad-dc. Weryfikacja: rekordy SRV w DNS,
kinit administratora, lista użytkowników, verify.sh.

Przy więcej niż jednym kontrolerze domeny przywrócenie bazy z kopii
grozi uszkodzeniem replikacji (USN rollback).

## 4. Odtworzenie całego svc01 z kodu i kopii usług (scenariusz A)

Na stacji administratora:

```bash
cd ~/projekty/Praca_Inzynierska
./infra/scripts/deploy.sh
./infra/scripts/verify.sh --wait 600
```

deploy.sh tworzy brakującą maszynę (Terraform), usuwa jej stary klucz
z known_hosts, czeka na cloud-init i wykonuje site.yml. Rola
backup_restore przywraca dane usług przed ich uruchomieniem (wolumeny
nie istnieją, kopie są). Odcisk certyfikatu głównego w wyniku musi być
niezmieniony.

Wymagany dostęp do internetu (repozytoria Debiana, Docker Hub).
Zmierzony RTO: 11 min 18 s.

## 5. Przywrócenie svc01 z kopii vzdump (scenariusz B)

```bash
ssh homelab 'qm stop 101; qm destroy 101'      # jeśli maszyna istnieje
ssh homelab 'pvesm list nas-backup | grep vzdump-qemu-101'
ssh homelab 'qmrestore nas-backup:backup/<archiwum>.vma.zst 101 --storage local-lvm && qm start 101'
ssh-keygen -R 192.168.1.41                     # maszyna ma klucz z chwili kopii
./infra/scripts/verify.sh --wait 600
./infra/scripts/deploy.sh                      # zgodność z aktualnym kodem
```

Dane z chwili wykonania kopii vzdump; spójność jak po nagłym
wyłączeniu. Zmierzony RTO: ok. 1 min 7 s.

## 6. Odtworzenie stacji administratora

Wszystko poza sekretami jest w repozytorium GitHub
(BrotherFromMother/Praca_Inzynierska). Sekrety w menedżerze haseł
(folder projektu), krytyczne także w kopercie awaryjnej.

1. WSL2 z Debianem; pakiety i narzędzia zgodnie z etapem 2
   (Terraform 1.16.x, Ansible przez pipx, ansible-lint, dig, openssl).
2. Odtworzenie kluczy z menedżera haseł:
   `~/.ssh/github_ed25519`, `~/.ssh/homelab_ed25519`,
   `~/.ssh/portal_automation_ed25519` (chmod 600; klucze publiczne:
   `ssh-keygen -y -f <plik> > <plik>.pub`) oraz ~/.ssh/config.
3. Odtworzenie `~/.config/homelab/ansible-vault-pass` oraz plików
   proxmox.env i proxmox-images.env (lub nowe tokeny w panelu Proxmoxa).
4. Klon repozytorium, `ansible-galaxy collection install -r
   infra/ansible/requirements.yml`.
5. Zaufanie do certyfikatu głównego (infra/ansible/files/pki/root_ca.crt)
   w WSL i Windows; reguła NRPT `.homelab.internal` → 192.168.1.40.
6. Weryfikacja: `./infra/scripts/verify.sh`, następnie
   `./infra/scripts/deploy.sh` (oczekiwany brak zmian).

Bez stacji i menedżera haseł: panel Proxmoxa (root, hasło, TOTP lub
kod zapasowy 2FA) pozwala odzyskać dostęp do maszyn.

## 7. Weryfikacja po każdym odtworzeniu

`./infra/scripts/verify.sh`: DNS, LDAPS, step-ca, Gitea, BookStack,
Zabbix, dziewięć kontenerów na svc01. Logowanie kontami AD sprawdzić
ręcznie w Gitei, BookStacku i Zabbixie.
