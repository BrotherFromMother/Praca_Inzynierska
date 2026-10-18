# Dziennik: etap 1 (fundament)

**Data:** 2026-10-17

## Wykonane prace
- Instalacja Proxmox VE 9.2 na Lenovo MiniPC (węzeł homelab,
  192.168.1.30), system plików ext4 z LVM-thin.
- Zmiana repozytoriów na pve-no-subscription, aktualizacja systemu,
  restart z nowym jądrem 7.0.14-24.
- Most vmbr0 w trybie VLAN aware.
- Uwierzytelnianie dwuskładnikowe (TOTP) dla root@pam.
- Synology DS225+ (192.168.1.80): foldery pve-vm i pve-backup,
  usługa NFS 4.1 z dostępem ograniczonym do adresu hypervisora.
- Magazyny nas-vm i nas-backup w Proxmoxie, test zapisu obrazu ISO
  z weryfikacją sumy SHA-512.
- Zadanie kopii zapasowych: codziennie 02:00, snapshot, ZSTD,
  retencja 7 dziennych i 4 tygodniowe.
- Decyzje ADR-001 do ADR-004.

## Napotkane problemy

| Problem | Przyczyna | Rozwiązanie |
|---|---|---|
| Błąd przy aktualizacji listy pakietów | domyślnie włączone repozytoria enterprise wymagają subskrypcji | wyłączenie repozytoriów enterprise, dodanie pve-no-subscription |
| Nieczytelny wynik apt update w listingu | polecenie uruchomione w tle | ponowne uruchomienie polecenia na pierwszym planie |
| System działał na starym jądrze po aktualizacji | nowe jądro aktywuje się dopiero po restarcie | restart serwera |
| Zadanie backupu bez własnej retencji | pole „Keep all backups” pozostało zaznaczone | edycja zadania, ustawienie retencji 7/4 |
| Pozostałe montowanie /mnt/pve/nas-back | zmiana nazwy magazynu nie odmontowuje poprzedniego punktu montowania | ręczne umount i usunięcie katalogu |
| VLAN aware nie pojawiło się w konfiguracji | zmiany sieci trafiają do pliku interfaces.new do czasu zatwierdzenia | „Apply Configuration” w panelu |

## Otwarte kwestie
- Powiadomienia e-mail (legacy-sendmail) prawdopodobnie nie docierają
  do Gmaila; do rozwiązania przy konfiguracji monitoringu.
- Retencja na poziomie magazynu nas-backup (keep-all) a kopie ręczne:
  do decyzji.
- Drugi interfejs sieciowy nic1: do zidentyfikowania.
- Zakres DHCP routera: do sprawdzenia.
