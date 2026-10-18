# Listingi

Zebrane wyniki poleceń do wykorzystania w pracy. Każdy listing ma numer
roboczy, podpis i komentarz w postaci gotowej do przeniesienia.

---

# Etap 1: Fundament (Proxmox VE, Synology)

## Listing 5.1. Aktualizacja listy pakietów po zmianie repozytoriów

```console
root@homelab:~# apt update
Hit:1 http://security.debian.org/debian-security trixie-security InRelease
Hit:2 http://deb.debian.org/debian trixie InRelease
Get:3 http://deb.debian.org/debian trixie-updates InRelease [47.3 kB]
Hit:4 http://download.proxmox.com/debian/pve trixie InRelease
Fetched 47.3 kB in 0s (149 kB/s)
All packages are up to date.
```

Komentarz: lista pakietów pobierana jest wyłącznie z repozytoriów
Debiana oraz z repozytorium pve-no-subscription. Brak błędu 401
potwierdza wyłączenie repozytoriów enterprise, a komunikat końcowy
wskazuje, że system jest w pełni zaktualizowany.

---

## Listing 5.2. Wersja platformy Proxmox VE i uruchomione jądro

```console
root@homelab:~# pveversion
pve-manager/9.2.21/4f6e0ac86f9e8c7f (running kernel: 7.0.14-24-pve)
```

Komentarz: środowisko działa na Proxmox VE 9.2 z jądrem Linux 7.0.14,
zainstalowanym podczas aktualizacji i aktywowanym po ponownym
uruchomieniu serwera.

---

## Listing 5.3. System plików dysku lokalnego hypervisora

```console
root@homelab:~# df -Th /
Filesystem           Type  Size  Used Avail Use% Mounted on
/dev/mapper/pve-root ext4   94G  5.3G   84G   6% /
```

Komentarz: partycja systemowa korzysta z systemu plików ext4 na
wolumenie LVM, zgodnie z decyzją ADR-002.

---

## Listing 5.4. Konfiguracja mostu sieciowego vmbr0 z obsługą VLAN

```console
root@homelab:~# grep -A8 "iface vmbr0" /etc/network/interfaces
iface vmbr0 inet static
        address 192.168.1.30/24
        gateway 192.168.1.1
        bridge-ports nic0
        bridge-stp off
        bridge-fd 0
        bridge-vlan-aware yes
        bridge-vids 2-4094
```

Komentarz: most vmbr0 łączy fizyczny interfejs nic0 z maszynami
wirtualnymi. Opcje bridge-vlan-aware i bridge-vids włączają obsługę
tagów VLAN, przygotowując infrastrukturę do ewentualnej segmentacji
sieci bez przebudowy konfiguracji.

---

## Listing 5.5. Synchronizacja czasu systemowego

```console
root@homelab:~# timedatectl
               Local time: Sat 2026-10-17 22:15:16 CEST
           Universal time: Sat 2026-10-17 20:15:16 UTC
                 RTC time: Sat 2026-10-17 20:15:16
                Time zone: Europe/Warsaw (CEST, +0200)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: no
root@homelab:~# chronyc sources
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^+ ntp.kdm.wcss.pl               2   9   377   463    -35us[  -35us] +/-   36ms
^+ ip-89-161-47-139.tel.tkb>     1   9   373   199    -16ms[  -16ms] +/-   48ms
^- ip-89-161-47-133.tel.tkb>     1   9   325    78    -16ms[  -16ms] +/-   48ms
^* ntp01.pingless.com            2   8   377   26m  +4355us[+4902us] +/-   25ms
```

Komentarz: zegar systemowy jest zsynchronizowany przez usługę chrony
z publicznymi serwerami NTP (symbol ^* oznacza aktualnie wybrane
źródło). Poprawny czas jest warunkiem działania uwierzytelniania
Kerberos w domenie Active Directory.

---

## Listing 5.6. Udziały NFS udostępniane przez Synology

```console
root@homelab:~# pvesm scan nfs 192.168.1.80
/volume1/pve-backup 192.168.1.30
/volume1/pve-vm     192.168.1.30
```

Komentarz: Synology udostępnia dwa udziały wyłącznie dla adresu
hypervisora (192.168.1.30), zgodnie z regułami dostępu NFS.

---

## Listing 5.7. Stan magazynów danych po podłączeniu udziałów NFS

```console
root@homelab:~# pvesm status
Name              Type     Status     Total (KiB)      Used (KiB) Available (KiB)        %
local              dir     active        98497780         5537228        87911004    5.62%
local-lvm      lvmthin     active       365760512               0       365760512    0.00%
nas-backup         nfs     active      3739615232       134181632      3605433600    3.59%
nas-vm             nfs     active      3739615232       134181632      3605433600    3.59%
```

Komentarz: wszystkie magazyny mają status active. Magazyny nas-backup
i nas-vm wykazują identyczną pojemność, ponieważ oba udziały znajdują
się na tym samym wolumenie Synology.

---

## Listing 5.8. Parametry montowania udziałów NFS

```console
root@homelab:~# mount | grep nfs
192.168.1.80:/volume1/pve-vm on /mnt/pve/nas-vm type nfs4 (rw,relatime,vers=4.1,rsize=262144,wsize=262144,namlen=255,hard,fatal_neterrors=none,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.30,local_lock=none,addr=192.168.1.80)
192.168.1.80:/volume1/pve-backup on /mnt/pve/nas-backup type nfs4 (rw,relatime,vers=4.1,rsize=262144,wsize=262144,namlen=255,hard,fatal_neterrors=none,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.30,local_lock=none,addr=192.168.1.80)
```

Komentarz: udziały zamontowano protokołem NFS w wersji 4.1 (vers=4.1)
przez TCP, z uwierzytelnianiem AUTH_SYS (sec=sys), co potwierdza
decyzję ADR-004.

---

## Listing 5.8a. Konfiguracja magazynów danych

```console
root@homelab:~# cat /etc/pve/storage.cfg
dir: local
        path /var/lib/vz
        content backup,iso,vztmpl,import

lvmthin: local-lvm
        thinpool data
        vgname pve
        content rootdir,images

nfs: nas-vm
        export /volume1/pve-vm
        path /mnt/pve/nas-vm
        server 192.168.1.80
        content iso,vztmpl,images,snippets
        options vers=4.1
        prune-backups keep-all=1

nfs: nas-backup
        export /volume1/pve-backup
        path /mnt/pve/nas-backup
        server 192.168.1.80
        content backup
        options vers=4.1
        prune-backups keep-all=1
```

Komentarz: plik opisuje cztery magazyny danych: lokalny katalog (local),
lokalną pulę LVM-thin na dyski maszyn (local-lvm) oraz dwa udziały NFS
na Synology. Magazyn nas-vm przechowuje dyski środowisk, obrazy ISO,
szablony i snippety cloud-init, a nas-backup wyłącznie kopie zapasowe.
Dla obu udziałów wymuszono protokół NFS w wersji 4.1.
---

## Listing 5.9. Konfiguracja zadania kopii zapasowych

```console
root@homelab:~# cat /etc/pve/jobs.cfg
vzdump: backup-4e5d5c3c-d112
        schedule 02:00
        all 1
        compress zstd
        enabled 1
        fleecing 0
        mailnotification failure
        mailto admin@example.com
        mode snapshot
        notes-template {{guestname}}
        notification-mode legacy-sendmail
        prune-backups keep-daily=7,keep-weekly=4
        storage nas-backup
```

Komentarz: zadanie wykonuje codziennie o 2:00 kopię wszystkich maszyn
w trybie snapshot z kompresją ZSTD na magazyn nas-backup. Polityka
retencji przechowuje 7 kopii dziennych i 4 tygodniowe. Konfiguracja
przechowywana jest w pliku tekstowym, co pozwala ją wersjonować
i odtworzyć niezależnie od interfejsu graficznego.

---

# Etap 2: Stacja robocza i repozytorium IaC

## Listing 5.10. Dystrybucja Linux w podsystemie WSL2

```console
PS C:\WINDOWS\system32> wsl -l -v
  NAME      STATE           VERSION
* Debian    Stopped         2
```

Komentarz: stacja robocza korzysta z dystrybucji Debian uruchomionej
w podsystemie WSL w wersji 2.

---

## Listing 5.11. Wersja systemu stacji roboczej

```console
keinshur@kv235-965:~$ cat /etc/os-release
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
NAME="Debian GNU/Linux"
VERSION_ID="13"
VERSION="13 (trixie)"
VERSION_CODENAME=trixie
DEBIAN_VERSION_FULL=13.7
ID=debian
```

Komentarz: stacja sterująca działa na tej samej wersji systemu
(Debian 13) co zarządzane serwery, co eliminuje różnice w wersjach
narzędzi i pakietów.

---

## Listing 5.12. Wersje podstawowych narzędzi stacji roboczej

```console
keinshur@kv235-965:~$ git --version
git version 2.47.3
keinshur@kv235-965:~$ python3 --version
Python 3.13.5
keinshur@kv235-965:~$ pipx --version
1.7.1
keinshur@kv235-965:~$ keychain --version
 * keychain 2.8.5 ~ http://www.funtoo.org
```

Komentarz: zestaw narzędzi bazowych: system kontroli wersji Git,
interpreter Python wraz z menedżerem pipx oraz keychain do zarządzania
odblokowanymi kluczami SSH.

---

## Listing 5.13. Globalna konfiguracja Git

```console
keinshur@kv235-965:~$ git config --global --list
user.name=Rafał Ciereszko
user.email=144132599+BrotherFromMother@users.noreply.github.com
init.defaultbranch=main
core.autocrlf=input
```

Komentarz: jako adres autora commitów użyto adresu noreply serwisu
GitHub, co zapobiega ujawnieniu prywatnego adresu e-mail w historii
repozytorium.

---

## Listing 5.14. Weryfikacja uwierzytelniania kluczem SSH w serwisie GitHub

```console
keinshur@kv235-965:~$ ssh -T git@github.com
The authenticity of host 'github.com (140.82.121.3)' can't be established.
ED25519 key fingerprint is SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'github.com' (ED25519) to the list of known hosts.
Enter passphrase for key '/home/keinshur/.ssh/github_ed25519':
Hi BrotherFromMother! You've successfully authenticated, but GitHub does not provide shell access.
```

Komentarz: uwierzytelnianie odbywa się kluczem Ed25519 zabezpieczonym
hasłem. Odcisk klucza serwera zweryfikowano z wartością opublikowaną
przez GitHub.

---

## Listing 5.15. Logowanie do hypervisora kluczem SSH

```console
keinshur@kv235-965:~$ ssh homelab 'hostname && pveversion'
homelab
pve-manager/9.2.21/4f6e0ac86f9e8c7f (running kernel: 7.0.14-24-pve)
```

Komentarz: stacja robocza łączy się z hypervisorem kluczem Ed25519
zabezpieczonym hasłem, bez przesyłania hasła konta przez sieć.
Klucz do serwerów jest oddzielony od klucza używanego w serwisie
GitHub, a odblokowane klucze przechowuje w pamięci narzędzie keychain.

---

# Do uzupełnienia

- [ ] Listing 5.1: ponownie uruchomić `apt update` na Proxmoxie i wkleić wynik
- [ ] Opcjonalnie: `pveversion -v` po restarcie (skrócona lista komponentów)
- [ ] Konfiguracja magazynów: `cat /etc/pve/storage.cfg`
- [ ] Opcjonalnie: log zadania pobrania ISO z potwierdzeniem sumy SHA-512
- [ ] Etap 2.3: logowanie do Proxmoxa kluczem SSH (`ssh homelab 'hostname && pveversion'`)