# Dziennik: etap 3 (szablon maszyny wirtualnej jako kod)

**Daty:** 2026-10-18 – 2026-10-19

## Wykonane prace

### 3.1 Wybór sposobu budowy szablonu
- Porównanie czterech podejść: ręczna instalacja, instalacja z ISO
  z plikiem preseed, Packer, oficjalny obraz chmurowy.
- Wybór obrazu Debian 13 genericcloud (amd64, qcow2), przypiętego
  do wydania 20261017-2634 z weryfikacją SHA-512 (ADR-009).

### 3.2 Import obrazu przez API
- Analiza dokumentacji providera: typ zawartości import i parametr
  import_from pozwalają uniknąć dostępu SSH.
- Analiza wymagań uprawnień funkcji download-url i query-url-metadata.
- Osobne konto terraform-images@pve z rolą ImageDownloader
  (Datastore.AllocateTemplate, Datastore.Audit, Sys.AccessNetwork,
  Sys.Audit) przypisaną na /storage/local i /nodes/homelab (ADR-010).
- Wydzielona konfiguracja infra/terraform/images z własnym stanem
  i tokenem.

### 3.3–3.4 Zmienne i pobranie obrazu
- Pierwsze zmienne Terraform (variables.tf, terraform.tfvars).
- Pobranie obrazu przez Proxmox bezpośrednio z serwera Debiana
  (6 min 31 s), weryfikacja sumy kontrolnej po stronie Proxmox.
- Zwiększenie limitu czasu pobierania do 1800 s (zmiana w miejscu,
  bez ponownego pobrania).

### 3.5 Szablon
- Szablon tpl-debian13 (VMID 9000) z dyskiem zaimportowanym z obrazu
  na nas-vm (qcow2, 10 GB), napędem cloud-init, portem szeregowym,
  kontrolerem virtio-scsi-single i płytą q35. Utworzony w 22 s kontem
  terraform@pve; rola TerraformProv nie wymagała rozszerzenia.

### 3.6 Maszyna testowa
- Klon połączony test-debian13 (VMID 2999) w puli portal, adres
  192.168.1.200, konto ansible z kluczem publicznym przez cloud-init.
- Utworzenie w 13 s; cloud-init: nazwa hosta, adres IP, konto z sudo,
  powiększenie partycji do 9,7 GB (zajęte 848 MB).
- Ansible: ping oraz polecenie z uprawnieniami administratora.
- Usunięcie maszyny przez usunięcie pliku test-vm.tf z kodu (2 s).
- Potwierdzenie zakresu DHCP routera (.100–.199): pula portalu
  .200–.239 jest poza nim.

## Napotkane problemy

| Problem | Przyczyna | Rozwiązanie |
|---|---|---|
| Wybór obrazu arm64 zamiast amd64 | pomyłka przy odczycie pliku SHA512SUMS | pobranie właściwej linii poleceniem curl z grep |
| Plan bez zmian mimo nowego kodu | pliki utworzone w VS Code bez zapisania treści | zapisanie plików, włączenie Auto Save |
| Nieaktualny zapisany plan | plan wyliczony przed zapisaniem kodu | stała nazwa tfplan nadpisywana przy każdym planie, usuwanie po apply |
| Literówka w nazwie pliku (veriables.tf) | błąd przy tworzeniu pliku | zmiana nazwy poleceniem mv |
| Ostrzeżenie Deprecated dla proxmox_virtual_environment_download_file | zmiana nazw zasobów przed wersją 1.0 providera | użycie proxmox_download_file przed utworzeniem zasobu |
| Błąd 403 Permission check failed przy pobieraniu obrazu | brak uprawnień do pobierania z URL w roli TerraformProv | analiza wymagań, osobne konto z Sys.AccessNetwork (ADR-010) |
| Czas pobierania bliski limitowi 600 s | wolne pobieranie z serwera Debiana | zwiększenie upload_timeout do 1800 s |
| Domyślny kontroler virtio-scsi-pci w planie klonu | provider uzupełnia nieokreślone pola wartościami domyślnymi | jawne podanie scsi_hardware i machine; niezgodność wykryta podczas przeglądu planu |
| Błąd HTTP 500 parameter 'storage' not allowed for linked clones | wskazanie magazynu docelowego dla klonu połączonego | usunięcie datastore_id z bloku clone |
| Odrzucony git push | commit wykonany w przeglądarce na GitHubie (docs/brudnopis.md) | git stash, git pull --rebase, git push, git stash pop |
| Ponowne pojawienie się katalogu docs/listingi | otwarta w VS Code karta ze starą ścieżką pliku | zamknięcie karty, usunięcie katalogu |

## Decyzje
- Obraz chmurowy Debiana zamiast instalacji z ISO (ADR-009).
- Osobne konto do pobierania obrazów (ADR-010).
- Szablon i środowiska użytkowników na nas-vm, klony połączone (ADR-003).
- Agent gościa wyłączony w szablonie; instalacja przez Ansible.
- Zasada pracy: każda sesja zaczyna się od git pull.

## Pomiary (do rozdziału testów)

| Operacja | Czas |
|---|---|
| Pobranie obrazu (ok. 327 MiB) | 6 min 31 s |
| Utworzenie szablonu z obrazu | 22 s |
| Utworzenie klonu połączonego | 13 s |
| Usunięcie maszyny | 2 s |

## Otwarte kwestie
- Instalacja qemu-guest-agent przez Ansible i włączenie agenta.
- Obsługa kluczy serwerów SSH przy ponownym użyciu adresów IP
  (ssh-keygen -R); do rozwiązania w etapie 9.
- Osobny klucz SSH automatyzacji zamiast klucza administratora
  dla konta ansible; do rozwiązania w etapie 9.
- Ustawienie onboot w szablonie (dziedziczone przez klony).
