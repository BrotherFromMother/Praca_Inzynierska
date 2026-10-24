# Dziennik: etap 6 (svc01, urząd certyfikacji, Traefik, Gitea)

**Daty:** 2026-10-23 – 2026-10-24

## Wykonane prace
- Moduł Terraform: opcjonalny dysk danych (blok dynamic z walidacją).
- svc01 (VMID 101, 192.168.1.41): pełny klon, 4 rdzenie, 6 GB RAM,
  dysk danych 40 GB (ADR-018).
- Role Ansible: data_disk (ext4, /var/lib/docker), step_ca, ca_trust
  (z handlerem), traefik (z handlerem), samba_tls, gitea.
- step-ca 0.30.2: urząd dwupoziomowy z ACME; provisioner infra
  dla certyfikatów rocznych (ADR-019). Odcisk certyfikatu głównego
  (SHA-256): e2992d189062047e664f038e0bbf0459e23ad5f0d041143e75935232f21ed15c
- Traefik: jedyny punkt wejścia, HTTPS z certyfikatami 24-godzinnymi
  (ADR-020); usługa testowa whoami.
- dc1: certyfikat LDAPS ze step-ca na podstawie wniosku CSR, SAN
  z nazwą, nazwą krótką i adresem IP.
- Gitea 28.2.0 z PostgreSQL 17.11 w sieci wewnętrznej, logowanie przez
  LDAPS, RBAC z grup AD (ADR-021).
- Hasło konta usługowego LDAP przeniesione do group_vars/all;
  atrybut mail użytkowników ustawiany przez ldbmodify.
- Przypinanie wersji obrazów z weryfikacją identyfikatora (ADR-022).

## Napotkane problemy

| Problem | Przyczyna | Rozwiązanie |
|---|---|---|
| Blocks of type "dynamic" are not expected here | blok dynamic poza zasobem | wklejenie bloku wewnątrz zasobu |
| Module not installed | nowe wywołanie modułu bez terraform init | terraform init po każdym nowym bloku module |
| Missing Proxmox VE API Endpoint | nowy terminal bez wczytanych zmiennych | source ~/.config/homelab/proxmox.env |
| Playbook svc.yml not found | plik niezapisany lub w złym katalogu | utworzenie pliku w playbooks/ |
| Hasło urzędu certyfikacji w rozmowie | wynik polecenia z hasłem wklejony razem z innymi | nowe hasło w sejfie, usunięcie i ponowne utworzenie urzędu (nowy certyfikat główny) |
| Pozorny brak odpowiedzi z dc1 | curl -s bez znaku nowej linii; błędna hipoteza o starym certyfikacie | curl -sS z echo; weryfikacja wyniku roli (ok zamiast changed) |
| Odcisk w Windows niezgodny z odciskiem z Ansible | Windows pokazuje SHA-1, Ansible SHA-256 | porównanie z openssl x509 -fingerprint -sha1 |
| ansible-lint: no-handler | zadanie z when: …changed | handler Uruchom ponownie Traefika |
| Certyfikat LDAPS Samby odrzucany przez Go | automatycznie wygenerowany certyfikat bez SAN | certyfikat ze step-ca przez CSR, provisioner infra |
| Hasło LDAP niewidoczne dla svc01 | group_vars ograniczone do grupy | przeniesienie do group_vars/all |
| YAML: Missing closing quote w when | ciąg ": " w niecytowanym tekście | uproszczenie warunku |
| yaml[indentation] | when na złym poziomie wcięcia | właściwości zadania na poziomie 2 spacji |
| Adresy e-mail nie ustawione, playbook bez błędu | literówka ssamba_dc_users zamaskowana wartością domyślną [] roli | poprawka nazwy; weryfikacja wyniku zamiast samego braku błędów |
| Jan nie mógł się zalogować | wpisywane hasło różniło się od hasła w sejfie | test hasłem z pliku (ldapsearch -y), poprawa wpisu w menedżerze haseł |
| Ostrzeżenie: hasło w wierszu poleceń | argumenty samba-tool widoczne na liście procesów | pakiet python3-setproctitle |
| Resolve-DnsName nie rozwiązuje git.homelab.internal | dwie karty sieciowe, priorytet DNS sieci przewodowej | zapytanie z -Server; reguła NRPT jako rozwiązanie |

## Pomiary

| Operacja | Wynik |
|---|---|
| Pełny klon svc01 z dyskiem danych | 1 min 33 s |
| Wydanie certyfikatu przez ACME (Traefik) | kilka sekund od startu |
| Ważność certyfikatów usług webowych | 24 h |
| Ważność certyfikatu kontrolera domeny | 1 rok |
| Ponowne wykonanie playbooków svc.yml, dc.yml, dc-tls.yml | changed=0 |

## Wnioski
- Rozpoznanie przed implementacją (certyfikat Samby bez SAN) zmieniło
  koncepcję rozwiązania przed napisaniem kodu.
- Wymiana certyfikatu głównego wymaga aktualizacji wszystkich klientów;
  automatyczne rozsyłanie i kopia kluczy urzędu są kluczowe.
- Wartości domyślne ról mogą maskować błędy konfiguracji; poprawność
  należy weryfikować wynikiem, a nie brakiem błędów.

## Otwarte kwestie
- Kopia zapasowa wolumenu step-ca (etap 9) – krytyczna.
- Gniazdo Dockera w Traefiku (docker socket proxy jako rozszerzenie).
- Aktualizacja źródła uwierzytelniania Gitei (update-ldap).
- Wyłączenie usługi testowej whoami po zakończeniu testów.
- Reguła NRPT na stacji administratora (opcjonalnie).
- Kolejność wdrożenia od zera: dc.yml → svc.yml → dc-tls.yml (etap 10).
