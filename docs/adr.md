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
