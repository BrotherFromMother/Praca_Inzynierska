# Dziennik: etap 4 (mechanizm tworzenia i konfiguracji maszyn)

**Daty:** 2026-10-20 – 2026-10-21

## Wykonane prace
- Moduł Terraform portal-vm z walidacją parametrów (zakres VMID,
  rdzenie, pamięć) i wartościami wyjściowymi (ADR-013).
- Konfiguracja environments wywołująca moduł, z osobnym workspace
  dla każdej maszyny.
- Osobny klucz SSH automatyzacji bez hasła (ADR-014).
- Rola Ansible base: aktualizacja systemu, pakiety bazowe (w tym
  qemu-guest-agent), strefa czasowa, warunkowy restart.
- Rola Ansible docker: Docker Engine i wtyczka Compose z oficjalnego
  repozytorium, konto ansible w grupie docker.
- Playbook provision.yml, plik requirements.yml z przypiętą wersją
  kolekcji community.general, konfiguracja SSH w ansible.cfg
  (accept-new, pipelining).
- Skrypty provision.sh i deprovision.sh z pomiarem czasu faz.
- Wyłączenie aktualizacji pakietów w cloud-init (upgrade = false).
- Decyzja o zmianie zakresu projektu (ADR-011) oraz o nazewnictwie
  i certyfikatach (ADR-012).

## Napotkane problemy

| Problem | Przyczyna | Rozwiązanie |
|---|---|---|
| VS Code: role 'base' was not found | rozszerzenie uruchamia ansible-lint z katalogu głównego repozytorium, bez ansible.cfg | zmienna ANSIBLE_ROLES_PATH w ~/.bashrc |
| ansible-lint: brak znaku nowej linii, spacje na końcu linii | ustawienia edytora | opcje Insert Final Newline, Trim Trailing Whitespace i Trim Final Newlines w VS Code |
| ansible-lint nie znajdował community.general.timezone | Ansible i ansible-lint w osobnych środowiskach pipx; kolekcja tylko w środowisku Ansible | requirements.yml i instalacja do ~/.ansible/collections z opcją --force |
| Skrypt zgłaszał brak odpowiedzi SSH mimo działającej maszyny | cloud-init zwracał kod 2 (zakończenie z ostrzeżeniem DEPRECATED dla formatu generowanego przez Proxmox) | akceptacja kodów 0 i 2 |
| Oczekiwanie dłuższe niż zakładane | cloud-init status --wait bez limitu czasu; błędne oszacowanie czasu pętli | timeout 600, osobne oczekiwanie na SSH i na cloud-init, wskaźnik postępu |
| Podwójna aktualizacja systemu | aktualizacja pakietów w cloud-init (domyślnie w Proxmox) i w roli base | upgrade = false w module |
| Ostrzeżenie remote_tmp przy pierwszym uruchomieniu | Ansible tworzy katalog tymczasowy roota przy pierwszym użyciu | nieszkodliwe, bez zmian |

## Pomiary

| Operacja | Czas |
|---|---|
| Klonowanie maszyny z szablonu | 4 s |
| Rola base (pierwsze wykonanie, świeży obraz) | 25 s |
| Role base i docker (pierwsze wykonanie) | 4 min 11 s – 7 min 11 s (zależnie od łącza) |
| Pełne utworzenie maszyny (env-003): Terraform / cloud-init / Ansible | 4 s / 22 s / 431 s, razem 457 s |
| Usunięcie maszyny z workspace | 1 s |
| Ponowne wykonanie ról | changed=0 |

## Wnioski
- Instalacja Dockera dominuje czas konfiguracji maszyny; wypiekanie
  obrazu (np. Packer) to kierunek optymalizacji.
- Każda operacja oczekiwania w automatyzacji wymaga limitu czasu
  i jawnej interpretacji kodów wyjścia.
- Idempotentność Terraform i Ansible pozwala wznawiać przerwany proces
  przez ponowne uruchomienie tego samego polecenia.

## Otwarte kwestie
- Uogólnienie modułu na maszyny usługowe (pełny klon, local-lvm,
  inny zakres VMID) przed etapem 5.
- Włączenie agenta gościa Proxmox w maszynach.
- Los konfiguracji environments i puli portal po zmianie zakresu.
