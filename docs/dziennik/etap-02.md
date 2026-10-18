# Dziennik: etap 2 (stacja robocza i repozytorium IaC)

**Data:** 2026-10-18

## Wykonane prace

### Część 1: stacja robocza (2.1–2.3)
- Stacja sterująca: WSL2 z Debianem 13.7 (ADR-005).
- VS Code połączony z WSL, rozszerzenia Ansible, HashiCorp Terraform
  i YAML zainstalowane po stronie WSL.
- Git: adres autora noreply GitHub, gałąź domyślna main.
- Klucz SSH Ed25519 dla GitHuba, weryfikacja odcisku serwera GitHub.
- Repozytorium sklonowane do ~/projekty/Praca_Inzynierska,
  uporządkowana struktura (docs/, infra/), plik .gitignore.
- Osobny klucz SSH Ed25519 dla serwerów, logowanie do Proxmoxa
  bez hasła, keychain do przechowywania odblokowanych kluczy.

### Część 2: narzędzia i konto automatyzacji (2.4–2.6)
- Terraform 1.16.6 z repozytorium HashiCorp (ADR-006).
- Ansible 2.21.5 i ansible-lint 26.10.1 przez pipx, z bibliotekami
  proxmoxer i requests.
- Rola TerraformProv z ograniczonym zestawem uprawnień, użytkownik
  terraform@pve i token iac z separacją uprawnień.
- Sekret tokenu w menedżerze haseł i w ~/.config/homelab/proxmox.env
  (uprawnienia 600), poza repozytorium (ADR-008).
- Weryfikacja tokenu zapytaniem do API (curl).

### Część 3: pierwszy kod IaC (2.7–2.8)
- Konfiguracja Terraform w infra/terraform/platform: provider
  bpg/proxmox 0.117.0 (ADR-007), źródła danych (wersja, węzły),
  pula zasobów portal.
- Zastosowanie zapisanego planu, weryfikacja idempotentności,
  wartości wyjściowe w formacie JSON.
- Konfiguracja Ansible w infra/ansible: ansible.cfg, inwentarz z grupą
  hypervisors, playbook weryfikacyjny zgodny z profilem production
  ansible-lint.

## Napotkane problemy

| Problem | Przyczyna | Rozwiązanie |
|---|---|---|
| Rozszerzenia VS Code wyłączone | tryb ograniczony (Restricted Mode) dla niezaufanego katalogu domowego | otwarcie folderu repozytorium i nadanie mu zaufania |
| Rozszerzenia działały tylko w Windowsie | przy pracy w WSL rozszerzenia muszą być zainstalowane po stronie zdalnej | instalacja „Install in WSL: Debian” |
| Plik listingów bez formatowania na GitHubie | brak rozszerzenia .md w nazwie pliku | zmiana nazwy na plik Markdown |
| Listingi rozproszone w wielu plikach | brak przyjętej konwencji na początku projektu | scalenie w docs/listingi.md |
| Commit opisany jako zawierający ADR-y bez zmian w adr.md | brak kontroli listy zmian przed commitem | osobny commit z ADR-ami; kontrola git status przed każdym commitem |
| Wiersz tabeli ADR wklejony poza tabelą | ręczne wklejanie w niewłaściwe miejsce pliku | przeniesienie wierszy poleceniem sed |
| Błąd „event not found” w poleceniu grep | znak ! w podwójnym cudzysłowie oznacza w bashu odwołanie do historii | użycie pojedynczego cudzysłowu |
| Ostrzeżenie Deprecated dla proxmox_virtual_environment_version | zmiana nazw zasobów w providerze przed wersją 1.0 | użycie nowej nazwy proxmox_version |
| Puste pliki .tf | polecenie cat > czyści plik przed odczytem treści; treść nie została wklejona | odtworzenie plików; tworzenie dłuższych plików w edytorze |
| Błąd niespójnego pliku blokady (hashicorp/proxmox) | pusty versions.tf, brak mapowania nazwy lokalnej na bpg/proxmox | odtworzenie versions.tf, terraform init -upgrade |
| Rozszerzenie Ansible w VS Code nie znajdowało programów | proces VS Code uruchomiony przed dodaniem ~/.local/bin do ścieżki | ponowne uruchomienie WSL i VS Code |
| Katalog .ansible w repozytorium | pamięć podręczna tworzona przez rozszerzenie Ansible i ansible-lint | wykluczenie w .gitignore |

## Decyzje
- Klucze SSH rozdzielone według przeznaczenia (GitHub, serwery),
  zabezpieczone hasłem.
- Terraform zamiast OpenTofu (ADR-006), provider bpg/proxmox (ADR-007).
- Sekrety poza repozytorium, stan Terraform lokalnie do etapu 6
  (ADR-008).
- TODO: widoczność repozytorium (prywatne/publiczne).

## Ustalenia z dokumentacji
- Provider bpg/proxmox wymaga SSH do węzła dla wybranych operacji
  (snippety cloud-init, import dysków z pliku lokalnego, idmap LXC).
  Do rozstrzygnięcia w etapie 3 przy tworzeniu szablonu maszyny.

## Otwarte kwestie
- Rola TerraformProv przypisana na ścieżce „/”; do zawężenia w etapie 9.
- Wyłączona weryfikacja certyfikatu TLS API Proxmoxa; do usunięcia
  po wdrożeniu zaufanego certyfikatu.
- Stan Terraform tylko lokalnie w WSL; przeniesienie do PostgreSQL
  w etapie 6.
- Test pełnego cyklu życia puli (terraform destroy i ponowne apply)
  do udokumentowania listingiem.