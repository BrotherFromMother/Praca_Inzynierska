# ADR-004: Protokół dostępu do magazynu danych na Synology

Status: przyjęta
Data: 2026-10-17

## Kontekst
Synology DS225+ ma udostępniać przestrzeń dyskową dla Proxmox VE:
na dyski środowisk użytkowników, obrazy ISO, szablony i kopie zapasowe.
Proxmox obsługuje dwa główne protokoły sieciowe: NFS (dostęp plikowy)
i iSCSI (dostęp blokowy).

## Rozważane opcje
1. NFS: udział plikowy, dyski VM jako pliki (qcow2/raw)
2. iSCSI: LUN widoczny w Proxmoxie jako dysk blokowy, zwykle z LVM

## Decyzja
Wybrano NFS (wersja 4.1).

## Uzasadnienie
- Jeden udział obsługuje wiele typów zawartości: dyski VM, obrazy ISO,
  szablony, snippety cloud-init i kopie zapasowe. iSCSI z LVM
  przechowuje wyłącznie dyski.
- Format qcow2 na NFS zapewnia snapshoty i thin provisioning.
- Pliki są widoczne bezpośrednio na NAS-ie, co ułatwia diagnostykę
  i pozwala korzystać ze snapshotów Btrfs po stronie Synology.
- Prostsza konfiguracja: brak zarządzania LUN-ami, targetami
  i inicjatorami.
- Dostęp ograniczony regułą NFS do adresu hypervisora.

## Konsekwencje
- Dostęp plikowy wprowadza dodatkowy narzut w porównaniu z dostępem
  blokowym; wpływ na wydajność zostanie zmierzony w rozdziale testów.
- Uwierzytelnianie AUTH_SYS opiera się na adresie IP hosta, a nie
  na kryptograficznej tożsamości. W środowisku laboratoryjnym jest to
  akceptowalne; w produkcji należałoby rozważyć NFS z Kerberosem
  lub izolowaną sieć dla ruchu storage (VLAN STORAGE).
