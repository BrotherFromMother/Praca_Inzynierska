# Rejestr decyzji architektonicznych (ADR)

Dokument zawiera decyzje techniczne podjęte w trakcie projektu.
Każda decyzja opisuje kontekst, rozważane opcje, wybór oraz jego
konsekwencje.

## Spis decyzji

| Nr      | Decyzja                                   | Status   | Data       |
|---------|-------------------------------------------|----------|------------|
| ADR-001 | Wybór platformy wirtualizacji             | przyjęta | 2026-10-17 |
| ADR-002 | System plików dysku lokalnego hypervisora | przyjęta | 2026-10-17 |
| ADR-003 | Rozmieszczenie dysków maszyn wirtualnych  | przyjęta | 2026-10-17 |
| ADR-004 | Protokół dostępu do magazynu na Synology  | przyjęta | 2026-10-17 |

---

## ADR-001: Wybór platformy wirtualizacji

**Status:** przyjęta
**Data:** 2026-10-17

### Kontekst
Projekt wymaga platformy wirtualizacji uruchomionej bezpośrednio
na sprzęcie (bare-metal) na komputerze Lenovo MiniPC (32 GB RAM).
Platforma musi:
- udostępniać API REST, przez które autorski portal będzie tworzył
  i usuwał maszyny wirtualne,
- być obsługiwana przez narzędzia Infrastructure as Code
  (OpenTofu/Terraform, Ansible),
- działać na sprzęcie klasy konsumenckiej,
- nie generować kosztów licencyjnych w środowisku laboratoryjnym,
- umożliwiać integrację z zewnętrznym magazynem danych (NFS/iSCSI)
  oraz wykonywanie kopii zapasowych.

### Rozważane opcje
1. Proxmox VE (KVM + LXC)
2. VMware ESXi / vSphere
3. Microsoft Hyper-V (Windows Server)
4. XCP-ng (Xen) z Xen Orchestra

### Porównanie

| Kryterium            | Proxmox VE          | VMware ESXi             | Hyper-V                 | XCP-ng                  |
|----------------------|---------------------|-------------------------|-------------------------|-------------------------|
| Licencja             | open source (AGPLv3)| komercyjna, subskrypcja | wymaga licencji Windows | open source             |
| API do zapisu        | REST, tokeny API    | pełne w płatnych edycjach| PowerShell / WMI       | XAPI, API Xen Orchestra |
| OpenTofu / Terraform | provider bpg/proxmox| oficjalny, wymaga vCenter| społecznościowy        | społecznościowy         |
| Ansible              | community.proxmox   | community.vmware        | moduły Windows          | ograniczone wsparcie    |
| Kontenery systemowe  | tak (LXC)           | nie                     | nie                     | nie                     |
| Sprzęt konsumencki   | szerokie wsparcie   | ograniczona lista (HCL) | dobre                   | dobre                   |
| Kopie zapasowe       | wbudowane (vzdump)  | narzędzia zewnętrzne    | narzędzia zewnętrzne    | wbudowane w Xen Orch.   |

### Decyzja
Wybrano **Proxmox VE** (wersja 9.2).

### Uzasadnienie
- Natywne API REST z tokenami o ograniczonych uprawnieniach umożliwia
  bezpośrednią integrację z portalem bez dodatkowych komponentów
  zarządzających.
- Dojrzałe wsparcie IaC: provider bpg/proxmox dla OpenTofu oraz
  kolekcja community.proxmox dla Ansible z dynamicznym inwentarzem.
- Brak kosztów licencyjnych przy pełnej funkcjonalności.
- Obsługa maszyn wirtualnych (KVM) i kontenerów systemowych (LXC)
  w jednej platformie.
- Wbudowane mechanizmy: firewall, kopie zapasowe, obsługa NFS/iSCSI,
  uwierzytelnianie przez LDAP/Active Directory.
- Oparcie o Debian GNU/Linux zapewnia szerokie wsparcie sterowników.
- Zmiany modelu licencjonowania VMware po przejęciu przez Broadcom
  zwiększyły koszt i niepewność tej opcji.
  (TODO: dodać źródło z datą przed oddaniem pracy)

### Konsekwencje
- Brak wsparcia komercyjnego: korzystanie z repozytorium
  pve-no-subscription, przeznaczonego do zastosowań nieprodukcyjnych.
- Mniejsza popularność w dużych korporacjach niż VMware; rozwiązanie
  szeroko stosowane w małych i średnich organizacjach.
- Hypervisor jest instalowany i konfigurowany ręcznie (warstwa
  „day 0”); wyższe warstwy infrastruktury są tworzone jako kod.

---

## ADR-002: System plików dysku lokalnego hypervisora

**Status:** przyjęta
**Data:** 2026-10-17

### Kontekst
Lenovo MiniPC ma jeden dysk wewnętrzny i 32 GB RAM, które mają być
przeznaczone przede wszystkim dla maszyn wirtualnych.

### Rozważane opcje
1. ext4 + LVM-thin (domyślna opcja instalatora Proxmox VE)
2. ZFS na pojedynczym dysku

### Decyzja
Wybrano **ext4 + LVM-thin** (magazyny `local` i `local-lvm`).

### Uzasadnienie
- Przy jednym dysku ZFS nie zapewnia redundancji (brak mirrora
  lub RAID-Z), więc jego główna zaleta nie jest wykorzystana.
- ZFS rezerwuje część RAM na pamięć podręczną ARC, a RAM jest
  najbardziej ograniczonym zasobem w projekcie.
- LVM-thin obsługuje thin provisioning, snapshoty i linked clone.
- Prostsza konfiguracja i mniejszy narzut na zasoby.

### Konsekwencje
- Brak sum kontrolnych danych na poziomie systemu plików.
- Awaria dysku oznacza utratę lokalnych maszyn; ryzyko ograniczają
  codzienne kopie zapasowe na Synology (magazyn `nas-back`).

---

## ADR-003: Rozmieszczenie dysków maszyn wirtualnych

**Status:** przyjęta
**Data:** 2026-10-17

### Kontekst
Dostępne są dwa magazyny dysków VM: lokalny `local-lvm` (dysk Lenovo)
oraz `nas-vm` (NFS na Synology DS225+, 192.168.1.80).

### Rozważane opcje
1. Wszystkie maszyny na `local-lvm`
2. Wszystkie maszyny na `nas-vm`
3. Podział według roli maszyny

### Decyzja
Wybrano **podział według roli**:
- maszyny platformy (`dc1`, `svc01`) → `local-lvm`,
- środowiska tworzone przez portal → `nas-vm` (format qcow2).

### Uzasadnienie
- Usługi krytyczne (uwierzytelnianie, portal) nie mogą zależeć
  od dostępności NAS-a i wymagają najlepszej wydajności dysku.
- Środowiska użytkowników są tymczasowe i liczne: liczy się
  pojemność, a krótkotrwała niedostępność jest akceptowalna.
- Rozwiązanie wykorzystuje NAS jako współdzielony magazyn danych.

### Konsekwencje
- Awaria NAS-a zatrzymuje środowiska użytkowników, ale nie platformę.
- Wydajność dysków środowisk zależy od przepustowości sieci; zostanie
  to zmierzone w rozdziale testów (porównanie `local-lvm` i NFS).

---

## ADR-004: Protokół dostępu do magazynu danych na Synology

**Status:** przyjęta
**Data:** 2026-10-17

### Kontekst
Synology DS225+ ma udostępniać przestrzeń dyskową dla Proxmox VE:
na dyski środowisk użytkowników, obrazy ISO, szablony i kopie
zapasowe. Proxmox obsługuje dwa główne protokoły sieciowe: NFS
(dostęp plikowy) i iSCSI (dostęp blokowy).

### Rozważane opcje
1. NFS: udział plikowy, dyski VM jako pliki (qcow2/raw)
2. iSCSI: LUN widoczny w Proxmoxie jako dysk blokowy, zwykle z LVM

### Decyzja
Wybrano **NFS w wersji 4.1**: magazyny `nas-vm` (folder `pve-vm`)
oraz `nas-back` (folder `pve-backup`).
(TODO: potwierdzić faktyczną wersję w wyniku `mount | grep nfs`)

### Uzasadnienie
- Jeden udział obsługuje wiele typów zawartości: dyski VM, obrazy ISO,
  szablony, snippety cloud-init i kopie zapasowe. iSCSI z LVM
  przechowuje wyłącznie dyski.
- Format qcow2 na NFS zapewnia snapshoty i thin provisioning.
- Pliki są widoczne bezpośrednio na NAS-ie, co ułatwia diagnostykę
  i pozwala korzystać ze snapshotów Btrfs po stronie Synology.
- Prostsza konfiguracja: brak zarządzania LUN-ami, targetami
  i inicjatorami.
- Dostęp ograniczony regułą NFS do adresu hypervisora (192.168.1.30).

### Konsekwencje
- Dostęp plikowy wprowadza narzut w porównaniu z dostępem blokowym;
  wpływ na wydajność zostanie zmierzony w rozdziale testów.
- Uwierzytelnianie AUTH_SYS opiera się na adresie IP hosta, a nie
  na kryptograficznej tożsamości. W środowisku laboratoryjnym jest to
  akceptowalne; w produkcji należałoby rozważyć NFS z Kerberosem
  lub izolowaną sieć dla ruchu storage (VLAN STORAGE).
- Folder `pve-vm` ma wyłączoną sumę kontrolną danych (wydajność przy
  częstych zapisach), a `pve-backup` włączoną (integralność kopii).

---

| ADR-005 | Stacja sterująca dla narzędzi IaC         | przyjęta | 2026-10-18 |

## ADR-005: Stacja sterująca dla narzędzi IaC

**Status:** przyjęta
**Data:** 2026-10-18

### Kontekst
Narzędzia IaC i Ansible muszą być uruchamiane z maszyny mającej dostęp
do API Proxmox VE i do SSH zarządzanych hostów (węzeł sterujący,
ang. control node). Stacja robocza administratora działa pod kontrolą
systemu Windows, a Ansible nie jest wspierany na Windowsie jako węzeł
sterujący.

### Rozważane opcje
1. WSL2 (Debian) na stacji roboczej administratora
2. Dedykowana maszyna wirtualna zarządzająca na Proxmoxie
3. Kontener workera platformy samoobsługowej na svc01

### Decyzja
Na etapie budowy środowiska: **WSL2 z Debianem 13** na stacji roboczej.
Docelowo zadania automatyczne wykonuje kontener workera portalu (opcja 3).

### Uzasadnienie
- WSL2 zapewnia pełne środowisko Linux w tej samej wersji co serwery
  (Debian 13), bez zużywania zasobów hypervisora.
- Maszyna zarządzająca na Proxmoxie byłaby niedostępna przy awarii
  hypervisora, a jej utworzenie wymagałoby narzędzi, które sama ma
  uruchamiać (problem rozruchu).
- Ten sam kod IaC jest później uruchamiany w kontenerze workera,
  więc wybór stacji nie wpływa na kod.

### Konsekwencje
- Repozytorium musi znajdować się w systemie plików WSL, a nie na dysku
  Windows (wydajność, uprawnienia plików wymagane przez Ansible).
- Rozszerzenia VS Code muszą być zainstalowane po stronie WSL.
- Klucze SSH oddzielone według przeznaczenia (GitHub, serwery),
  zabezpieczone hasłem i odblokowywane przez keychain.

---
## ADR-006: Narzędzie Infrastructure as Code

**Status:** przyjęta
**Data:** 2026-10-18

### Kontekst
Infrastruktura (maszyny wirtualne, pule, reguły zapory) ma być tworzona
deklaratywnie, z kodu przechowywanego w repozytorium. Narzędzie musi
obsługiwać Proxmox VE i być szeroko stosowane w praktyce.

### Rozważane opcje
1. Terraform (HashiCorp)
2. OpenTofu (fork Terraforma, Linux Foundation)
3. Pulumi
4. Wyłącznie Ansible (bez narzędzia do zarządzania zasobami)

### Decyzja
Wybrano **Terraform** (wersja 1.16).

### Uzasadnienie
- Standard branżowy w obszarze IaC: największa społeczność,
  dokumentacja i liczba providerów.
- Podejście deklaratywne z planem zmian (terraform plan) i stanem
  pozwala wykrywać różnice między kodem a rzeczywistością.
- Dojrzały provider dla Proxmox VE (ADR-007).
- Narzędzie wiersza poleceń jest bezpłatne. Licencja BSL 1.1 (od 2023 r.)
  dopuszcza użycie wewnętrzne w organizacji, w tym w wewnętrznej
  platformie samoobsługowej; ogranicza jedynie oferowanie produktów
  konkurencyjnych wobec usług HashiCorp.
- Pulumi wymaga opisywania infrastruktury w języku ogólnego
  przeznaczenia, co zwiększa złożoność; Ansible nie przechowuje stanu
  i słabiej nadaje się do zarządzania cyklem życia zasobów.

### Konsekwencje
- Kod jest zgodny z OpenTofu, co umożliwia migrację bez zmian kodu
  w przypadku zmian licencyjnych.
- Podział ról: Terraform tworzy i usuwa zasoby wirtualne, Ansible
  konfiguruje systemy wewnątrz maszyn.
- Terraform nie jest oprogramowaniem open source w rozumieniu OSI;
  w pracy określany jako oprogramowanie bezpłatne z dostępnym kodem
  źródłowym.

---

## ADR-007: Provider Terraform dla Proxmox VE

**Status:** przyjęta
**Data:** 2026-10-18

### Kontekst
Terraform komunikuje się z Proxmox VE przez providera. Proxmox nie ma
oficjalnego providera; dostępne są dwa popularne providery
społecznościowe.

### Rozważane opcje
1. bpg/proxmox
2. Telmate/proxmox

### Decyzja
Wybrano **bpg/proxmox** (wersja 0.117).

### Uzasadnienie
- Aktywny rozwój i wsparcie aktualnych wersji Proxmox VE.
- Szerszy zakres obsługiwanych zasobów: maszyny, kontenery, pule,
  pliki, cloud-init, reguły zapory.
- Konfiguracja przez zmienne środowiskowe, co ułatwia oddzielenie
  sekretów od kodu.

### Konsekwencje
- Większość operacji odbywa się wyłącznie przez API Proxmox VE z użyciem
  tokenu. Według dokumentacji providera połączenie SSH z węzłem jest
  wymagane tylko dla wybranych operacji: wgrywania snippetów cloud-init,
  wgrywania niektórych typów plików, importu dysków z pliku lokalnego
  (source_file.path) oraz konfiguracji idmap kontenerów LXC.
  Sposób tworzenia szablonu maszyny zostanie dobrany w etapie 3 tak, aby
  w miarę możliwości uniknąć konieczności dostępu SSH.
- Provider jest w wersji 0.x i zmienia nazwy zasobów przed wydaniem 1.0
  (np. proxmox_virtual_environment_version → proxmox_version). Ryzyko
  ograniczono przez przypięcie zakresu wersji w versions.tf oraz plik
  blokady .terraform.lock.hcl.
- Provider jest podpisany kluczem autorów (provider społecznościowy),
  a nie kluczem HashiCorp; podpis jest weryfikowany przy terraform init.

---

## ADR-008: Przechowywanie sekretów i stanu Terraform

**Status:** przyjęta
**Data:** 2026-10-18

### Kontekst
Terraform potrzebuje tokenu API Proxmoxa oraz przechowuje stan
infrastruktury, który może zawierać wrażliwe dane. Repozytorium jest
przechowywane w serwisie GitHub.

### Decyzja
- Token API: dedykowane konto terraform@pve z rolą TerraformProv
  o ograniczonym zestawie uprawnień, token z separacją uprawnień.
- Sekret tokenu przechowywany w menedżerze haseł oraz w pliku
  ~/.config/homelab/proxmox.env (uprawnienia 600), poza repozytorium;
  przekazywany do Terraforma przez zmienne środowiskowe.
- Stan Terraform: na etapie budowy lokalnie, wykluczony z repozytorium
  (.gitignore); docelowo w bazie PostgreSQL na svc01 (backend pg).

### Uzasadnienie
- Kod w repozytorium nie zawiera żadnego sekretu.
- Kompromitacja tokenu nie daje pełnej kontroli nad hypervisorem.
- Stan w bazie danych umożliwi współbieżny dostęp z blokadą,
  potrzebny platformie samoobsługowej, oraz objęcie go kopiami
  zapasowymi.

### Konsekwencje
- Znane ograniczenie: rola przypisana na ścieżce „/”; zakres zostanie
  zawężony do puli zasobów w etapie 9.
- Znane ograniczenie: wyłączona weryfikacja certyfikatu TLS API
  (certyfikat samopodpisany); do usunięcia po wdrożeniu zaufanego
  certyfikatu.
- Znane ograniczenie: do etapu 6 stan istnieje tylko na stacji roboczej.
- Lista uprawnień roli będzie rozszerzana w kolejnych etapach,
  a każda zmiana dokumentowana.

---

## Szablon nowej decyzji

## ADR-00X: Tytuł decyzji

**Status:** proponowana / przyjęta / zastąpiona przez ADR-00Y
**Data:** RRRR-MM-DD

### Kontekst
Jaki problem rozwiązujemy i jakie są ograniczenia.

### Rozważane opcje
1. ...
2. ...

### Decyzja
Co wybrano.

### Uzasadnienie
Dlaczego właśnie to.

### Konsekwencje
Co z tego wynika, także negatywnie.
