# Procedura odtwarzania danych usług

Dokument dla administratora. Opisuje odtworzenie danych z kopii restic
na Synology (udział homelab-backup). Konfiguracja usług odtwarzana jest
z repozytorium Git (Terraform, Ansible); niniejsza procedura dotyczy
danych.

## 1. Informacje wstępne

| Element | Wartość |
|---|---|
| Repozytoria restic | /mnt/homelab-backup/restic/<host> (dc1, svc01) |
| Plik z hasłem | /etc/restic/password (źródło: sejf Ansible, group_vars/all) |
| Kopie svc01 | osobne dla usług: tagi step-ca, gitea, bookstack, zabbix |
| Kopie dc1 | archiwum samba-tool, tag samba |
| Harmonogram | codziennie ok. 1:30; retencja 7 dziennych, 4 tygodniowe |

Przed odtworzeniem na danym hoście (jako root):

```bash
export RESTIC_REPOSITORY=/mnt/homelab-backup/restic/$(hostname)
export RESTIC_PASSWORD_FILE=/etc/restic/password
export RESTIC_CACHE_DIR=/var/cache/restic
mountpoint /mnt/homelab-backup     # musi być punktem montowania
restic snapshots                   # lista dostępnych kopii
```

## 2. Odtworzenie jednej usługi na svc01

Dotyczy: step-ca, gitea, bookstack, zabbix. Pozostałe usługi działają
bez przerwy.

| Usługa | Katalog projektu | Wolumeny |
|---|---|---|
| step-ca | /opt/stack/step-ca | step-ca_step-ca-data |
| gitea | /opt/stack/gitea | gitea_gitea-data, gitea_gitea-db |
| bookstack | /opt/stack/bookstack | bookstack_bookstack-config, bookstack_bookstack-db |
| zabbix | /opt/stack/zabbix | zabbix_zabbix-db |

Przykład dla BookStacka (najnowsza kopia):

```bash
USLUGA=bookstack
KATALOG=/opt/stack/bookstack
WOLUMENY="bookstack_bookstack-config bookstack_bookstack-db"

docker compose --project-directory "$KATALOG" stop
for v in $WOLUMENY; do
  mv /var/lib/docker/volumes/$v/_data /var/lib/docker/volumes/$v/_data.przed-odtworzeniem
done
restic restore latest --tag "$USLUGA" --host svc01 --target /
docker compose --project-directory "$KATALOG" start
```

Odtworzenie kopii innej niż najnowsza: zamiast `latest` podać
identyfikator z `restic snapshots --tag "$USLUGA"`.

Weryfikacja: usługa odpowiada przez https i zawiera oczekiwane dane.
Po potwierdzeniu usunąć katalogi `_data.przed-odtworzeniem`.

Wycofanie (gdy odtworzenie się nie powiodło): zatrzymać usługę,
usunąć odtworzone `_data`, przywrócić nazwy katalogów
`_data.przed-odtworzeniem` na `_data`, uruchomić usługę.

**Uwaga (step-ca):** odtworzenie innego niż bieżący stanu urzędu nie
zmienia certyfikatu głównego, o ile kopia pochodzi z tego samego
urzędu. Utrata wolumenu step-ca bez kopii wymusza wymianę certyfikatu
głównego na wszystkich klientach.

## 3. Odtworzenie katalogu Samby AD na dc1

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
narzędzia (smb.conf z katalogu restore) i uruchomić samba-ad-dc.
Weryfikacja: rekordy SRV w DNS, kinit administratora, lista
użytkowników.

**Uwaga:** przy więcej niż jednym kontrolerze domeny przywrócenie bazy
z kopii grozi uszkodzeniem replikacji (USN rollback); procedura dotyczy
środowiska z jednym kontrolerem.

## 4. Odtworzenie całego svc01 (awaria maszyny)

1. Terraform: utworzenie maszyny svc01 (konfiguracja platform).
2. Ansible: playbooks/svc.yml do roli docker włącznie
   (base, data_disk, docker) oraz playbooks/backup.yml (montowanie
   NFS, restic).
3. Utworzenie wolumenów i odtworzenie danych wszystkich usług
   (sekcja 2, bez kroku zatrzymania), w tym w pierwszej kolejności
   step-ca.
4. Ansible: pełny playbooks/svc.yml (role usług znajdą istniejące
   dane), playbooks/monitoring.yml, playbooks/zabbix-config.yml.
5. Weryfikacja wszystkich usług; pomiar RTO i RPO.

Procedura podlega testowi awarii w etapie 11.

## 5. Alternatywa: kopia maszyny w Proxmox VE

Kopie vzdump (codziennie 2:00, magazyn nas-backup) pozwalają
przywrócić całą maszynę z poziomu Proxmox VE (Backup → Restore).
Przywraca to wszystkie usługi maszyny do stanu z chwili kopii.
