# Dziennik: etap 2 (stacja robocza i repozytorium IaC)

**Data:** 2026-10-18

## Wykonane prace (część 1: punkty 2.1–2.3)
- Stacja sterująca: WSL2 z Debianem 13.7 (ADR-005).
- VS Code połączony z WSL, rozszerzenia Ansible, HashiCorp Terraform
  i YAML zainstalowane po stronie WSL.
- Git: adres autora noreply GitHub, gałąź domyślna main.
- Klucz SSH Ed25519 dla GitHuba, weryfikacja odcisku serwera GitHub.
- Repozytorium sklonowane do ~/projekty/Praca_Inzynierska,
  uporządkowana struktura (docs/, infra/), plik .gitignore.
- Osobny klucz SSH Ed25519 dla serwerów, logowanie do Proxmoxa
  bez hasła, keychain do przechowywania odblokowanych kluczy.

## Napotkane problemy

| Problem | Przyczyna | Rozwiązanie |
|---|---|---|
| Rozszerzenia VS Code wyłączone | tryb ograniczony (Restricted Mode) dla niezaufanego katalogu domowego | otwarcie folderu repozytorium i nadanie mu zaufania |
| Rozszerzenia działały tylko w Windowsie | przy pracy w WSL rozszerzenia muszą być zainstalowane po stronie zdalnej | instalacja „Install in WSL: Debian” |
| Plik listingów bez formatowania na GitHubie | brak rozszerzenia .md w nazwie pliku | zmiana nazwy na plik Markdown |
| Listingi rozproszone w wielu plikach | brak przyjętej konwencji na początku projektu | scalenie w docs/listingi.md |

## Decyzje
- Klucze SSH rozdzielone według przeznaczenia (GitHub, serwery),
  zabezpieczone hasłem.
- TODO: widoczność repozytorium (prywatne/publiczne).

## Otwarte kwestie
- Wybór narzędzia IaC: Terraform czy OpenTofu (przed punktem 2.4).
