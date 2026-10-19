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

## Listing 5.16. Wersje narzędzi Infrastructure as Code

```console
keinshur@kv235-965:~$ terraform version
Terraform v1.16.6
on linux_amd64
keinshur@kv235-965:~$ ansible --version
ansible [core 2.21.5]
  executable location = /home/keinshur/.local/bin/ansible
  python version = 3.13.5
keinshur@kv235-965:~$ ansible-lint --version
ansible-lint 26.10.1 using ansible-core:2.21.5
```

Komentarz: Terraform zainstalowano z oficjalnego repozytorium HashiCorp
jako pakiet systemowy, a Ansible i ansible-lint przez pipx, w izolowanym
środowisku Pythona.

---

## Listing 5.17. Uprawnienia konta automatyzacji w Proxmox VE

```console
root@homelab:~# pveum acl list
┌──────┬───────────────┬───────┬───────────────────┬───────────┐
│ path │ roleid        │ type  │ ugid              │ propagate │
╞══════╪═══════════════╪═══════╪═══════════════════╪═══════════╡
│ /    │ TerraformProv │ user  │ terraform@pve     │ 1         │
├──────┼───────────────┼───────┼───────────────────┼───────────┤
│ /    │ TerraformProv │ token │ terraform@pve!iac │ 1         │
└──────┴───────────────┴───────┴───────────────────┴───────────┘
```

Komentarz: rola TerraformProv z ograniczonym zestawem uprawnień została
przypisana zarówno użytkownikowi, jak i tokenowi z separacją uprawnień.
Efektywne uprawnienia tokenu stanowią część wspólną obu przypisań.
Zakres („/”) zostanie zawężony w etapie 9 (ADR-008).

---

## Listing 5.18. Weryfikacja tokenu API bez udziału Terraforma

```console
keinshur@kv235-965:~$ source ~/.config/homelab/proxmox.env
keinshur@kv235-965:~$ curl -s -k -H "Authorization: PVEAPIToken=$PROXMOX_VE_API_TOKEN" "${PROXMOX_VE_ENDPOINT}api2/json/version" | jq
{
  "data": {
    "version": "9.2.21",
    "repoid": "4f6e0ac86f9e8c7f",
    "release": "9.2"
  }
}
```

Komentarz: token jest przekazywany przez zmienną środowiskową, dzięki
czemu sekret nie pojawia się w poleceniu ani w historii terminala.
Opcja -k wyłącza weryfikację certyfikatu samopodpisanego (ADR-008).

---

## Listing 5.19. Inicjalizacja konfiguracji Terraform

```console
keinshur@kv235-965:~/…/infra/terraform/platform$ terraform init
Initializing the backend...

Initializing provider plugins...
- Finding latest version of bpg/proxmox...
- Installing bpg/proxmox v0.117.0...
- Installed bpg/proxmox v0.117.0 (self-signed, key ID 0B3405B36193A495)
...
Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above.
...
Terraform has been successfully initialized!
```

Komentarz: Terraform pobrał provider bpg/proxmox z publicznego rejestru,
zweryfikował jego podpis kluczem autorów i zapisał wybraną wersję wraz
z sumami kontrolnymi w pliku blokady.

---

## Listing 5.20. Plan zmian: utworzenie puli zasobów

```console
keinshur@kv235-965:~/…/infra/terraform/platform$ terraform plan
data.proxmox_version.pve: Reading...
data.proxmox_virtual_environment_nodes.all: Reading...
data.proxmox_version.pve: Read complete after 0s [id=version]
data.proxmox_virtual_environment_nodes.all: Read complete after 0s [id=nodes]

Terraform will perform the following actions:

  # proxmox_virtual_environment_pool.portal will be created
  + resource "proxmox_virtual_environment_pool" "portal" {
      + comment = "Srodowiska platformy samoobslugowej (zarzadzane przez Terraform)"
      + id      = (known after apply)
      + members = (known after apply)
      + pool_id = "portal"
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + nodes       = [
      + "homelab",
    ]
  + portal_pool = "portal"
  + pve_version = "9.2.21"
```

Komentarz: na podstawie deklaratywnego opisu Terraform samodzielnie
wyznaczył zmianę potrzebną do osiągnięcia stanu docelowego. Polecenie
plan nie modyfikuje infrastruktury.

---

## Listing 5.21. Zastosowanie zapisanego planu

```console
keinshur@kv235-965:~/…/infra/terraform/platform$ terraform plan -out=portal.tfplan
...
Saved the plan to: portal.tfplan
keinshur@kv235-965:~/…/infra/terraform/platform$ terraform apply portal.tfplan
proxmox_virtual_environment_pool.portal: Creating...
proxmox_virtual_environment_pool.portal: Creation complete after 0s [id=portal]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

nodes = tolist([
  "homelab",
])
portal_pool = "portal"
pve_version = "9.2.21"
```

Komentarz: zastosowanie zapisanego planu gwarantuje wykonanie dokładnie
tych zmian, które zostały wcześniej przejrzane.

---

## Listing 5.22. Stan infrastruktury i idempotentność

```console
keinshur@kv235-965:~/…/infra/terraform/platform$ terraform state list
data.proxmox_version.pve
data.proxmox_virtual_environment_nodes.all
proxmox_virtual_environment_pool.portal
keinshur@kv235-965:~/…/infra/terraform/platform$ terraform plan
...
proxmox_virtual_environment_pool.portal: Refreshing state... [id=portal]
...
No changes. Your infrastructure matches the configuration.
```

Komentarz: ponowne wyznaczenie planu po zastosowaniu zmian nie wykazuje
różnic między konfiguracją a stanem rzeczywistym, co potwierdza
idempotentność rozwiązania.

---

## Listing 5.22a. Usunięcie zasobu: pełny cykl życia puli

```console
keinshur@kv235-965:~/…/infra/terraform/platform$ terraform destroy
...
Destroy complete! Resources: 1 destroyed.
```

Komentarz: polecenie destroy usuwa wyłącznie zasoby zarządzane przez
Terraform i zapisane w jego stanie; źródła danych nie są usuwane.
Ponowne wykonanie apply odtwarza pulę z kodu, co potwierdza, że zasób
może zostać w każdej chwili odtworzony na podstawie konfiguracji.

---

## Listing 5.23. Wartości wyjściowe w formacie JSON

```console
keinshur@kv235-965:~/…/infra/terraform/platform$ terraform output -json
{
  "nodes": {
    "sensitive": false,
    "type": [
      "list",
      "string"
    ],
    "value": [
      "homelab"
    ]
  },
  "portal_pool": {
    "sensitive": false,
    "type": "string",
    "value": "portal"
  },
  "pve_version": {
    "sensitive": false,
    "type": "string",
    "value": "9.2.21"
  }
}
keinshur@kv235-965:~/…/infra/terraform/platform$ terraform output -json | jq -r '.nodes.value[0]'
homelab
```

Komentarz: wartości wyjściowe w formacie JSON mogą być automatycznie
odczytywane przez inne programy, w szczególności przez platformę
samoobsługową i narzędzie Ansible.

---

## Listing 5.24. Weryfikacja konfiguracji i połączenia Ansible

```console
keinshur@kv235-965:~/…/infra/ansible$ ansible --version | grep "config file"
  config file = /home/keinshur/projekty/Praca_Inzynierska/infra/ansible/ansible.cfg
keinshur@kv235-965:~/…/infra/ansible$ ansible-inventory --graph
@all:
  |--@ungrouped:
  |--@hypervisors:
  |  |--homelab
keinshur@kv235-965:~/…/infra/ansible$ ansible all -m ansible.builtin.ping
homelab | SUCCESS =>
    ansible_facts:
        discovered_interpreter_python: /usr/bin/python3.13
    changed: false
    ping: pong
```

Komentarz: Ansible korzysta z konfiguracji zapisanej w repozytorium,
a moduł ping potwierdza połączenie SSH z uwierzytelnianiem kluczem
i dostępność interpretera Python na zarządzanym hoście.

---

## Listing 5.25. Pierwszy playbook i jego weryfikacja narzędziem ansible-lint

```console
keinshur@kv235-965:~/…/infra/ansible$ ansible-playbook playbooks/sprawdz-hypervisor.yml

PLAY [Weryfikacja połączenia z hypervisorem] ***********************************

TASK [Gathering Facts] *********************************************************
ok: [homelab]

TASK [Wyświetl system operacyjny i wersję jądra] *******************************
ok: [homelab] =>
    msg: 'homelab: Debian 13.7, jądro 7.0.14-24-pve, RAM 31961 MB'

PLAY RECAP *********************************************************************
homelab                    : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

keinshur@kv235-965:~/…/infra/ansible$ ansible-lint playbooks/sprawdz-hypervisor.yml
Passed: 0 failure(s), 0 warning(s) in 1 files processed of 1 encountered. Last profile that met the validation criteria was 'production'.
```

Komentarz: playbook odczytuje fakty o hoście bez wprowadzania zmian
(changed=0) i spełnia najbardziej rygorystyczny profil reguł
ansible-lint (production).

---

# Etap 3: Szablon maszyny wirtualnej jako kod

## Listing 5.33. Odczyt sumy kontrolnej przypiętego wydania obrazu

```console
keinshur@kv235-965:~$ curl -s https://cloud.debian.org/images/cloud/trixie/20261017-2634/SHA512SUMS | grep 'genericcloud-amd64-20261017-2634.qcow2'
ec584ccabfef7120b4c4f7482adf0e615894d9292cedec446b64194b951ebe5dd97c336b5dcbae458333764b0edd516334506017f33c4f2020ef8d38b569ffe3  debian-13-genericcloud-amd64-20261017-2634.qcow2
```

Komentarz: suma SHA-512 obrazu pobierana jest z pliku SHA512SUMS
opublikowanego przez projekt Debian dla konkretnego wydania. Przypięcie
wydania z datą zamiast katalogu latest zapewnia powtarzalność (ADR-009).

---

## Listing 5.34. Odmowa pobrania obrazu kontem terraform@pve

```console
keinshur@kv235-965:~/…/infra/terraform/platform$ terraform apply tfplan
proxmox_download_file.debian13: Creating...
╷
│ Error: Error initiating file download
│
│ Could not get file metadata, unexpected error: error fetching
│ metadata from download url, unexpected error in GetQueryURLMetadata:
│ error retrieving URL metadata for
│ "https://cloud.debian.org/images/cloud/trixie/20261017-2634/debian-13-genericcloud-amd64-20261017-2634.qcow2":
│ received an HTTP 403 response - Reason: Permission check failed
╵
```

Komentarz: rola TerraformProv nie obejmuje uprawnień do pobierania plików
z dowolnych adresów URL przez hypervisor. Analiza wymaganych uprawnień
doprowadziła do wydzielenia osobnego konta z uprawnieniem
Sys.AccessNetwork (ADR-010).

---


## Listing 5.34a. Przypisania ról kont automatyzacji


```console
keinshur@kv235-965:~/projekty/Praca_Inzynierska$ ssh homelab 'pveum acl list'
┌────────────────┬─────────────────┬───────┬──────────────────────────┬───────────┐
│ path           │ roleid          │ type  │ ugid                     │ propagate │
╞════════════════╪═════════════════╪═══════╪══════════════════════════╪═══════════╡
│ /              │ TerraformProv   │ user  │ terraform@pve            │ 1         │
├────────────────┼─────────────────┼───────┼──────────────────────────┼───────────┤
│ /              │ TerraformProv   │ token │ terraform@pve!iac        │ 1         │
├────────────────┼─────────────────┼───────┼──────────────────────────┼───────────┤
│ /nodes/homelab │ ImageDownloader │ user  │ terraform-images@pve     │ 1         │
├────────────────┼─────────────────┼───────┼──────────────────────────┼───────────┤
│ /nodes/homelab │ ImageDownloader │ token │ terraform-images@pve!img │ 1         │
├────────────────┼─────────────────┼───────┼──────────────────────────┼───────────┤
│ /storage/local │ ImageDownloader │ user  │ terraform-images@pve     │ 1         │
├────────────────┼─────────────────┼───────┼──────────────────────────┼───────────┤
│ /storage/local │ ImageDownloader │ token │ terraform-images@pve!img │ 1         │
└────────────────┴─────────────────┴───────┴──────────────────────────┴───────────┘
keinshur@kv235-965:~/projekty/Praca_Inzynierska$

```

Komentarz: konto terraform-images@pve z rolą ImageDownloader ma
uprawnienia wyłącznie na węźle homelab i magazynie local, w odróżnieniu
od konta terraform@pve przypisanego na ścieżce „/”. Każda rola jest
przypisana zarówno użytkownikowi, jak i jego tokenowi, ponieważ tokeny
z separacją uprawnień nie dziedziczą uprawnień użytkownika (ADR-010).

---

## Listing 5.35. Pobranie obrazu przez API osobnym kontem

```console
keinshur@kv235-965:~/…/infra/terraform/images$ terraform apply tfplan
...
proxmox_download_file.debian13: Creation complete after 6m31s [id=local:import/debian-13-genericcloud-amd64-20261017-2634.qcow2]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

debian13_image_id = "local:import/debian-13-genericcloud-amd64-20261017-2634.qcow2"
keinshur@kv235-965:~/…/infra/terraform/images$ ssh homelab 'pvesm list local --content import'
Volid                                                         Format  Type           Size VMID
local:import/debian-13-genericcloud-amd64-20261017-2634.qcow2 qcow2   import    342818816
```

Komentarz: Proxmox pobrał obraz bezpośrednio z serwera Debiana i
zweryfikował jego sumę SHA-512, a operację wykonało konto
terraform-images@pve z rolą ograniczoną do magazynu local i węzła
homelab. Obraz nie był przesyłany przez stację roboczą ani przez SSH.

---

## Listing 5.36. Zmiana parametru zasobu bez jego odtwarzania

```console
keinshur@kv235-965:~/…/infra/terraform/images$ terraform plan
proxmox_download_file.debian13: Refreshing state... [id=local:import/debian-13-genericcloud-amd64-20261017-2634.qcow2]

Terraform will perform the following actions:

  # proxmox_download_file.debian13 will be updated in-place
  ~ resource "proxmox_download_file" "debian13" {
        id                  = "local:import/debian-13-genericcloud-amd64-20261017-2634.qcow2"
      ~ upload_timeout      = 600 -> 1800
        # (11 unchanged attributes hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

Komentarz: plan rozróżnia modyfikację zasobu w miejscu (~) od jego
zastąpienia (-/+). Zwiększenie limitu czasu pobierania nie wymaga
ponownego pobrania obrazu, co można zweryfikować przed wykonaniem zmiany.

---

## Listing 5.37. Konfiguracja szablonu maszyny w Proxmox VE

```console
keinshur@kv235-965:~$ ssh homelab 'qm config 9000'
acpi: 1
agent: enabled=0,fstrim_cloned_disks=0,type=virtio
balloon: 0
bios: seabios
boot: order=scsi0;net0
cores: 2
cpu: x86-64-v2-AES
description: Szablon Debian 13 (genericcloud), zarzadzany przez Terraform
ide2: nas-vm:9000/vm-9000-cloudinit.qcow2,media=cdrom
ipconfig0: ip=dhcp
keyboard: en-us
machine: q35
memory: 2048
meta: creation-qemu=11.0.3,ctime=1792427361
name: tpl-debian13
net0: virtio=BC:24:11:90:CD:A3,bridge=vmbr0,firewall=0
numa: 0
onboot: 1
ostype: l26
protection: 0
scsi0: nas-vm:9000/base-9000-disk-0.qcow2,aio=io_uring,backup=1,cache=none,discard=on,iothread=1,replicate=1,size=10G,ssd=0
scsihw: virtio-scsi-single
serial0: socket
smbios1: uuid=b7e7b61f-d15c-4a1d-bc5f-884a4a6a4322
sockets: 1
tablet: 1
tags: debian13;template;terraform
template: 1
vmgenid: 3c40badb-2f2a-42d0-a9dd-a4f8491e1657
```

Komentarz: deklaracja z pliku template.tf została przełożona na
konfigurację maszyny w Proxmox VE: dysk zaimportowany z obrazu
na magazyn nas-vm w formacie qcow2 (przedrostek base- oznacza dysk
szablonu), napęd cloud-init (ide2), port szeregowy wymagany przez
obrazy chmurowe Debiana oraz oznaczenie template: 1.

---

## Listing 5.38. Pliki szablonu na magazynie sieciowym

```console
keinshur@kv235-965:~$ ssh homelab 'pvesm list nas-vm --vmid 9000'
Volid                               Format  Type             Size VMID
nas-vm:9000/base-9000-disk-0.qcow2  qcow2   images    10737418240 9000
nas-vm:9000/vm-9000-cloudinit.qcow2 qcow2   images        4194304 9000
```

Komentarz: szablon składa się z dysku systemowego o rozmiarze wirtualnym
10 GiB oraz dysku cloud-init. Format qcow2 przydziela miejsce w miarę
zapisu, więc faktyczne zajęcie magazynu jest znacznie mniejsze od
rozmiaru wirtualnego.

---

## Listing 5.39. Odrzucenie wskazania magazynu dla klonu połączonego

```console
keinshur@kv235-965:~/…/infra/terraform/platform$ terraform apply tfplan
proxmox_virtual_environment_vm.test_clone: Creating...
╷
│ Error: VM clone
│
│ All attempts fail:
│ #1: error cloning VM: received an HTTP 500 response - Reason: parameter 'storage' not
│ allowed for linked clones
╵
```

Komentarz: klon połączony zapisuje wyłącznie różnice względem dysku
szablonu, dlatego musi znajdować się w tym samym magazynie co szablon.
Proxmox VE nie dopuszcza wskazania magazynu docelowego; parametr
datastore_id usunięto z bloku clone.

---

## Listing 5.40. Utworzenie maszyny jako klonu połączonego

```console
keinshur@kv235-965:~/…/infra/terraform/platform$ terraform apply tfplan
proxmox_virtual_environment_vm.test_clone: Creating...
proxmox_virtual_environment_vm.test_clone: Still creating... [00m10s elapsed]
proxmox_virtual_environment_vm.test_clone: Creation complete after 13s [id=2999]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

Komentarz: utworzenie maszyny jako klonu połączonego trwało 13 sekund,
ponieważ nie wymaga kopiowania dysku szablonu.

---

## Listing 5.41. Weryfikacja konfiguracji wykonanej przez cloud-init

```console
keinshur@kv235-965:~$ ssh -i ~/.ssh/homelab_ed25519 ansible@192.168.1.200 'cloud-init status --wait; echo "---"; hostname; id; echo "---"; ip -br a; echo "---"; df -h /; echo "---"; sudo -n true && echo "sudo bez hasla: OK"'
status: done
---
test-debian13
uid=1000(ansible) gid=1000(ansible) groups=1000(ansible),4(adm),20(dialout),24(cdrom),25(floppy),27(sudo),29(audio),30(dip),44(video),46(plugdev)
---
lo               UNKNOWN        127.0.0.1/8 ::1/128
eth0             UP             192.168.1.200/24 fe80::be24:11ff:fe91:915/64
---
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1       9.7G  848M  8.4G   9% /
---
sudo bez hasla: OK
```

Komentarz: przy pierwszym uruchomieniu cloud-init ustawił nazwę hosta
i statyczny adres IP, utworzył konto ansible z kluczem publicznym
i uprawnieniami sudo oraz powiększył partycję systemową do rozmiaru
dysku. Logowanie odbyło się kluczem, bez ręcznej konfiguracji maszyny.

---

## Listing 5.42. Przejęcie nowej maszyny przez Ansible

```console
keinshur@kv235-965:~/…/infra/ansible$ ansible all -i "192.168.1.200," -u ansible --private-key ~/.ssh/homelab_ed25519 -m ansible.builtin.ping
192.168.1.200 | SUCCESS =>
    ansible_facts:
        discovered_interpreter_python: /usr/bin/python3.13
    changed: false
    ping: pong
keinshur@kv235-965:~/…/infra/ansible$ ansible all -i "192.168.1.200," -u ansible --private-key ~/.ssh/homelab_ed25519 -b -m ansible.builtin.command -a "whoami"
192.168.1.200 | CHANGED | rc=0 >>
root
```

Komentarz: Ansible połączył się z maszyną bezpośrednio po jej utworzeniu
i wykonał polecenie z uprawnieniami administratora (-b), co zamyka
łańcuch Terraform, cloud-init, Ansible. Moduł command zawsze zgłasza
zmianę (CHANGED), ponieważ Ansible nie może ocenić skutków dowolnego
polecenia.

---

## Listing 5.43. Usunięcie maszyny przez usunięcie jej z kodu

```console
keinshur@kv235-965:~/…/infra/terraform/platform$ terraform plan -out=tfplan
...
Plan: 0 to add, 0 to change, 1 to destroy.
keinshur@kv235-965:~/…/infra/terraform/platform$ terraform apply tfplan
proxmox_virtual_environment_vm.test_clone: Destroying... [id=2999]
proxmox_virtual_environment_vm.test_clone: Destruction complete after 2s

Apply complete! Resources: 0 added, 0 changed, 1 destroyed.
keinshur@kv235-965:~$ ssh homelab 'qm list'
      VMID NAME                 STATUS     MEM(MB)    BOOTDISK(GB) PID
      9000 tpl-debian13         stopped    2048              10.00 0
```

Komentarz: po usunięciu pliku test-vm.tf z konfiguracji Terraform
wyznaczył usunięcie maszyny i wykonał je w 2 sekundy, nie naruszając
szablonu ani puli zasobów.

---

## Listingi kodu etapu 3 (z repozytorium)

| Listing | Plik |
|---|---|
| 5.44 | infra/terraform/images/images.tf |
| 5.45 | infra/terraform/images/variables.tf |
| 5.46 | infra/terraform/images/terraform.tfvars |
| 5.47 | infra/terraform/platform/template.tf |
| 5.48 | infra/terraform/platform/test-vm.tf (z historii Git, commit „Maszyna testowa etapu 3”) |

## Do uzupełnienia (etap 3)

- [x] Listing: `pveum acl list` z przypisaniami roli ImageDownloader (listing 5.34a)
- [ ] Zrzuty etapu 3: lista wydań obrazów na cloud.debian.org, zakładka Import magazynu local, szablon 9000 i jego Hardware, maszyna 2999 w puli portal z zakładką Cloud-Init, zadania wykonane przez terraform@pve

---

## Listingi kodu (z repozytorium)

Pliki konfiguracji wstawiane do pracy bezpośrednio z repozytorium:

| Listing | Plik |
|---|---|
| 5.26 | infra/terraform/platform/versions.tf |
| 5.27 | infra/terraform/platform/providers.tf |
| 5.28 | infra/terraform/platform/main.tf |
| 5.29 | infra/terraform/platform/outputs.tf |
| 5.30 | infra/ansible/ansible.cfg |
| 5.31 | infra/ansible/inventories/hosts.yml |
| 5.32 | infra/ansible/playbooks/sprawdz-hypervisor.yml |

---

# Do uzupełnienia

- [x] Listing 5.1: wynik `apt update` po zmianie repozytoriów
- [x] Konfiguracja magazynów: `cat /etc/pve/storage.cfg` (listing 5.8a)
- [x] Logowanie do Proxmoxa kluczem SSH (listing 5.15)
- [x] Usunięcie puli: `terraform destroy` (listing 5.22a)
- [ ] Opcjonalnie: pełny wynik `terraform destroy` z planem usunięcia
- [ ] Opcjonalnie: `pveversion -v` po restarcie (skrócona lista komponentów)
- [ ] Opcjonalnie: log zadania pobrania ISO z potwierdzeniem sumy SHA-512
- [ ] Opcjonalnie: struktura repozytorium (`tree -a -I .git`)
- [ ] Zrzuty etapu 2: VS Code z WSL, rola TerraformProv, token iac, pula portal, strona providera w rejestrze
