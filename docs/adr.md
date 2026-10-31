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
| ADR-005 | Stacja sterująca dla narzędzi IaC         | przyjęta | 2026-10-18 |
| ADR-006 | Narzędzie Infrastructure as Code          | przyjęta | 2026-10-18 |
| ADR-007 | Provider Terraform dla Proxmox VE         | przyjęta | 2026-10-18 |
| ADR-008 | Przechowywanie sekretów i stanu Terraform | przyjęta | 2026-10-18 |
| ADR-009 | Sposób budowy szablonu maszyny wirtualnej | przyjęta | 2026-10-18 |
| ADR-010 | Uprawnienia do pobierania obrazów dysków  | przyjęta | 2026-10-18 |
| ADR-011 | Zakres projektu: usługi w kontenerach    | przyjęta | 2026-10-21 |
| ADR-012 | Nazewnictwo domen i certyfikaty TLS       | przyjęta | 2026-10-21 |
| ADR-013 | Moduł Terraform i osobny stan maszyn      | przyjęta | 2026-10-21 |
| ADR-014 | Klucz SSH automatyzacji                   | przyjęta | 2026-10-21 |
| ADR-015 | Kontroler domeny: Samba AD w VM           | przyjęta | 2026-10-22 |
| ADR-016 | Sekrety Ansible: Ansible Vault            | przyjęta | 2026-10-22 |
| ADR-017 | Struktura katalogu i integracja LDAPS     | przyjęta | 2026-10-22 |
| ADR-018 | Host usług svc01 z dyskiem danych        | przyjęta | 2026-10-24 |
| ADR-019 | Wewnętrzny urząd certyfikacji step-ca     | przyjęta | 2026-10-24 |
| ADR-020 | Reverse proxy Traefik                     | przyjęta | 2026-10-24 |
| ADR-021 | Gitea z izolowaną bazą i integracją z AD  | przyjęta | 2026-10-24 |
| ADR-022 | Przypinanie i weryfikacja wersji obrazów  | przyjęta | 2026-10-24 |
| ADR-023 | BookStack: obraz LinuxServer.io i role   | przyjęta | 2026-10-24 |
| ADR-024 | Monitoring Zabbix 7.0 LTS                 | przyjęta | 2026-10-25 |
| ADR-025 | Przypinanie obrazów przez skrót           | przyjęta | 2026-10-25 |
| ADR-026 | Zabbix: konfiguracja przez API, LDAP      | przyjęta | 2026-10-25 |
| ADR-027 | Strategia kopii zapasowych danych usług   | przyjęta | 2026-10-25 |
| ADR-028 | Wdrożenie środowiska jednym poleceniem   | przyjęta | 2026-10-27 |
| ADR-029 | Przywracanie danych usług przy odbudowie | przyjęta | 2026-10-27 |
| ADR-030 | Testy akceptacyjne, metodyka RTO i RPO   | przyjęta | 2026-10-31 |
| ADR-031 | Klucze SSH i sekrety administratora      | przyjęta | 2026-10-31 |

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

## ADR-009: Sposób budowy szablonu maszyny wirtualnej

**Status:** przyjęta
**Data:** 2026-10-18

### Kontekst
Wszystkie maszyny wirtualne projektu (dc1, svc01, środowiska
użytkowników) mają być klonowane z jednego szablonu z systemem
Debian 13. Szablon musi powstawać powtarzalnie, z kodu, i współpracować
z cloud-init oraz Ansible.

### Rozważane opcje
1. Ręczna instalacja z ISO i konwersja na szablon
2. Instalacja nienadzorowana z ISO (plik preseed)
3. Budowa obrazu narzędziem Packer
4. Oficjalny obraz chmurowy Debiana (genericcloud, qcow2)

### Decyzja
Wybrano **oficjalny obraz chmurowy Debian 13 w wariancie genericcloud**,
pobierany i przekształcany w szablon przez Terraform. Wersja obrazu
przypięta do konkretnego wydania z datą 20261017-2634,
z weryfikacją sumy SHA-512.

### Uzasadnienie
- Obraz jest publikowany i utrzymywany przez projekt Debian.
- Zawiera wbudowany cloud-init, wymagany do konfiguracji dostępu
  przy pierwszym uruchomieniu maszyny.
- Nie wymaga instalacji systemu: przygotowanie szablonu sprowadza się
  do pobrania pliku, a maszyny uruchamiają się w kilkanaście sekund.
- Nie wymaga dodatkowych narzędzi poza Terraformem.
- Wariant genericcloud zawiera wyłącznie sterowniki dla maszyn
  wirtualnych, dzięki czemu jest mniejszy od wariantu generic.
- Przypięcie wydania z datą zamiast „latest” zapewnia powtarzalność:
  ten sam kod zawsze tworzy ten sam szablon.

### Konsekwencje
- Ograniczona kontrola nad zawartością obrazu; konfiguracja systemu
  realizowana przez cloud-init i Ansible.
- Aktualizacja szablonu do nowszego wydania wymaga świadomej zmiany
  wersji i sumy kontrolnej w kodzie.
- Packer pozostaje kierunkiem rozwoju dla szablonów z preinstalowanym
  oprogramowaniem.

  ---

## ADR-010: Uprawnienia do pobierania obrazów dysków

**Status:** przyjęta
**Data:** 2026-10-18

### Kontekst
Obraz chmurowy Debiana (ADR-009) jest pobierany przez Proxmox
bezpośrednio z serwera Debiana, przez API (download-url), bez dostępu
SSH. Próba pobrania kontem terraform@pve zakończyła się błędem 403
(Permission check failed). Funkcja pobierania wymaga uprawnienia
Datastore.AllocateTemplate na magazynie oraz Sys.Modify na całym
klastrze albo Sys.AccessNetwork na węźle. Pobieranie z dowolnego adresu
URL daje pośredni dostęp do sieci hypervisora, co stwarza ryzyko ataku
typu SSRF (Server-Side Request Forgery).

### Rozważane opcje
1. Rozszerzenie roli TerraformProv o Sys.AccessNetwork
2. Ręczne pobieranie obrazów kontem root, odwołanie z kodu do pliku
3. Osobne konto i token wyłącznie do pobierania obrazów

### Decyzja
Wybrano **opcję 3**: konto terraform-images@pve z rolą ImageDownloader
(Datastore.AllocateTemplate, Datastore.Audit, Sys.AccessNetwork,
Sys.Audit), przypisaną wyłącznie na ścieżkach /storage/local
i /nodes/homelab. Pobieranie obrazów wydzielono do osobnej konfiguracji
Terraform (infra/terraform/images) z własnym stanem i własnym tokenem.

### Uzasadnienie
- Konto terraform@pve, docelowo używane przez platformę samoobsługową,
  nie może zlecać hypervisorowi pobierania z dowolnych adresów URL,
  co eliminuje wektor ataku SSRF z poziomu aplikacji.
- Uprawnienie Sys.AccessNetwork zostało wprowadzone w Proxmox VE
  specjalnie dla automatyzacji pobierania obrazów zgodnie z zasadą
  najmniejszych uprawnień; jest znacznie węższe niż Sys.Modify.
- Rola konta do obrazów ma zakres ograniczony do jednego magazynu
  i jednego węzła.
- Pobieranie obrazów jest operacją rzadką (aktualizacja szablonu),
  wykonywaną ręcznie przez administratora.

### Konsekwencje
- Dwie konfiguracje Terraform z osobnymi stanami; konfiguracja platform
  odwołuje się do obrazu przez jego identyfikator w magazynie
  (local:import/debian-13-genericcloud-amd64-20261017-2634.qcow2).
- Dwa tokeny API i dwa pliki zmiennych środowiskowych do utrzymania.
- Przed pracą w danym katalogu należy wczytać właściwy plik
  zmiennych środowiskowych.
- Pobranie obrazu trwało ok. 6,5 minuty; limit czasu pobierania
  (upload_timeout) zwiększono z 600 do 1800 sekund.

---



## ADR-011: Zakres projektu: środowisko usług w kontenerach

**Status:** przyjęta
**Data:** 2026-10-21

### Kontekst
Pierwotny zakres zakładał autorską platformę samoobsługową (aplikację
webową) do automatycznego tworzenia środowisk użytkowników. Po
zakończeniu etapów 1–4 oceniono, że przy terminie złożenia pracy
w grudniu 2026 r. oraz konieczności nauki programowania aplikacji
webowych w Pythonie od podstaw, realizacja platformy stanowi największe
ryzyko projektu. Zarejestrowany temat pracy („Projekt i implementacja
środowiska korporacyjnego opartego na konteneryzacji usług”) nie
wymaga platformy samoobsługowej; dotyczy usług korporacyjnych
uruchamianych w kontenerach.

### Rozważane opcje
1. Pełna platforma samoobsługowa (wariant A)
2. Uproszczona platforma samoobsługowa
3. Środowisko usług korporacyjnych w kontenerach z pełną automatyzacją
   wdrożenia i odtwarzania (wariant B)

### Decyzja
Wybrano **opcję 3**: środowisko usług korporacyjnych (Samba AD, Traefik,
urząd certyfikacji step-ca, Gitea, BookStack, Zabbix) uruchamianych
w kontenerach Docker, tworzone i konfigurowane w całości jako kod,
z testem odtwarzania po awarii.

### Uzasadnienie
- Bezpośrednia zgodność z zarejestrowanym tematem i słowami kluczowymi
  (środowisko korporacyjne, konteneryzacja, Docker, Linux, Git).
- Eliminacja największego ryzyka harmonogramu.
- Wykorzystanie doświadczenia autora z usługami Zabbix, Samba AD,
  BookStack i reverse proxy.
- Wkład własny realizowany przez projekt architektury, automatyzację
  wdrożenia od zera, integrację usług z katalogiem LDAP oraz mierzalną
  ewaluację odporności na awarię (RTO, RPO).

### Konsekwencje
- Moduł Terraform, role Ansible base i docker oraz skrypty z etapu 4
  są wykorzystywane do tworzenia maszyn usługowych (dc1, svc01) zamiast
  środowisk użytkowników.
- Pula zasobów portal i konfiguracja environments z workspace
  pozostają jako element badawczy, opisany w pracy, lecz nie są
  częścią docelowego środowiska.
- ADR-003: zapis dotyczący środowisk użytkowników na magazynie nas-vm
  traci zastosowanie; maszyny usługowe pozostają na local-lvm.
- Platforma samoobsługowa zostaje wskazana jako kierunek rozwoju.

---

## ADR-012: Nazewnictwo domen i certyfikaty TLS

**Status:** przyjęta
**Data:** 2026-10-21

### Kontekst
Usługi środowiska wymagają nazw DNS i certyfikatów TLS. Domena Active
Directory po utworzeniu jest praktycznie niezmienialna. Nie przewidziano
zakupu publicznej domeny.

### Rozważane opcje (nazwa domeny AD)
1. homelab.local
2. homelab.lan
3. ad.homelab.internal

### Rozważane opcje (certyfikaty)
1. Zakupiona domena i Let's Encrypt (DNS-01)
2. DuckDNS i Let's Encrypt (DNS-01)
3. deSEC (dedyn.io) i Let's Encrypt (DNS-01)
4. Certyfikaty samopodpisane dla każdej usługi
5. Własny urząd certyfikacji (step-ca) z protokołem ACME

### Decyzja
- Domena AD: **ad.homelab.internal**, nazwa NetBIOS **HOMELAB**.
- Nazwy usług w strefie **homelab.internal** obsługiwanej przez dc1
  (np. git.homelab.internal).
- Certyfikaty z **własnego urzędu certyfikacji step-ca**, wystawiane
  automatycznie protokołem ACME, z Traefikiem jako klientem.
- Plan zapasowy: DuckDNS i Let's Encrypt.

### Uzasadnienie
- Końcówka .local jest zarezerwowana dla mDNS i powoduje konflikty
  rozwiązywania nazw w domenie; .lan nie jest formalnie zarezerwowana.
  Końcówkę .internal ICANN zarezerwowała w 2024 r. do użytku w sieciach
  prywatnych.
- Przedrostek ad. oddziela domenę AD od pozostałej przestrzeni nazw.
- Własny urząd certyfikacji odpowiada praktyce stosowanej w sieciach
  firmowych dla usług wewnętrznych i nie zależy od usług zewnętrznych.
- Protokół ACME zapewnia automatyczne wystawianie i odnawianie
  certyfikatów, tak jak przy Let's Encrypt.
- DuckDNS pozwala na tylko jeden rekord TXT jednocześnie i narzuca
  nazwę w obcej domenie; rejestracja nowych nazw w dedyn.io (deSEC)
  była w październiku 2026 r. wstrzymana; certyfikaty samopodpisane
  nie zapewniają automatyzacji.

### Konsekwencje
- Certyfikat główny urzędu musi zostać zaimportowany na stacjach
  roboczych (ręcznie) i maszynach środowiska (przez Ansible).
- Klucz prywatny urzędu certyfikacji wymaga szczególnej ochrony
  i uwzględnienia w kopiach zapasowych.
- Możliwe wystawienie zaufanego certyfikatu dla panelu Proxmox VE
  i usunięcie wyłączonej weryfikacji TLS (ADR-008).

---

## ADR-013: Moduł Terraform i osobny stan dla każdej maszyny

**Status:** przyjęta
**Data:** 2026-10-21

### Kontekst
Maszyny wirtualne tworzone z szablonu różnią się wyłącznie kilkoma
parametrami (nazwa, VMID, adres IP, zasoby). Powielanie kodu dla każdej
maszyny prowadzi do błędów i rozbieżności konfiguracji. Przechowywanie
wielu niezależnych maszyn we wspólnym stanie Terraform powoduje
blokowanie się operacji i utrudnia usuwanie pojedynczych maszyn.

### Rozważane opcje
1. Osobny plik .tf dla każdej maszyny, wspólny stan
2. Moduł Terraform i jedna konfiguracja z wieloma wywołaniami
   (for_each), wspólny stan
3. Moduł Terraform i osobny stan dla każdej maszyny (workspace)

### Decyzja
Wybrano **opcję 3**: moduł infra/terraform/modules/portal-vm
z walidacją parametrów wejściowych, wywoływany z konfiguracji
infra/terraform/environments, z osobnym workspace dla każdej maszyny.

### Uzasadnienie
- Jedna definicja maszyny dla wszystkich środowisk: zmiana w module
  obejmuje każdą nową maszynę.
- Walidacja zmiennych (zakres VMID, liczba rdzeni, ilość pamięci)
  odrzuca błędne dane przed jakąkolwiek zmianą w infrastrukturze.
- Osobny stan umożliwia niezależne tworzenie i usuwanie maszyn
  oraz równoległe operacje.

### Konsekwencje
- Usuwanie maszyny wymaga odczytu wartości zmiennych z jej stanu
  (skrypt deprovision.sh).
- Po zmianie zakresu (ADR-011) moduł wymaga uogólnienia na maszyny
  usługowe: pełny klon na local-lvm i inny zakres VMID.

---

## ADR-014: Klucz SSH automatyzacji

**Status:** przyjęta
**Data:** 2026-10-21

### Kontekst
Maszyny tworzone automatycznie są konfigurowane przez Ansible
z użyciem konta ansible, tworzonego przez cloud-init. Do tej pory
konto otrzymywało klucz SSH administratora, który daje również dostęp
do hypervisora.

### Decyzja
- Osobny klucz Ed25519 (portal_automation_ed25519) wyłącznie dla
  automatyzacji, przekazywany do maszyn przez cloud-init.
- Klucz bez hasła, ponieważ jest używany bez udziału człowieka.
- Akceptacja kluczy nowych serwerów (StrictHostKeyChecking=accept-new)
  w konfiguracji Ansible i skryptach; usuwanie wpisu z known_hosts
  przy usuwaniu maszyny.

### Uzasadnienie
- Kompromitacja klucza automatyzacji nie daje dostępu do hypervisora
  ani do kont administratora.
- Działania automatyzacji są odróżnialne od działań administratora.
- Opcja accept-new automatyzuje przyjęcie klucza nowej maszyny,
  zachowując ochronę przed zmianą klucza znanego serwera.

### Konsekwencje
- Klucz bez hasła wymaga ochrony przez uprawnienia pliku (600)
  i przechowywanie poza repozytorium.
- Ponowne użycie adresu IP wymaga usunięcia starego wpisu
  z known_hosts (realizowane przez deprovision.sh).

---

## ADR-015: Kontroler domeny: Samba AD w maszynie wirtualnej

**Status:** przyjęta
**Data:** 2026-10-22

### Kontekst
Środowisko wymaga centralnego katalogu kont (Active Directory). Temat
pracy dotyczy konteneryzacji usług, co nasuwa pytanie, czy kontroler
domeny również powinien działać w kontenerze. Rozważano także
zastosowanie Windows Server, dominującego w dużych organizacjach.

### Rozważane opcje
1. Samba AD w kontenerze Docker na svc01
2. Samba AD w osobnej maszynie wirtualnej z Debianem
3. Windows Server (dwa kontrolery domeny)

### Decyzja
Wybrano **opcję 2**: Samba AD w osobnej maszynie wirtualnej dc1
(Debian 13, pełny klon na local-lvm, autostart).

### Uzasadnienie
- Kontroler domeny wymaga stałej tożsamości (nazwa, adres, czas),
  wielu portów (DNS, Kerberos, LDAP, SMB, RPC), rozszerzonych atrybutów
  systemu plików dla SYSVOL oraz izolacji od usług aplikacyjnych;
  cechy te kolidują z modelem kontenerów. Dokumentacja Samby nie
  zaleca uruchamiania kontrolera domeny w kontenerze.
- Odtwarzanie kontrolera domeny przez wymianę kontenera grozi
  uszkodzeniem replikacji (USN rollback).
- Samba AD wykorzystuje ten sam szablon, role Ansible i system
  operacyjny co pozostała infrastruktura, nie generuje kosztów
  licencyjnych i działa również na architekturze ARM (możliwy drugi
  kontroler na Raspberry Pi 5).
- Windows Server dominuje w dużych organizacjach (integracja
  z Microsoft 365, ekosystem, wsparcie producenta), jednak wymagałby
  osobnego szablonu (sterowniki VirtIO, sysprep, cloudbase-init)
  i kilku dni dodatkowej pracy; drugi kontroler na tym samym
  hypervisorze nie zapewniałby realnej redundancji.

### Konsekwencje
- Domena działa na poziomie funkcjonalności Windows Server 2008 R2
  (domyślny poziom Samby); wystarczający dla integracji LDAP usług.
- Zarządzanie zasadami grupy (GPO) wymaga narzędzi RSAT z systemu
  Windows.
- Kontroler domeny jest pojedynczym punktem awarii; drugi kontroler
  (np. na Raspberry Pi 5) wskazano jako kierunek rozwoju.

---

## ADR-016: Sekrety Ansible: Ansible Vault

**Status:** przyjęta
**Data:** 2026-10-22

### Kontekst
Konfiguracja kontrolera domeny wymaga haseł (administrator domeny,
konto usługowe LDAP, użytkownicy testowi), które muszą być dostępne dla
Ansible i odtwarzalne wraz z kodem. Repozytorium znajduje się
w serwisie GitHub.

### Rozważane opcje
1. Hasła poza repozytorium, przekazywane ręcznie przy uruchomieniu
2. Hasła w repozytorium w plikach zaszyfrowanych Ansible Vault
3. Zewnętrzny menedżer sekretów (np. HashiCorp Vault, OpenBao)

### Decyzja
Wybrano **opcję 2**: zmienne poufne z przedrostkiem vault_ w pliku
group_vars/domain_controllers/vault.yml, zaszyfrowanym algorytmem
AES-256; zmienne jawne w vars.yml odwołują się do nich. Hasło do sejfu
przechowywane poza repozytorium (~/.config/homelab, uprawnienia 600)
i w menedżerze haseł.

### Uzasadnienie
- Sekrety są wersjonowane razem z kodem, a w repozytorium występują
  wyłącznie w postaci zaszyfrowanej.
- Brak dodatkowej usługi do utrzymania (w przeciwieństwie do opcji 3).
- Konwencja vars.yml i vault.yml pozwala odnaleźć użycie zmiennej bez
  odszyfrowywania pliku.
- Zadania przekazujące hasła oznaczono no_log, a pętle etykietą
  (loop_control.label), aby hasła nie trafiały do wyników.

### Konsekwencje
- Utrata hasła do sejfu uniemożliwia odczyt zaszyfrowanych plików.
- Hasła generowane losowo (openssl rand) z dopiskiem zapewniającym
  zgodność z polityką złożoności Samby.

---

## ADR-017: Struktura katalogu i integracja usług przez LDAPS

**Status:** przyjęta
**Data:** 2026-10-22

### Kontekst
Usługi (Gitea, BookStack, Zabbix) mają uwierzytelniać użytkowników
kontami domeny i nadawać uprawnienia na podstawie przynależności do
grup. Domyślne hasła w domenie wygasają po 42 dniach.

### Decyzja
- Struktura OU: OU=Homelab z jednostkami Uzytkownicy, Grupy
  i KontaUslugowe; nazwy bez znaków diakrytycznych.
- Kontrola dostępu oparta na rolach (RBAC): grupy grp-it-admins,
  grp-gitea-users, grp-wiki-users, grp-zabbix-users.
- Konto usługowe svc-ldap-bind bez uprawnień administracyjnych,
  używane przez usługi wyłącznie do odczytu katalogu.
- Wyłączone wygasanie haseł dla kont technicznych (Administrator,
  svc-ldap-bind); konta użytkowników podlegają polityce domeny.
- Integracja usług przez LDAPS (port 636) z kontem usługowym podanym
  jako pełny DN; zwykły LDAP z prostym logowaniem jest odrzucany przez
  kontroler domeny.
- Strefa DNS homelab.internal z rekordami usług, zarządzana kodem.

### Uzasadnienie
- Uprawnienia nadawane grupom zamiast osobom: zmiana uprawnień
  użytkownika wymaga zmiany wyłącznie w katalogu.
- Wygaśnięcie hasła konta usługowego przerwałoby logowanie we
  wszystkich zależnych usługach; ochronę zapewnia losowe hasło
  w sejfie i minimalne uprawnienia konta.
- LDAPS chroni hasła przesyłane podczas logowania.

### Konsekwencje
- Do czasu wdrożenia urzędu certyfikacji (etap 6) certyfikat LDAPS
  kontrolera jest samopodpisany, a weryfikacja certyfikatu przez
  klientów jest wyłączona.
- Narzędzie samba-tool nie jest idempotentne; zadania Ansible stosują
  wzorzec odczytu stanu przed zmianą.

---

## ADR-018: Host usług svc01 z osobnym dyskiem danych

**Status:** przyjęta
**Data:** 2026-10-24

### Kontekst
Usługi w kontenerach (urząd certyfikacji, reverse proxy, Gitea,
BookStack, Zabbix) wymagają hosta z Dockerem. Obrazy i dane usług będą
rosły, a dysk szablonu ma 10 GB.

### Decyzja
- Maszyna svc01 (VMID 101, 192.168.1.41): pełny klon na local-lvm,
  4 rdzenie, 6 GB RAM, autostart.
- Osobny dysk danych 40 GB (scsi1), sformatowany ext4 i montowany
  w /var/lib/docker przez rolę data_disk, przed instalacją Dockera;
  stała nazwa urządzenia z /dev/disk/by-id, opcja nofail.
- Moduł Terraform rozszerzony o opcjonalny dysk danych (blok dynamic)
  z walidacją rozmiaru i magazynu.
- Każda usługa w osobnym katalogu /opt/stack/<usługa> z własnym plikiem
  Compose generowanym przez Ansible; dane w wolumenach nazwanych.

### Uzasadnienie
- Zapełnienie dysku danymi nie blokuje systemu operacyjnego.
- Dane usług znajdują się na jednym, wyodrębnionym dysku, co upraszcza
  kopie zapasowe i odtwarzanie (etap 9).
- Osobne pliki Compose pozwalają uruchamiać, aktualizować i odtwarzać
  usługi niezależnie.

### Konsekwencje
- Montowanie dysku po instalacji Dockera przesłoniłoby istniejące dane;
  kolejność ról jest istotna.

---

## ADR-019: Wewnętrzny urząd certyfikacji step-ca

**Status:** przyjęta
**Data:** 2026-10-24

### Kontekst
ADR-012 przyjął własny urząd certyfikacji. Usługi webowe wymagają
automatycznie odnawianych certyfikatów, a kontroler domeny certyfikatu
LDAPS z rozszerzeniem SAN (certyfikat wygenerowany przez Sambę nie
zawiera SAN i jest odrzucany przez klientów w języku Go).

### Decyzja
- step-ca 0.30.2 w kontenerze na svc01, zainicjowany automatycznie,
  z hasłem kluczy w Ansible Vault; dwa poziomy (główny i pośredni).
- Usługi webowe: provisioner ACME, certyfikaty 24-godzinne zamawiane
  i odnawiane przez Traefik (wyzwanie HTTP-01).
- Kontroler domeny: provisioner JWK infra, certyfikat roczny wydawany
  na podstawie wniosku CSR wygenerowanego na dc1 (klucz prywatny nie
  opuszcza kontrolera); odnawiany przez Ansible 30 dni przed
  wygaśnięciem.
- Certyfikat główny przechowywany w repozytorium (jest publiczny)
  i rozsyłany do magazynów zaufania serwerów rolą ca_trust; na stacji
  administratora import ręczny po weryfikacji odcisku.

### Rozważane alternatywy dla certyfikatu kontrolera domeny
1. Wyłączenie weryfikacji certyfikatu w usługach (ryzyko ataku
   man-in-the-middle i przechwycenia haseł użytkowników)
2. Zaufanie do urzędu wygenerowanego przez Sambę (odrzucone: brak SAN)
3. Certyfikat 24-godzinny przez ACME (codzienny restart Samby)

### Uzasadnienie
- Jeden urząd certyfikacji dla całego środowiska i jeden certyfikat
  główny do rozesłania.
- Krótkotrwałe certyfikaty ograniczają skutki wycieku klucza tam, gdzie
  odnawianie nie zakłóca pracy usługi; dłuższa ważność tam, gdzie
  wymiana wymaga restartu.

### Konsekwencje
- Wolumen step-ca (klucze urzędu) jest krytyczny dla kopii zapasowych:
  jego utrata wymusza wymianę certyfikatu głównego na wszystkich
  klientach, co przećwiczono po zmianie hasła urzędu.
- Rozesłanie certyfikatu na stacje z Windows w domenie powinno odbywać
  się przez GPO (poza zakresem).

---

## ADR-020: Reverse proxy Traefik

**Status:** przyjęta
**Data:** 2026-10-24

### Kontekst
Usługi muszą być dostępne przez HTTPS pod własnymi nazwami, bez
wystawiania ich portów bezpośrednio.

### Rozważane opcje
1. Nginx (konfiguracja w plikach, ręczne dopisywanie usług)
2. Caddy
3. Traefik (wykrywanie kontenerów na podstawie etykiet)

### Decyzja
Traefik w kontenerze, jedyny punkt wejścia (porty 80 i 443),
przekierowanie HTTP na HTTPS, certyfikaty z resolvera stepca,
exposedByDefault: false, wspólna sieć Dockera proxy dla usług
wystawianych przez Traefika.

### Uzasadnienie
- Usługa jest wystawiana przez dodanie etykiet w jej pliku Compose,
  bez zmiany konfiguracji proxy.
- Wbudowany klient ACME z obsługą wewnętrznego urzędu
  (LEGO_CA_CERTIFICATES) i krótkich certyfikatów
  (certificatesDuration).
- Kontenery nie są wystawiane bez jawnej zgody.

### Konsekwencje
- Traefik ma dostęp do gniazda Dockera (tylko do odczytu), co daje mu
  szerokie uprawnienia; pośrednik gniazda (docker socket proxy)
  wskazano jako kierunek rozwoju.
- Zmiana konfiguracji statycznej wymaga restartu (handler).

---

## ADR-021: Gitea z izolowaną bazą danych i integracją z AD

**Status:** przyjęta
**Data:** 2026-10-24

### Decyzja
- Gitea 28.2.0 i PostgreSQL 17.11 w jednym pliku Compose; baza
  wyłącznie w sieci gitea-internal z internal: true; Gitea w sieciach
  proxy i gitea-internal.
- Konfiguracja przez zmienne GITEA__sekcja__KLUCZ, bez kreatora
  instalacji; rejestracja wyłączona, wymagane logowanie do przeglądania,
  dostęp wyłącznie przez HTTPS (SSH wyłączone).
- Uwierzytelnianie przez LDAPS do dc1 kontem svc-ldap-bind (hasło
  w group_vars/all, wspólne dla kontrolera i hosta usług), z pełną
  weryfikacją certyfikatu (magazyn zaufania hosta montowany w kontenerze).
- RBAC: logowanie dla członków grp-gitea-users, uprawnienia
  administratora dla członków grp-it-admins; konta tworzone przy
  pierwszym logowaniu, atrybut mail z katalogu.

### Uzasadnienie
- Segmentacja sieci kontenerów: przejęcie innej usługi nie daje
  bezpośredniego dostępu do bazy Gitei.
- Uprawnienia zarządzane wyłącznie w katalogu.

### Konsekwencje
- Rola tworzy źródło uwierzytelniania, lecz go nie aktualizuje
  (gitea admin auth update-ldap jako rozszerzenie).
- Sekrety w zmiennych środowiskowych pliku Compose (tryb 0600).

---

## ADR-022: Przypinanie i weryfikacja wersji obrazów kontenerów

**Status:** przyjęta
**Data:** 2026-10-24

### Kontekst
Tagi takie jak latest zmieniają się w czasie, co uniemożliwia
powtarzalne odtworzenie środowiska. Krytyczne podatności w składnikach
obrazów (np. PHP2Shell, październik 2026) wymagają kontrolowanej
aktualizacji.

### Decyzja
- Każdy obraz przypięty do konkretnej wersji w wartościach domyślnych
  roli (step-ca 0.30.2, Gitea 28.2.0, PostgreSQL 17.11, Traefik).
- Przed przypięciem odczyt wersji z obrazu latest i porównanie
  identyfikatora obrazu (docker image inspect) z identyfikatorem
  obrazu o tagu wersji.
- Aktualizacja obrazu przez zmianę wersji w repozytorium i ponowne
  wykonanie roli.

### Uzasadnienie
- Powtarzalność wdrożenia i jawna historia zmian wersji w Git.
- Weryfikacja wykazała nieoczekiwaną zmianę numeracji wersji Gitei,
  co potwierdza zasadność sprawdzania zamiast zakładania.

### Konsekwencje
- Brak automatycznego powiadamiania o podatnościach w obrazach;
  skanowanie obrazów (np. Trivy) jako kierunek rozwoju.

---

## ADR-023: BookStack z obrazem LinuxServer.io i mapowaniem ról

**Status:** przyjęta
**Data:** 2026-10-24

### Kontekst
Środowisko wymaga bazy wiedzy z logowaniem kontami domeny i rolami
zależnymi od grup. Projekt BookStack nie publikuje oficjalnego obrazu
Docker. BookStack jest napisany w PHP, a w październiku 2026 r.
opublikowano krytyczne podatności silnika PHP (PHP2Shell).

### Decyzja
- Obraz lscr.io/linuxserver/bookstack:v26.09.2-ls292 (BookStack
  26.09.2, PHP 8.5.12 zbudowane 21.10.2026, czyli z poprawką PHP2Shell)
  oraz MariaDB 11.8.9 w sieci wewnętrznej bookstack-internal.
- Logowanie przez LDAPS kontem svc-ldap-bind z weryfikacją certyfikatu
  (LDAP_TLS_CA_CERT); dostęp dla członków grp-wiki-users.
- Identyfikacja użytkowników po atrybucie objectGUID (niezmiennym przy
  zmianie nazwy konta).
- Mapowanie grup na role przez identyfikatory zewnętrzne ról:
  Admin ↔ grp-it-admins, Editor ↔ grp-wiki-users; ustawiane poleceniem
  SQL z kontrolą liczby zmienionych wierszy (ROW_COUNT), synchronizowane
  przy każdym logowaniu.
- Usunięcie domyślnego konta admin@admin.com po pierwszym logowaniu
  administratora z AD.

### Uzasadnienie
- LinuxServer.io utrzymuje obraz i wydał wersję z poprawionym PHP
  w dniu publikacji łatek; wersję PHP zweryfikowano przed przypięciem.
- Mapowanie grup na role realizuje RBAC bez ręcznej konfiguracji
  uprawnień w aplikacji.

### Konsekwencje
- Zależność od dostawcy obrazu spoza projektu BookStack.
- Domyślne konto aplikacji wymagało ręcznego usunięcia; automatyzacja
  tego kroku jako rozszerzenie.

---

## ADR-024: Monitoring Zabbix 7.0 LTS

**Status:** przyjęta
**Data:** 2026-10-25

### Kontekst
Środowisko wymaga monitoringu maszyn, usług i kontenerów z wykrywaniem
awarii. Najnowsza wersja Zabbixa (7.4.16) jest wydaniem standardowym,
a gałąź 8.0 LTS nie została jeszcze wydana. Repozytorium Debiana 13
zawiera agenta Zabbix 2 w wersji 7.0.22.

### Decyzja
- Zabbix 7.0.32 LTS (serwer, interfejs Nginx/PHP-FPM, PostgreSQL 17.11)
  w kontenerach na svc01, interfejs za Traefikiem pod
  zabbix.homelab.internal.
- Agent Zabbix 2 z repozytorium Debiana na dc1, svc01 i hypervisorze,
  instalowany rolą zabbix_agent dla grupy monitored.
- Trzy sieci: zabbix-internal (internal: true, baza), proxy (interfejs),
  zabbix-agents ze stałą podsiecią 172.30.0.0/24 (łączność serwera
  z agentami w sieci LAN).
- Agent na svc01 w grupie docker (szablon Docker by Zabbix agent 2).

### Uzasadnienie
- Wydanie LTS zapewnia wieloletnie wsparcie i poprawki bezpieczeństwa.
- Agent z repozytorium dystrybucji należy do tej samej gałęzi co serwer,
  bez dodatkowego repozytorium na każdej maszynie.
- Połączenia z kontenera do agenta na tym samym hoście nie są
  maskowane adresem hosta; stała podsieć pozwala jawnie dopuścić ją
  w konfiguracji agenta.

### Konsekwencje
- Monitoring działa na tym samym sprzęcie co usługi i nie wykryje
  awarii całego hypervisora; przeniesienie na Raspberry Pi 5 jako
  kierunek rozwoju.
- Członkostwo agenta w grupie docker daje mu uprawnienia równoważne
  rootowi na svc01 (pośrednik gniazda Dockera jako rozszerzenie).
- Poza zakresem: powiadomienia (typy mediów i akcje), Grafana,
  monitorowanie Proxmox VE przez API.

---

## ADR-025: Przypinanie obrazów kontenerów przez skrót

**Status:** przyjęta (uzupełnienie ADR-022)
**Data:** 2026-10-25

### Kontekst
Obrazy Zabbixa o tagach alpine-7.0-latest i alpine-7.0.32 zawierały tę
samą wersję aplikacji i PHP 8.5.12, lecz miały różne identyfikatory:
były to dwie kompilacje z tego samego dnia. Tag jest nazwą, którą
wydawca może przenieść na inny obraz.

### Decyzja
Obrazy Zabbixa przypięte jednocześnie tagiem (czytelność) i skrótem
manifestu (niezmienność), np.
zabbix/zabbix-web-nginx-pgsql:alpine-7.0.32@sha256:a54ce2e1…; przed
przypięciem weryfikacja wersji PHP pod kątem PHP2Shell.

### Uzasadnienie
- Skrót jednoznacznie identyfikuje sprawdzony obraz; ponowne
  odtworzenie środowiska pobierze dokładnie ten sam obraz.
- Niezgodny skrót powoduje błąd pobrania zamiast cichej zmiany.

### Konsekwencje
- Aktualizacja wymaga zmiany skrótu w repozytorium.
- Pozostałe usługi przypięte tagiem; ujednolicenie przez skróty jako
  rozszerzenie.

---

## ADR-026: Konfiguracja Zabbixa przez API i logowanie kontami AD

**Status:** przyjęta
**Data:** 2026-10-25

### Decyzja
- Konfiguracja Zabbixa jako kod: kolekcja community.zabbix
  (połączenie httpapi, host zabbix-api w inwentarzu,
  ansible_zabbix_url_path: "") oraz bezpośrednie wywołania JSON-RPC
  modułem uri.
- Zmiana domyślnego hasła konta Admin przez API, idempotentna:
  wykonywana tylko, gdy logowanie hasłem domyślnym się powiedzie.
- Rejestracja hostów z szablonami Linux by Zabbix agent i Docker by
  Zabbix agent 2; wyłączenie domyślnego hosta Zabbix server.
- Katalog użytkowników LDAPS (dc1, svc-ldap-bind), JIT provisioning,
  LDAP jako domyślna metoda uwierzytelniania.
- Mapowanie grup: grp-it-admins → Super admin role, grupa
  „Homelab - administratorzy”; grp-zabbix-users → User role, grupa
  „Homelab - podglad” z prawem odczytu grupy hostów Homelab.
- Konto awaryjne Admin w grupie Zabbix administrators z wymuszonym
  logowaniem wewnętrznym; kolejność zadań gwarantuje ustawienie
  wyjątku przed przełączeniem domyślnej metody na LDAP.

### Uzasadnienie
- Pełna odtwarzalność konfiguracji monitoringu z repozytorium.
- JIT provisioning wymaga LDAP jako metody domyślnej; konto awaryjne
  zapewnia dostęp przy niedostępności kontrolera domeny.
- Rozdzielenie roli (zakres czynności) i grupy użytkowników (zakres
  hostów) realizuje RBAC na dwóch poziomach.

### Konsekwencje
- Moduł zabbix_user_directory zgłasza zmianę przy każdym uruchomieniu,
  ponieważ API nie zwraca hasła konta usługowego (pole tylko do zapisu).
- Ostrzeżenie o przestarzałym imporcie w kodzie kolekcji (zewnętrzne).

---

## ADR-027: Strategia kopii zapasowych danych usług

**Status:** przyjęta
**Data:** 2026-10-25

### Kontekst
Infrastruktura jako kod odtwarza maszyny i konfigurację, lecz nie dane
wytworzone przez użytkowników (konta i grupy w AD, repozytoria,
dokumentacja, historia monitoringu, klucze urzędu certyfikacji).
Istniejące kopie maszyn (vzdump, etap 1) są spójne jedynie jak po
nagłym wyłączeniu (agent gościa wyłączony), niezaszyfrowane
i niepodzielne.

### Rozważane opcje
1. Wyłącznie kopie maszyn w Proxmox VE (vzdump)
2. Zrzuty baz danych (pg_dump, mariadb-dump) importowane przy
   odtwarzaniu
3. Kopie wolumenów na zimno i kopia katalogu narzędziem Samby,
   przechowywane w repozytorium restic

### Decyzja
Wybrano **opcję 3** jako uzupełnienie opcji 1 (obrona warstwowa):
- dc1: samba-tool domain backup offline;
- svc01: dla każdej usługi zatrzymanie, kopia jej wolumenów, ponowne
  uruchomienie (osobna kopia z tagiem usługi); bez wolumenu Traefika
  (certyfikaty odtwarzalne);
- restic: szyfrowanie AES-256, deduplikacja, kompresja, retencja
  7 dziennych i 4 tygodniowych kopii, weryfikacja restic check;
- repozytoria na Synology w udziale homelab-backup (NFS 4,
  dostęp wyłącznie dla 192.168.1.40 i 192.168.1.41, tylko root);
- harmonogram: timer systemd codziennie o 1:30 (przed vzdump o 2:00),
  Persistent=true, losowe opóźnienie do 5 minut;
- zabezpieczenia: kontrola montowania w skrypcie i RequiresMountsFor
  w usłudze; ponowne uruchomienie usługi także po nieudanej kopii.

### Uzasadnienie
- Kopia na zimno jest spójna bez narzędzi specyficznych dla bazy,
  a odtworzenie sprowadza się do przywrócenia plików przed startem
  usługi.
- Kopie per usługa pozwalają przywrócić jedną usługę bez wpływu na
  pozostałe.
- Szyfrowanie chroni klucze urzędu i skróty haseł z AD w razie
  kradzieży NAS-a.

### Konsekwencje
- Krótka przerwa w działaniu każdej usługi podczas kopii
  (zmierzona: 1–16 s), zdominowana przez restart kontenerów.
- Utrata hasła repozytorium restic uniemożliwia odtworzenie; hasło
  przechowywane w sejfie Ansible i w menedżerze haseł, zalecana kopia
  poza infrastrukturą.
- Brak kopii poza siedzibą (reguła 3-2-1 niespełniona); Hyper Backup
  do chmury lub nośnika zewnętrznego jako kierunek rozwoju.
- Monitorowanie świeżości kopii (plik last-success) w Zabbixie jako
  rozszerzenie.

---

## ADR-028: Wdrożenie środowiska jednym poleceniem

**Status:** przyjęta
**Data:** 2026-10-27

### Kontekst
Wdrożenie wymagało znajomości kolejności wykonywania konfiguracji
Terraform i playbooków Ansible. Między dc1 a svc01 występuje cykl
zależności: step-ca na svc01 potrzebuje DNS z dc1, a dc1 potrzebuje
certyfikatu LDAPS z urzędu na svc01.

### Decyzja
- Playbook site.yml importuje playbooki w kolejności zależności:
  dc.yml, svc.yml, dc-tls.yml, monitoring.yml, zabbix-config.yml,
  backup.yml; cykl rozwiązany drugim przebiegiem na dc1 (dc-tls.yml,
  poprzedzony rolą ca_trust).
- Skrypt infra/scripts/deploy.sh: Terraform (images, platform) z planem
  -detailed-exitcode i apply tylko przy zmianach, osobne podpowłoki dla
  tokenów dwóch kont, oczekiwanie na SSH i cloud-init, site.yml,
  pomiar czasu etapów.
- Usuwanie klucza serwera z known_hosts wyłącznie dla maszyn, które
  według planu Terraform zostały utworzone od nowa.
- force_handlers = True; role weryfikują efekt (np. obecność
  certyfikatu w magazynie systemowym), a nie tylko wykonanie kroku.

### Uzasadnienie
- Kolejność zapisana w kodzie zamiast w pamięci administratora.
- To samo polecenie służy do pierwszego wdrożenia, weryfikacji
  zgodności z kodem i odbudowy po awarii.
- Zmiana klucza istniejącej maszyny nadal zatrzymuje wdrożenie
  (ochrona przed podszyciem).

### Konsekwencje
- Weryfikacja zgodności całego środowiska trwa ok. 90 s.
- Zbieżność zamiast ścisłej idempotentności: pierwsze uruchomienie
  może wprowadzić zmiany zewnętrzne (aktualizacje pakietów); kolejne
  zgłaszają jedynie zmianę pola hasła w Zabbixie (ADR-026).

---

## ADR-029: Przywracanie danych usług przy odbudowie

**Status:** przyjęta
**Data:** 2026-10-27 (poprawka 2026-10-27, INC-01)

### Kontekst
Odbudowany svc01 bez danych uruchomiłby puste usługi, a step-ca
utworzyłby nowy urząd z nowym certyfikatem głównym.

### Decyzja
- Rola backup_restore wykonywana w svc.yml po roli backup (montowanie
  NFS, restic), a przed rolami usług.
- Dla każdej usługi z backup_docker_stacks: przywrócenie wyłącznie
  wtedy, gdy żaden z jej wolumenów nie istnieje, a w repozytorium jest
  kopia z jej tagiem; istniejące dane nigdy nie są nadpisywane.
- Wolumeny tworzone z etykietami com.docker.compose.project
  i com.docker.compose.volume, aby Compose uznał je za własne.
- Lista wolumenów dołączana do argv jako osobne elementy
  (wyrażenie Jinja z konkatenacją list).

### Uzasadnienie
- Jedna rola zachowuje się poprawnie przy zwykłym wdrożeniu (brak
  działań), pierwszym wdrożeniu (brak kopii) i odbudowie (przywrócenie).
- Przywrócenie przed rolą step_ca zachowuje tożsamość urzędu
  (odcisk certyfikatu głównego bez zmian).

### Konsekwencje
- Błędne wykrycie wolumenów skutkuje nadpisaniem danych działających
  usług (INC-01); test na działającym środowisku jest obowiązkowy po
  każdej zmianie roli.

---

## ADR-030: Testy akceptacyjne i metodyka pomiaru RTO i RPO

**Status:** przyjęta
**Data:** 2026-10-31

### Decyzja
- Skrypt infra/scripts/verify.sh: DNS przez dc1, LDAPS z weryfikacją
  certyfikatu, zdrowie step-ca, Gitea, BookStack i API Zabbixa przez
  HTTPS bez wyłączania weryfikacji TLS, obecność i działanie
  dziewięciu oczekiwanych kontenerów na svc01.
- Tryb --wait N: powtarzanie co 10 s do pełnej sprawności lub limitu.
- RTO: od chwili awarii (date przed qm destroy) do przejścia wszystkich
  testów. RPO: od zakończenia ostatniej kopii do chwili awarii.
- Znaczniki danych w BookStacku przed i po kopii jako dowód RPO.
- Dwa scenariusze awarii svc01: A (deploy.sh i restic), B (qmrestore
  z vzdump).

### Uzasadnienie
- Sprawność oceniana z perspektywy użytkownika, a nie zakończenia
  polecenia.

### Konsekwencje
- Testy sprawdzają dostępność, nie logowanie kontami AD (wymagałoby
  haseł w skrypcie); logowanie weryfikowane ręcznie.

---

## ADR-031: Zarządzanie kluczami SSH i sekretami administratora

**Status:** przyjęta
**Data:** 2026-10-31 (INC-02)

### Decyzja
- Pierwszy klucz automatyzacji przekazywany przez cloud-init przy
  tworzeniu maszyny; później kluczami zarządza Ansible
  (playbook rotate-automation-key.yml).
- Moduł Terraform ignoruje zmiany initialization[0].user_account,
  aby rotacja nie wymuszała zmian cloud-init istniejących maszyn.
- Rotacja w kolejności: dodanie nowego klucza, test, usunięcie
  pozostałych (exclusive), test odrzucenia starego, zniszczenie pliku.
- Kopie kluczy SSH, hasła sejfu Ansible i hasła restic w menedżerze
  haseł, zweryfikowane odtworzeniem i użyciem; sekrety krytyczne
  (hasło sejfu, hasło restic, kody zapasowe 2FA) także poza
  infrastrukturą (koperta awaryjna).

### Uzasadnienie
- Stacja administratora przestaje być pojedynczym punktem awarii:
  konfiguracja jest w repozytorium, sekrety w menedżerze haseł.
- Ujawniony klucz uznaje się za przejęty niezależnie od oceny ryzyka.

### Konsekwencje
- Bezpieczeństwo całości zależy od ochrony menedżera haseł (hasło
  główne, drugi składnik, potwierdzanie dostępu do wpisów).
- Menedżer haseł działający na tym samym sprzęcie co środowisko nie
  zastępuje kopii poza infrastrukturą.

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
