# Praca Inżynierska

# ADR-001: Wybór platformy wirtualizacji (hypervisora)

Status: przyjęta
Data: 2026-10-17

## Kontekst
Projekt wymaga platformy wirtualizacji uruchomionej bezpośrednio na
sprzęcie (bare-metal) na komputerze Lenovo MiniPC (32 GB RAM). Platforma
musi spełniać następujące wymagania:
- udostępniać API REST, przez które autorski portal będzie tworzył
  i usuwał maszyny wirtualne,
- być obsługiwana przez narzędzia Infrastructure as Code
  (Terraform/OpenTofu, Ansible),
- działać na sprzęcie klasy konsumenckiej (MiniPC),
- nie generować kosztów licencyjnych w środowisku laboratoryjnym,
- umożliwiać integrację z zewnętrznym magazynem danych (NFS/iSCSI)
  oraz wykonywanie kopii zapasowych.

## Rozważane opcje
1. Proxmox VE (KVM + LXC)
2. VMware ESXi / vSphere
3. Microsoft Hyper-V (Windows Server)
4. XCP-ng (Xen) z Xen Orchestra

## Porównanie

| Kryterium              | Proxmox VE        | VMware ESXi              | Hyper-V                    | XCP-ng                 |
|------------------------|-------------------|--------------------------|----------------------------|------------------------|
| Licencja               | open source       | komercyjna, subskrypcja  | wymaga licencji Windows    | open source            |
|                        | (AGPLv3)          |                          | Server                     |                        |
| API do zapisu          | REST, tokeny API  | pełne tylko w płatnych   | PowerShell / WMI           | XAPI, API Xen          |
|                        |                   | edycjach                 |                            | Orchestra              |
| Terraform / OpenTofu   | dojrzały provider | oficjalny provider       | provider społecznościowy   | provider społecznościowy|
|                        | (bpg/proxmox)     | (wymaga vCenter)         |                            |                        |
| Ansible                | kolekcja          | kolekcja                 | moduły Windows             | ograniczone wsparcie   |
|                        | community.proxmox | community.vmware         |                            |                        |
| Kontenery systemowe    | tak (LXC)         | nie                      | nie                        | nie                    |
| Sprzęt konsumencki     | szerokie wsparcie | ograniczona lista        | dobre                      | dobre                  |
|                        | (jądro Linuksa)   | sterowników (HCL)        |                            |                        |
| Kopie zapasowe         | wbudowane (vzdump,| zewnętrzne narzędzia     | zewnętrzne narzędzia       | wbudowane w Xen        |
|                        | PBS)              |                          |                            | Orchestra              |

## Decyzja
Wybrano Proxmox VE.

## Uzasadnienie
- Natywne API REST z tokenami o ograniczonych uprawnieniach umożliwia
  bezpośrednią integrację z portalem bez dodatkowych komponentów
  zarządzających (w przeciwieństwie do VMware, gdzie pełna automatyzacja
  wymaga vCenter).
- Dojrzałe wsparcie narzędzi IaC: provider bpg/proxmox dla OpenTofu
  oraz kolekcja community.proxmox dla Ansible, łącznie z dynamicznym
  inwentarzem.
- Brak kosztów licencyjnych przy pełnej funkcjonalności.
- Obsługa zarówno maszyn wirtualnych (KVM), jak i kontenerów
  systemowych (LXC) w jednej platformie.
- Wbudowane mechanizmy: firewall, kopie zapasowe, obsługa NFS/iSCSI,
  uwierzytelnianie przez LDAP/Active Directory.
- Oparcie o Debian GNU/Linux zapewnia szerokie wsparcie sterowników
  dla sprzętu konsumenckiego.
- Zmiany modelu licencjonowania VMware po przejęciu przez Broadcom
  (przejście na subskrypcje, wycofanie darmowej edycji ESXi w 2024 r.)
  zwiększyły koszt i niepewność tej opcji.

## Konsekwencje
- Ograniczone wsparcie komercyjne (bez subskrypcji): korzystanie
  z repozytorium pve-no-subscription, przeznaczonego do zastosowań
  nieprodukcyjnych.
- Mniejsza popularność w dużych korporacjach niż VMware; rozwiązanie
  jest jednak szeroko stosowane w małych i średnich organizacjach.
- Hypervisor jest instalowany i konfigurowany ręcznie

# ADR-002: System plików dysku lokalnego hypervisora

Status: przyjęta
Data: 2026-10-17

## Kontekst
Lenovo MiniPC ma jeden dysk wewnętrzny i 32 GB RAM, które mają być
przeznaczone przede wszystkim dla maszyn wirtualnych.

## Rozważane opcje
1. ext4 + LVM-thin: domyślna opcja instalatora Proxmox VE
2. ZFS (pojedynczy dysk)

## Decyzja
Wybrano ext4 + LVM-thin.

## Uzasadnienie
- Przy jednym dysku ZFS nie zapewnia redundancji (brak mirrora/RAID-Z),
  więc jego główna zaleta nie jest wykorzystana.
- ZFS rezerwuje część RAM na pamięć podręczną ARC, a RAM jest
  najbardziej ograniczonym zasobem w projekcie.
- LVM-thin obsługuje thin provisioning, snapshoty i linked clone,
  czyli funkcje potrzebne w projekcie.
- Prostsza konfiguracja i mniejszy narzut na zasoby.

## Konsekwencje
- Brak sum kontrolnych danych na poziomie systemu plików.
- Awaria dysku oznacza utratę lokalnych maszyn; ryzyko ograniczają
  codzienne kopie zapasowe na Synology (etap 1.6).

```bash
root@homelab:~# df -Th
Filesystem           Type      Size  Used Avail Use% Mounted on
udev                 devtmpfs   15G     0   15G   0% /dev
tmpfs                tmpfs     3.2G  1.3M  3.2G   1% /run
/dev/mapper/pve-root ext4       94G  5.3G   84G   6% /
tmpfs                tmpfs      16G   46M   16G   1% /dev/shm
efivarfs             efivarfs  320K   66K  250K  21% /sys/firmware/efi/efivars
tmpfs                tmpfs     5.0M     0  5.0M   0% /run/lock
tmpfs                tmpfs     1.0M     0  1.0M   0% /run/credentials/systemd-journald.service
/dev/nvme0n1p2       vfat     1022M  9.1M 1013M   1% /boot/efi
tmpfs                tmpfs      16G     0   16G   0% /tmp
/dev/fuse            fuse      128M   16K  128M   1% /etc/pve
tmpfs                tmpfs     1.0M     0  1.0M   0% /run/credentials/getty@tty1.service
tmpfs                tmpfs     3.2G  4.0K  3.2G   1% /run/user/0
root@homelab:~#
```


  # ADR-003: Rozmieszczenie dysków maszyn wirtualnych

Status: przyjęta
Data: 2026-10-17

## Kontekst
Dostępne są dwa magazyny dysków VM: lokalny local-lvm (dysk Lenovo)
oraz nas-vm (NFS na Synology DS225+).

## Decyzja
- Maszyny platformy (dc1, svc01) → local-lvm
- Środowiska tworzone przez portal → nas-vm (format qcow2)

## Uzasadnienie
- Usługi krytyczne (uwierzytelnianie, portal) nie mogą zależeć
  od dostępności NAS-a i wymagają najlepszej wydajności dysku.
- Środowiska użytkowników są tymczasowe i liczne: liczy się
  pojemność, a krótkotrwała niedostępność jest akceptowalna.
- Rozwiązanie wykorzystuje NAS jako współdzielony magazyn danych.

## Konsekwencje
- Awaria NAS-a zatrzymuje środowiska użytkowników, ale nie platformę.
- Wydajność dysków środowisk zależy od przepustowości sieci; zostanie
  to zmierzone w rozdziale testów (porównanie local-lvm i NFS).
