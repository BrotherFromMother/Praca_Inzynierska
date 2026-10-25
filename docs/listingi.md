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

# Etap 4: Mechanizm tworzenia i konfiguracji maszyn

## Listing 5.49. Walidacja modułu Terraform

```console
keinshur@kv235-965:~/…/infra/terraform/modules/portal-vm$ terraform init
...
- Installed bpg/proxmox v0.117.0 (self-signed, key ID 0B3405B36193A495)
...
Terraform has been successfully initialized!
keinshur@kv235-965:~/…/infra/terraform/modules/portal-vm$ terraform validate
Success! The configuration is valid.
```

Komentarz: moduł zawiera wyłącznie deklarację wymaganego providera,
zmienne z walidacją, zasób maszyny i wartości wyjściowe. Nie konfiguruje
połączenia z Proxmox VE; otrzymuje je od konfiguracji, która go wywołuje.

---

## Listing 5.50. Logowanie do nowej maszyny kluczem automatyzacji

```console
keinshur@kv235-965:~/…/infra/terraform/environments$ ssh -i ~/.ssh/portal_automation_ed25519 -o StrictHostKeyChecking=accept-new ansible@192.168.1.201 'hostname && cloud-init status --wait'
Warning: Permanently added '192.168.1.201' (ED25519) to the list of known hosts.
env-001
...............................................................status: done
```

Komentarz: maszyna utworzona z modułu w osobnym workspace przyjmuje
logowanie kluczem automatyzacji (ADR-014). Opcja accept-new
automatycznie zapisała klucz nowego serwera, a polecenie
cloud-init status --wait poczekało na zakończenie pierwszej
konfiguracji.

---

## Listing 5.51. Kolekcja Ansible zadeklarowana w requirements.yml

```console
keinshur@kv235-965:~/…/infra/ansible$ ansible-galaxy collection list community.general

# /home/keinshur/.local/share/pipx/venvs/ansible/lib/python3.13/site-packages/ansible_collections
Collection        Version
----------------- -------
community.general 13.5.0
```

Komentarz: kolekcja community.general była dostępna wyłącznie
w środowisku Pythona narzędzia Ansible, a nie w środowisku ansible-lint.
Jawna instalacja z pliku requirements.yml do katalogu
~/.ansible/collections udostępnia ją obu narzędziom i zapewnia
powtarzalność na innych maszynach.

---

## Listing 5.52. Pierwsze wykonanie roli base

```console
keinshur@kv235-965:~/…/infra/ansible$ time ansible-playbook -i "192.168.1.201," -u ansible --private-key ~/.ssh/portal_automation_ed25519 playbooks/provision.yml

PLAY [Konfiguracja środowiska użytkownika] *************************************

TASK [Gathering Facts] *********************************************************
ok: [192.168.1.201]

TASK [base : Zaktualizuj listę pakietów i system] ******************************
ok: [192.168.1.201]

TASK [base : Zainstaluj pakiety bazowe] ****************************************
changed: [192.168.1.201]

TASK [base : Ustaw strefę czasową] *********************************************
changed: [192.168.1.201]

TASK [base : Sprawdź, czy aktualizacja wymaga ponownego uruchomienia] **********
ok: [192.168.1.201]

TASK [base : Uruchom ponownie system, jeśli wymaga tego aktualizacja] **********
skipping: [192.168.1.201]

PLAY RECAP *********************************************************************
192.168.1.201              : ok=5    changed=2    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0

real    0m25.298s
```

Komentarz: rola zainstalowała pakiety bazowe i ustawiła strefę czasową.
Restart został pominięty, ponieważ aktualizacja nie wymagała nowego
jądra (warunek when).

---

## Listing 5.53. Idempotentność ról base i docker

```console
keinshur@kv235-965:~/…/infra/ansible$ ansible-playbook -i "192.168.1.201," -u ansible --private-key ~/.ssh/portal_automation_ed25519 playbooks/provision.yml
...
PLAY RECAP *********************************************************************
192.168.1.201              : ok=11   changed=0    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
```

Komentarz: ponowne wykonanie obu ról na skonfigurowanej maszynie nie
wprowadza żadnych zmian (changed=0), co potwierdza idempotentność.

---

## Listing 5.54. Pierwsze wykonanie roli docker

```console
keinshur@kv235-965:~/…/infra/ansible$ time ansible-playbook -i "192.168.1.201," -u ansible --private-key ~/.ssh/portal_automation_ed25519 playbooks/provision.yml
...
TASK [docker : Pobierz klucz GPG repozytorium Dockera] *************************
changed: [192.168.1.201]

TASK [docker : Dodaj repozytorium Dockera] *************************************
changed: [192.168.1.201]

TASK [docker : Zainstaluj pakiety Dockera] *************************************
changed: [192.168.1.201]

TASK [docker : Uruchom usługę Docker i włącz ją przy starcie systemu] **********
ok: [192.168.1.201]

TASK [docker : Dodaj użytkowników do grupy docker] *****************************
changed: [192.168.1.201] => (item=ansible)

PLAY RECAP *********************************************************************
192.168.1.201              : ok=11   changed=4    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0

real    4m11.390s
```

Komentarz: instalacja Dockera z oficjalnego repozytorium stanowi
dominującą część czasu konfiguracji maszyny (ok. 4 min wobec 25 s dla
roli base), co wskazuje wypiekanie obrazu z preinstalowanym Dockerem
jako kierunek optymalizacji.

---

## Listing 5.55. Weryfikacja działania Dockera

```console
keinshur@kv235-965:~$ ssh -i ~/.ssh/portal_automation_ed25519 ansible@192.168.1.201 'docker --version && docker compose version && docker run --rm hello-world'
Docker version 29.9.1, build dfc520d
Docker Compose version v5.6.0
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
...
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

Komentarz: konto ansible uruchamia kontenery bez sudo dzięki
członkostwu w grupie docker. Obraz został pobrany z rejestru Docker Hub,
ponieważ nie było go lokalnie.

---

## Listing 5.56. Kod wyjścia cloud-init przy zakończeniu z ostrzeżeniami

```console
keinshur@kv235-965:~$ ssh -i ~/.ssh/portal_automation_ed25519 ansible@192.168.1.202 'uptime; cloud-init status --long'
 12:48:12 up 7 min,  1 user,  load average: 0.11, 0.12, 0.05
status: done
extended_status: degraded done
...
recoverable_errors:
DEPRECATED:
        - 'user' of type string is deprecated in 22.2 and scheduled to be removed in 27.2. Use 'users' list instead.
keinshur@kv235-965:~$ ssh -i ~/.ssh/portal_automation_ed25519 ansible@192.168.1.202 'cloud-init status --wait; echo "kod wyjścia: $?"'
status: done
kod wyjścia: 2
```

Komentarz: cloud-init zakończył pracę z ostrzeżeniem wynikającym
z formatu konfiguracji generowanej przez Proxmox VE i zwrócił kod 2.
Pierwsza wersja skryptu traktowała każdy kod różny od 0 jako błąd;
poprawiona wersja uznaje kody 0 i 2 za zakończenie i ogranicza czas
oczekiwania do 10 minut.

---

## Listing 5.57. Wznowienie przerwanego procesu

```console
keinshur@kv235-965:~/projekty/Praca_Inzynierska$ ./infra/scripts/provision.sh env-002 2002 192.168.1.202
==> [1/3] Terraform: tworzenie maszyny env-002
module.env.proxmox_virtual_environment_vm.this: Refreshing state... [id=2002]

No changes. Your infrastructure matches the configuration.
...
==> [2/3] Oczekiwanie na SSH i zakończenie cloud-init

==> [3/3] Ansible: konfiguracja systemu
...
PLAY RECAP *********************************************************************
192.168.1.202              : ok=11   changed=6    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0

==> Środowisko env-002 gotowe: ansible@192.168.1.202
    Terraform:  1 s
    cloud-init: 1 s
    Ansible:    404 s
    Razem:      406 s
```

Komentarz: ponowne uruchomienie skryptu po przerwaniu kontynuuje proces
od niewykonanego kroku: Terraform nie tworzy istniejącej maszyny,
a Ansible wykonuje wyłącznie brakującą konfigurację. Właściwość ta
wynika z idempotentności obu narzędzi.

---

## Listing 5.58. Pełne utworzenie maszyny jednym poleceniem

```console
keinshur@kv235-965:~/projekty/Praca_Inzynierska$ ./infra/scripts/provision.sh env-003 2003 192.168.1.203
...
PLAY RECAP *********************************************************************
192.168.1.203              : ok=11   changed=7    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0

==> Środowisko env-003 gotowe: ansible@192.168.1.203
    Terraform:  4 s
    cloud-init: 22 s
    Ansible:    431 s
    Razem:      457 s
```

Komentarz: utworzenie i pełna konfiguracja maszyny od zera trwały
457 s. Po wyłączeniu aktualizacji pakietów w cloud-init (upgrade = false)
faza cloud-init skróciła się do 22 s, a aktualizacja systemu jest
wykonywana jednokrotnie, przez rolę base.

---

## Listing 5.59. Usunięcie maszyny wraz z jej stanem

```console
keinshur@kv235-965:~/projekty/Praca_Inzynierska$ ./infra/scripts/deprovision.sh env-001
...
Plan: 0 to add, 0 to change, 1 to destroy.
...
module.env.proxmox_virtual_environment_vm.this: Destroying... [id=2001]
module.env.proxmox_virtual_environment_vm.this: Destruction complete after 1s

Destroy complete! Resources: 1 destroyed.
Switched to workspace "default".
Deleted workspace "env-001"!
==> Środowisko env-001 usunięte w 1 s
keinshur@kv235-965:~/projekty/Praca_Inzynierska$ ssh homelab 'qm list'
      VMID NAME                 STATUS     MEM(MB)    BOOTDISK(GB) PID
      9000 tpl-debian13         stopped    2048              10.00 0
```

Komentarz: skrypt usuwa maszynę, jej workspace oraz wpis w known_hosts,
pozostawiając szablon nienaruszony.

---

## Listingi kodu etapu 4 (z repozytorium)

| Listing | Plik |
|---|---|
| 5.60 | infra/terraform/modules/portal-vm/variables.tf |
| 5.61 | infra/terraform/modules/portal-vm/main.tf |
| 5.62 | infra/terraform/modules/portal-vm/outputs.tf |
| 5.63 | infra/terraform/environments/main.tf |
| 5.64 | infra/ansible/ansible.cfg |
| 5.65 | infra/ansible/requirements.yml |
| 5.66 | infra/ansible/roles/base/tasks/main.yml |
| 5.67 | infra/ansible/roles/docker/tasks/main.yml |
| 5.68 | infra/ansible/playbooks/provision.yml |
| 5.69 | infra/scripts/provision.sh |
| 5.70 | infra/scripts/deprovision.sh |

## Do uzupełnienia (etap 4)

- [ ] Zrzuty: maszyny env-00x w puli portal, zadania wykonane przez terraform@pve, VS Code z rolami Ansible
- [ ] Opcjonalnie: wynik ansible-lint z profilem production dla obu ról

---

# Etap 5: Kontroler domeny dc1 (Samba AD)

## Listing 5.71. Utworzenie maszyny dc1 jako pełnego klonu

```console
keinshur@kv235-965:~/…/infra/terraform/platform$ terraform apply tfplan
module.dc1.proxmox_virtual_environment_vm.this: Creating...
...
module.dc1.proxmox_virtual_environment_vm.this: Creation complete after 1m29s [id=100]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

dc1_ip = "192.168.1.40"
```

Komentarz: pełny klon kopiuje dysk szablonu z magazynu nas-vm na
local-lvm i trwał 89 s, wobec 4–13 s dla klonu połączonego. Wyższy
koszt czasowy jest ceną niezależności kontrolera domeny od szablonu
i od magazynu sieciowego (ADR-003).

---

## Listing 5.72. Sekret w repozytorium zaszyfrowany przez Ansible Vault

```console
keinshur@kv235-965:~/…/infra/ansible$ head -2 inventories/group_vars/domain_controllers/vault.yml
$ANSIBLE_VAULT;1.1;AES256
37346664386363383361373833616533346563346133633336303032383863323839323564353138
keinshur@kv235-965:~/…/infra/ansible$ ansible domain_controllers -m ansible.builtin.debug -a "msg={{ samba_admin_password | length }}"
dc1 | SUCCESS =>
    msg: 28
```

Komentarz: plik z hasłami jest w repozytorium zaszyfrowany algorytmem
AES-256. Ansible odszyfrowuje go w pamięci; weryfikacja wyświetla
wyłącznie długość hasła, a nie jego treść (ADR-016).

---

## Listing 5.73. Rozpoznanie stanu maszyny przed instalacją Samby

```console
keinshur@kv235-965:~$ ssh … ansible@192.168.1.40 '…'
=== nazwa hosta
dc1
dc1
=== /etc/hosts
# Your system has configured 'manage_etc_hosts' as True.
...
127.0.1.1 dc1 dc1
127.0.0.1 localhost
=== resolv.conf
lrwxrwxrwx 1 root root 39 Oct 17 06:57 /etc/resolv.conf -> ../run/systemd/resolve/stub-resolv.conf
...
nameserver 127.0.0.53
search lan
=== systemd-resolved
active
=== port 53
udp   UNCONN 0      0         127.0.0.54:53        0.0.0.0:*    users:(("systemd-resolve",pid=388,fd=20))
udp   UNCONN 0      0      127.0.0.53%lo:53        0.0.0.0:*    users:(("systemd-resolve",pid=388,fd=18))
...
=== czas
System clock synchronized: yes
```

Komentarz: rozpoznanie wykazało trzy przeszkody dla kontrolera domeny:
nazwa hosta wskazująca adres pętli zwrotnej, plik /etc/hosts odtwarzany
przez cloud-init oraz port 53 zajęty przez systemd-resolved. Rola
samba_dc została zaprojektowana na podstawie tych ustaleń.

---

## Listing 5.74. Weryfikacja domeny na kontrolerze

```console
keinshur@kv235-965:~$ ssh … ansible@192.168.1.40 '…'
=== pełna nazwa hosta
dc1.ad.homelab.internal
=== usługa
active
=== port 53
udp   UNCONN 0      0            0.0.0.0:53         0.0.0.0:*    users:(("dns[master]",pid=9811,fd=49))
...
=== poziom domeny
Forest function level: (Windows) 2008 R2
Domain function level: (Windows) 2008 R2
Lowest function level of a DC: (Windows) 2008 R2
=== rekordy SRV: LDAP i Kerberos
_ldap._tcp.ad.homelab.internal has SRV record 0 100 389 dc1.ad.homelab.internal.
_kerberos._udp.ad.homelab.internal has SRV record 0 100 88 dc1.ad.homelab.internal.
=== rekord A kontrolera
dc1.ad.homelab.internal has address 192.168.1.40
=== przekazywanie zapytań na zewnątrz
debian.org has address 151.101.66.132
...
=== konta w domenie
krbtgt
Administrator
Guest
=== udziały kontrolera
        sysvol          Disk
        netlogon        Disk
```

Komentarz: kontroler domeny przejął DNS, publikuje rekordy SRV usług
LDAP i Kerberos pod prawdziwym adresem, przekazuje zapytania spoza
domeny do routera i udostępnia udziały sysvol i netlogon. Poziom
funkcjonalności domeny odpowiada Windows Server 2008 R2 (domyślny dla
Samby).

---

## Listing 5.75. Uwierzytelnienie Kerberos

```console
keinshur@kv235-965:~$ ssh -t … ansible@192.168.1.40 'kinit administrator@AD.HOMELAB.INTERNAL && klist'
Password for administrator@AD.HOMELAB.INTERNAL:
Warning: Your password will expire in 41 days on Wed Dec  2 21:04:13 2026
Ticket cache: FILE:/tmp/krb5cc_1000
Default principal: administrator@AD.HOMELAB.INTERNAL

Valid starting     Expires            Service principal
10/21/26 22:09:57  10/22/26 08:09:57  krbtgt/AD.HOMELAB.INTERNAL@AD.HOMELAB.INTERNAL
        renew until 10/22/26 22:09:01
```

Komentarz: kontroler domeny wydał bilet TGT ważny 10 godzin i odnawialny
przez 24 godziny. Ostrzeżenie o wygaśnięciu hasła po 42 dniach
doprowadziło do wyłączenia wygasania haseł kont technicznych (ADR-017).

---

## Listing 5.76. DNS domeny z innej maszyny i trwałość po restarcie

```console
keinshur@kv235-965:~$ dig @192.168.1.40 +short dc1.ad.homelab.internal
192.168.1.40
keinshur@kv235-965:~$ dig @192.168.1.40 +short -t SRV _ldap._tcp.ad.homelab.internal
0 100 389 dc1.ad.homelab.internal.
keinshur@kv235-965:~$ ssh … ansible@192.168.1.40 'sudo reboot'
keinshur@kv235-965:~$ ssh … ansible@192.168.1.40 'hostname -f; grep dc1 /etc/hosts; systemctl is-active samba-ad-dc'
dc1.ad.homelab.internal
192.168.1.40 dc1.ad.homelab.internal dc1
active
```

Komentarz: rekordy domeny są dostępne dla innych maszyn w sieci.
Po ponownym uruchomieniu cloud-init odtworzył /etc/hosts z szablonu
podmienionego przez rolę samba_dc, a kontroler domeny wystartował
automatycznie.

---

## Listing 5.77. Struktura katalogu

```console
keinshur@kv235-965:~$ ssh … ansible@192.168.1.40 '…'
=== OU
OU=Grupy,OU=Homelab
OU=Uzytkownicy,OU=Homelab
OU=KontaUslugowe,OU=Homelab
OU=Homelab
OU=Domain Controllers
=== obiekty w OU=Homelab
CN=Anna Nowak,OU=Uzytkownicy,OU=Homelab
CN=Jan Kowalski,OU=Uzytkownicy,OU=Homelab
CN=grp-it-admins,OU=Grupy,OU=Homelab
CN=svc-ldap-bind,OU=KontaUslugowe,OU=Homelab
CN=grp-wiki-users,OU=Grupy,OU=Homelab
CN=grp-gitea-users,OU=Grupy,OU=Homelab
CN=grp-zabbix-users,OU=Grupy,OU=Homelab
...
=== członkowie grp-it-admins
anna.nowak
=== członkowie grp-gitea-users
anna.nowak
jan.kowalski
keinshur@kv235-965:~$ ssh … ansible@192.168.1.40 '…'
userAccountControl: 66048
userAccountControl: 66048
```

Komentarz: struktura jednostek organizacyjnych, grupy RBAC, konta
użytkowników i konto usługowe utworzone przez Ansible. Wartość 66048
(512 + 65536) oznacza zwykłe konto z flagą niewygasającego hasła dla
kont Administrator i svc-ldap-bind.

---

## Listing 5.78. Idempotentność roli samba_dc

```console
keinshur@kv235-965:~/…/infra/ansible$ ansible-playbook playbooks/dc.yml
...
TASK [samba_dc : Utwórz jednostki organizacyjne] *******************************
skipping: [dc1] => (item=OU=Homelab)
skipping: [dc1] => (item=OU=Uzytkownicy,OU=Homelab)
...
TASK [samba_dc : Utwórz konta użytkowników] ************************************
skipping: [dc1] => (item=(censored due to no_log))
...
PLAY RECAP *********************************************************************
dc1                        : ok=23   changed=0    unreachable=0    failed=0    skipped=11   rescued=0    ignored=0
```

Komentarz: narzędzie samba-tool nie jest idempotentne, jednak dzięki
wzorcowi „odczytaj stan, potem zmień” ponowne wykonanie roli nie
wprowadza żadnych zmian. Hasła w pętlach są ukryte przez no_log.

---

## Listing 5.79. Wymuszenie szyfrowania przy logowaniu LDAP

```console
keinshur@kv235-965:~$ ldapsearch -H ldap://192.168.1.40 -x -D "svc-ldap-bind@ad.homelab.internal" -W …
Enter LDAP Password:
ldap_bind: Strong(er) authentication required (8)
        additional info: BindSimple: Transport encryption required.
```

Komentarz: kontroler domeny odrzuca proste logowanie przez
nieszyfrowany LDAP, chroniąc hasła przed przesłaniem jawnym tekstem.

---

## Listing 5.80. Odczyt katalogu kontem usługowym przez LDAPS

```console
keinshur@kv235-965:~$ LDAPTLS_REQCERT=never ldapsearch -H ldaps://192.168.1.40 -x \
  -D "CN=svc-ldap-bind,OU=KontaUslugowe,OU=Homelab,DC=ad,DC=homelab,DC=internal" \
  -y /tmp/ldap-bind-pw \
  -b "OU=Homelab,DC=ad,DC=homelab,DC=internal" \
  "(sAMAccountName=jan.kowalski)" cn memberOf
# Jan Kowalski, Uzytkownicy, Homelab, ad.homelab.internal
dn: CN=Jan Kowalski,OU=Uzytkownicy,OU=Homelab,DC=ad,DC=homelab,DC=internal
cn: Jan Kowalski
memberOf: CN=grp-gitea-users,OU=Grupy,OU=Homelab,DC=ad,DC=homelab,DC=internal
memberOf: CN=grp-wiki-users,OU=Grupy,OU=Homelab,DC=ad,DC=homelab,DC=internal
memberOf: CN=grp-zabbix-users,OU=Grupy,OU=Homelab,DC=ad,DC=homelab,DC=internal

# search result
search: 2
result: 0 Success
```

Komentarz: konto usługowe odczytuje przez szyfrowane połączenie DN
użytkownika i jego grupy, czyli dokładnie te informacje, których
usługi używają do uwierzytelnienia i autoryzacji. Weryfikacja
certyfikatu jest tymczasowo wyłączona do czasu wdrożenia urzędu
certyfikacji.

---

## Listing 5.81. Strefa DNS usług

```console
keinshur@kv235-965:~$ dig @192.168.1.40 +short git.homelab.internal
192.168.1.41
keinshur@kv235-965:~$ dig @192.168.1.40 +short wiki.homelab.internal
192.168.1.41
keinshur@kv235-965:~$ dig @192.168.1.40 +short dc1.ad.homelab.internal
192.168.1.40
```

Komentarz: kontroler domeny obsługuje dwie strefy: strefę domeny AD
oraz strefę homelab.internal z adresami usług na svc01.

---

## Listingi kodu etapu 5 (z repozytorium)

| Listing | Plik |
|---|---|
| 5.82 | infra/terraform/modules/vm/variables.tf (walidacja klonowania) |
| 5.83 | infra/terraform/platform/dc1.tf |
| 5.84 | infra/ansible/inventories/group_vars/domain_controllers/vars.yml |
| 5.85 | infra/ansible/roles/samba_dc/templates/hosts.j2 |
| 5.86 | infra/ansible/roles/samba_dc/tasks/main.yml |
| 5.87 | infra/ansible/roles/samba_dc/tasks/directory.yml |
| 5.88 | infra/ansible/roles/samba_dc/tasks/dns.yml |

## Do uzupełnienia (etap 5)

- [ ] Listing: komunikat walidacji modułu przy pełnym klonie bez magazynu (test z punktu 5.2)
- [ ] Zrzuty: maszyna dc1 w Proxmox (opcje: autostart), zadania terraform@pve

---

# Etap 6: svc01, urząd certyfikacji, Traefik i Gitea

## Listing 5.89. Maszyna svc01 z dyskiem danych

```console
keinshur@kv235-965:~/…/infra/terraform/platform$ terraform apply tfplan
module.svc01.proxmox_virtual_environment_vm.this: Creating...
...
module.svc01.proxmox_virtual_environment_vm.this: Creation complete after 1m33s [id=101]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
keinshur@kv235-965:~$ ssh homelab 'qm config 101 | grep -E "scsi|memory|cores"'
cores: 4
memory: 6144
scsi0: local-lvm:vm-101-disk-0,aio=io_uring,backup=1,cache=none,discard=on,iothread=1,replicate=1,size=10G,ssd=0
scsi1: local-lvm:vm-101-disk-1,aio=io_uring,backup=1,cache=none,discard=on,iothread=1,replicate=1,size=40G,ssd=0
scsihw: virtio-scsi-single
```

Komentarz: moduł utworzył drugi dysk (scsi1) wyłącznie dla svc01
dzięki blokowi dynamic; konfiguracja dc1 nie uległa zmianie.

---

## Listing 5.90. Dane Dockera na osobnym dysku

```console
keinshur@kv235-965:~$ ssh … ansible@192.168.1.41 '…'
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdb         40G  2.3M   38G   1% /var/lib/docker
/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi1 /var/lib/docker ext4 defaults,nofail 0 0
Katalog Dockera: /var/lib/docker
...
Hello from Docker!
```

Komentarz: dysk danych zamontowany pod stałą nazwą urządzenia,
z wpisem w /etc/fstab; Docker przechowuje obrazy i wolumeny na dysku
oddzielonym od systemowego.

---

## Listing 5.91. Weryfikacja tagów wersji obrazów

```console
keinshur@kv235-965:~$ ssh … ansible@192.168.1.41 '…'
docker.io/gitea/gitea:28.2.0
sha256:30777c91280d973fa02be48b1ade735bd6859e8f6f7af3b4444d519437852504
sha256:30777c91280d973fa02be48b1ade735bd6859e8f6f7af3b4444d519437852504
docker.io/library/postgres:17.11-alpine
sha256:eee6c6e1b0894fa4fe0075eb054af9fd1cf39a35321c2d4110626cfe506411fb
sha256:eee6c6e1b0894fa4fe0075eb054af9fd1cf39a35321c2d4110626cfe506411fb
```

Komentarz: identyczne identyfikatory obrazów dla tagów latest i tagów
z numerem wersji potwierdzają, że przypinana wersja odpowiada
sprawdzonemu obrazowi (ADR-022).

---

## Listing 5.92. Urząd certyfikacji step-ca

```console
TASK [step_ca : Wyświetl odcisk certyfikatu głównego] *************************
ok: [svc01] =>
    msg: 'Odcisk certyfikatu głównego (SHA-256): e2992d189062047e664f038e0bbf0459e23ad5f0d041143e75935232f21ed15c'
keinshur@kv235-965:~/…/infra/ansible$ openssl x509 -in files/pki/root_ca.crt -noout -subject -issuer -dates
subject=O=Homelab Internal CA, CN=Homelab Internal CA Root CA
issuer=O=Homelab Internal CA, CN=Homelab Internal CA Root CA
notBefore=Oct 24 …
notAfter=Oct 21 … 2036 GMT
keinshur@kv235-965:~/…/infra/ansible$ curl -s --cacert files/pki/root_ca.crt --resolve ca.homelab.internal:9000:192.168.1.41 https://ca.homelab.internal:9000/health
{"status":"ok"}
keinshur@kv235-965:~/…/infra/ansible$ curl -s --cacert files/pki/root_ca.crt --resolve … https://ca.homelab.internal:9000/acme/acme/directory | jq
{
  "newNonce": "https://ca.homelab.internal:9000/acme/acme/new-nonce",
  "newAccount": "https://ca.homelab.internal:9000/acme/acme/new-account",
  "newOrder": "https://ca.homelab.internal:9000/acme/acme/new-order",
  "revokeCert": "https://ca.homelab.internal:9000/acme/acme/revoke-cert",
  "keyChange": "https://ca.homelab.internal:9000/acme/acme/key-change"
}
```

Komentarz: samopodpisany certyfikat główny ważny 10 lat; połączenie
z urzędem weryfikowane pobranym certyfikatem głównym, a katalog ACME
potwierdza obsługę automatycznego wydawania certyfikatów.

---

## Listing 5.93. Zaufanie do urzędu na serwerach

```console
keinshur@kv235-965:~$ ssh … ansible@192.168.1.40 'echo -n "dc1: "; curl -sS https://ca.homelab.internal:9000/health; echo'
dc1: {"status":"ok"}
keinshur@kv235-965:~$ ssh … ansible@192.168.1.41 'echo -n "svc01: "; curl -sS https://ca.homelab.internal:9000/health; echo'
svc01: {"status":"ok"}
```

Komentarz: po rozesłaniu certyfikatu głównego rolą ca_trust obie
maszyny weryfikują certyfikat urzędu bez dodatkowych opcji, a nazwę
ca.homelab.internal rozwiązuje kontroler domeny.

---

## Listing 5.94. Automatyczny certyfikat usługi za Traefikiem

```console
keinshur@kv235-965:~$ curl -sS --resolve whoami.homelab.internal:443:192.168.1.41 https://whoami.homelab.internal | head -5
Hostname: ed278229dab5
IP: 127.0.0.1
IP: ::1
IP: 172.18.0.3
RemoteAddr: 172.18.0.4:54864
keinshur@kv235-965:~$ curl -sSI --resolve whoami.homelab.internal:80:192.168.1.41 http://whoami.homelab.internal | head -3
HTTP/1.1 308 Permanent Redirect
Location: https://whoami.homelab.internal/
keinshur@kv235-965:~$ echo | openssl s_client -connect 192.168.1.41:443 -servername whoami.homelab.internal 2>/dev/null | openssl x509 -noout -subject -issuer -dates
subject=CN=whoami.homelab.internal
issuer=O=Homelab Internal CA, CN=Homelab Internal CA Intermediate CA
notBefore=Oct 24 12:11:15 2026 GMT
notAfter=Oct 25 12:12:15 2026 GMT
```

Komentarz: Traefik zamówił certyfikat w step-ca protokołem ACME.
Certyfikat podpisany przez urząd pośredni jest ważny 24 godziny;
połączenie HTTP jest przekierowywane na HTTPS, a usługa widzi jako
klienta adres Traefika.

---

## Listing 5.95. Provisionery urzędu certyfikacji

```console
keinshur@kv235-965:~$ ssh … ansible@192.168.1.41 'docker exec step-ca step ca provisioner list' | jq -r '.[] | "\(.name) \(.type)"'
admin JWK
acme ACME
infra JWK
```

Komentarz: provisioner acme obsługuje usługi webowe (certyfikaty
24-godzinne), a provisioner infra certyfikaty infrastruktury ważne rok.

---

## Listing 5.96. Certyfikat kontrolera domeny z wniosku CSR

```console
TASK [samba_tls : Wygeneruj klucz prywatny kontrolera domeny] *****************
changed: [dc1]
TASK [samba_tls : Utwórz wniosek o certyfikat (CSR)] **************************
changed: [dc1]
TASK [samba_tls : Przekaż wniosek do urzędu certyfikacji] *********************
changed: [dc1 -> svc01(192.168.1.41)]
TASK [samba_tls : Podpisz wniosek w urzędzie certyfikacji] ********************
changed: [dc1 -> svc01(192.168.1.41)]
TASK [samba_tls : Zapisz certyfikat na kontrolerze domeny] ********************
changed: [dc1]
...
RUNNING HANDLER [samba_tls : Uruchom ponownie kontroler domeny] ***************
changed: [dc1]
```

Komentarz: klucz prywatny i wniosek powstają na dc1, a podpisanie
odbywa się na svc01 (delegate_to). Do urzędu trafia wyłącznie wniosek.

---

## Listing 5.97. Weryfikacja certyfikatu LDAPS kontrolera domeny

```console
keinshur@kv235-965:~$ echo | openssl s_client -connect 192.168.1.40:636 -verify_return_error 2>&1 | grep -E "Verify return code|subject=|issuer="
subject=CN=dc1.ad.homelab.internal
issuer=O=Homelab Internal CA, CN=Homelab Internal CA Intermediate CA
Verify return code: 0 (ok)
keinshur@kv235-965:~$ echo | openssl s_client -connect 192.168.1.40:636 2>/dev/null | openssl x509 -noout -ext subjectAltName -dates
X509v3 Subject Alternative Name:
    DNS:dc1.ad.homelab.internal, DNS:dc1, IP Address:192.168.1.40
notBefore=Oct 24 12:43:09 2026 GMT
notAfter=Oct 24 12:44:09 2027 GMT
keinshur@kv235-965:~$ ldapsearch -H ldaps://192.168.1.40 -x -D "CN=svc-ldap-bind,…" -y /tmp/ldap-bind-pw -b "OU=Homelab,…" "(sAMAccountName=jan.kowalski)" cn | grep -E "^cn:|^result:"
cn: Jan Kowalski
result: 0 Success
```

Komentarz: certyfikat zawiera SAN i jest weryfikowany względem
certyfikatu głównego step-ca; odczyt LDAPS działa bez wyłączania
weryfikacji (zamknięcie ograniczenia z etapu 5).

---

## Listing 5.98. Logowanie do Gitei kontami domeny (RBAC)

```console
keinshur@kv235-965:~$ R="--resolve git.homelab.internal:443:192.168.1.41"
keinshur@kv235-965:~$ curl -sS $R https://git.homelab.internal/api/healthz | jq .status
"pass"
keinshur@kv235-965:~$ curl -sS $R -u "jan.kowalski:…" https://git.homelab.internal/api/v1/user | jq '{login, email, is_admin}'
{
  "login": "jan.kowalski",
  "email": "jan.kowalski@homelab.internal",
  "is_admin": false
}
keinshur@kv235-965:~$ curl -sS $R -u anna.nowak https://git.homelab.internal/api/v1/user | jq '{login, email, is_admin}'
{
  "login": "anna.nowak",
  "email": "anna.nowak@homelab.internal",
  "is_admin": true
}
keinshur@kv235-965:~$ curl -sS $R -u Administrator https://git.homelab.internal/api/v1/user | jq .message
"invalid username, password or token"
keinshur@kv235-965:~$ ssh … ansible@192.168.1.41 'docker network inspect gitea_gitea-internal --format "{{range .Containers}}{{.Name}} {{end}}"'
gitea-db gitea
```

Komentarz: konta Gitei tworzone są przy pierwszym logowaniu na
podstawie katalogu; uprawnienia administratora wynikają wyłącznie
z członkostwa w grp-it-admins, a konta spoza filtra są odrzucane.
Baza danych jest dostępna wyłącznie w sieci wewnętrznej Gitei.

---

## Listing 5.99. Rozpoznawanie nazw na stacji z dwiema kartami sieciowymi

```console
PS C:\Users\…> Resolve-DnsName git.homelab.internal
Resolve-DnsName : git.homelab.internal : Nazwa DNS nie istnieje
PS C:\Users\…> Resolve-DnsName git.homelab.internal -Server 192.168.1.40
Name                                           Type   TTL   Section    IPAddress
----                                           ----   ---   -------    ---------
git.homelab.internal                           A      900   Answer     192.168.1.41
PS C:\Users\…> Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object ServerAddresses | Format-Table InterfaceAlias, ServerAddresses
InterfaceAlias ServerAddresses
-------------- ---------------
Ethernet       {192.168.0.92, 192.168.0.99}
Wi-Fi 2        {192.168.1.40, 192.168.1.1}
```

Komentarz: stacja podłączona do dwóch sieci odpytuje najpierw DNS karty
przewodowej, który zwraca odpowiedź „nazwa nie istnieje”. Rozwiązaniem
jest reguła NRPT kierująca zapytania o homelab.internal do kontrolera
domeny (rozdzielony DNS).

---

## Listingi kodu etapu 6 (z repozytorium)

| Listing | Plik |
|---|---|
| 5.100 | infra/terraform/modules/vm/main.tf (blok dynamic dysku danych) |
| 5.101 | infra/terraform/platform/svc01.tf |
| 5.102 | infra/ansible/roles/data_disk/tasks/main.yml |
| 5.103 | infra/ansible/roles/step_ca/templates/docker-compose.yml.j2 |
| 5.104 | infra/ansible/roles/step_ca/tasks/main.yml |
| 5.105 | infra/ansible/roles/ca_trust/tasks/main.yml i handlers/main.yml |
| 5.106 | infra/ansible/roles/traefik/templates/traefik.yml.j2 |
| 5.107 | infra/ansible/roles/traefik/templates/docker-compose.yml.j2 |
| 5.108 | infra/ansible/roles/samba_tls/tasks/main.yml |
| 5.109 | infra/ansible/roles/gitea/templates/docker-compose.yml.j2 |
| 5.110 | infra/ansible/roles/gitea/tasks/main.yml |
| 5.111 | infra/ansible/inventories/group_vars/all/vars.yml |

## Do uzupełnienia (etap 6)

- [ ] Zrzuty: kłódka i łańcuch certyfikatu w przeglądarce, Gitea po zalogowaniu Jana, panel administracyjny Anny ze źródłem uwierzytelniania homelab-ad
- [ ] Zrzut: certyfikat główny w certmgr z odciskiem SHA-1
- [ ] Wersja Traefika i whoami w dzienniku

---

# Etap 7: BookStack

## Listing 5.112. Wersja PHP w obrazie BookStack

```console
ansible@svc01:~$ docker image inspect lscr.io/linuxserver/bookstack:latest --format '{{ index .Config.Labels "org.opencontainers.image.version" }}'
v26.09.2-ls292
ansible@svc01:~$ docker run --rm --entrypoint php lscr.io/linuxserver/bookstack:latest -v | head -1
PHP 8.5.12 (cli) (built: Oct 21 2026 16:29:26) (NTS)
ansible@svc01:~$ docker run --rm mariadb:11-noble mariadbd --version
mariadbd  Ver 11.8.9-MariaDB-ubu2404 for debian-linux-gnu on x86_64 (mariadb.org binary distribution)
```

Komentarz: obraz zawiera PHP 8.5.12, czyli wersję z poprawką podatności
PHP2Shell, zbudowaną w dniu publikacji łatek. Weryfikacja wersji
komponentu przed przypięciem obrazu jest elementem kontroli łańcucha
dostaw (ADR-022, ADR-023).

---

## Listing 5.113. Mapowanie grup AD na role BookStacka

```console
keinshur@kv235-965:~$ ssh … ansible@192.168.1.41 'docker exec bookstack-db sh -c '…' SELECT display_name, system_name, external_auth_id FROM roles;'
+--------------+-------------+------------------+
| display_name | system_name | external_auth_id |
+--------------+-------------+------------------+
| Admin        | admin       | grp-it-admins    |
| Editor       |             | grp-wiki-users   |
| Viewer       |             |                  |
| Public       | public      |                  |
+--------------+-------------+------------------+
```

Komentarz: identyfikatory zewnętrzne ról wiążą je z grupami katalogu.
Ponowne wykonanie roli nie zmienia wierszy (ROW_COUNT = 0), co zapewnia
idempotentność polecenia SQL.

---

## Listing 5.114. Role użytkowników po pierwszym logowaniu

```console
keinshur@kv235-965:~$ ssh … ansible@192.168.1.41 'docker exec bookstack-db sh -c '…' SELECT u.name, u.email, r.display_name AS rola FROM users u JOIN role_user ru ON …'
+--------------+-------------------------------+--------+
| name         | email                         | rola   |
+--------------+-------------------------------+--------+
| Anna Nowak   | anna.nowak@homelab.internal   | Admin  |
| Anna Nowak   | anna.nowak@homelab.internal   | Editor |
| Guest        | guest@example.com             | Public |
| Jan Kowalski | jan.kowalski@homelab.internal | Editor |
+--------------+-------------------------------+--------+
```

Komentarz: konta zostały utworzone przy pierwszym logowaniu kontami
domeny, a role przypisane automatycznie na podstawie grup. Domyślne
konto admin@admin.com zostało usunięte; konto Guest jest kontem
systemowym dla niezalogowanych.

---

## Listing 5.115. Reguła NRPT na stacji administratora

```console
PS C:\WINDOWS\system32> Add-DnsClientNrptRule -Namespace ".homelab.internal" -NameServers "192.168.1.40"
PS C:\WINDOWS\system32> Clear-DnsClientCache
PS C:\WINDOWS\system32> Resolve-DnsName wiki.homelab.internal

Name                                           Type   TTL   Section    IPAddress
----                                           ----   ---   -------    ---------
wiki.homelab.internal                          A      900   Answer     192.168.1.41
```

Komentarz: reguła tabeli zasad rozpoznawania nazw kieruje zapytania
o domenę homelab.internal do kontrolera domeny niezależnie od kart
sieciowych stacji (rozdzielony DNS), rozwiązując problem z listingu 5.99.

---

## Listingi kodu etapu 7 (z repozytorium)

| Listing | Plik |
|---|---|
| 5.116 | infra/ansible/roles/bookstack/templates/docker-compose.yml.j2 |
| 5.117 | infra/ansible/roles/bookstack/tasks/main.yml |
| 5.118 | infra/ansible/roles/bookstack/defaults/main.yml |

## Do uzupełnienia (etap 7)

- [ ] Zrzuty: lista użytkowników BookStacka z rolami, profil Jana (Editor), kłódka na wiki.homelab.internal

---

# Etap 8: Monitoring Zabbix

## Listing 5.119. Rozpoznanie wersji Zabbixa i agenta

```console
ansible@svc01:~$ docker run --rm --entrypoint zabbix_server zabbix/zabbix-server-pgsql:alpine-latest -V | head -1
zabbix_server (Zabbix) 7.4.16
ansible@svc01:~$ docker pull zabbix/zabbix-server-pgsql:alpine-8.0-latest
Error response from daemon: … alpine-8.0-latest: not found
ansible@svc01:~$ docker run --rm --entrypoint zabbix_server zabbix/zabbix-server-pgsql:alpine-7.0-latest -V 2>/dev/null | head -1
zabbix_server (Zabbix) 7.0.32
keinshur@kv235-965:~$ ssh … ansible@192.168.1.40 'apt-cache policy zabbix-agent2 | head -3'
zabbix-agent2:
  Installed: (none)
  Candidate: 1:7.0.22+dfsg-1~deb13u1
```

Komentarz: najnowsza wersja (7.4) jest wydaniem standardowym, a gałąź
8.0 LTS nie jest jeszcze dostępna. Wybrano Zabbix 7.0 LTS, zgodny
z agentem z repozytorium Debiana (ADR-024).

---

## Listing 5.120. Tag a skrót obrazu

```console
ansible@svc01:~$ docker image inspect -f '{{.Id}}' zabbix/zabbix-web-nginx-pgsql:alpine-7.0-latest zabbix/zabbix-web-nginx-pgsql:alpine-7.0.32
sha256:fb5b690e182ad728f4b8e56ca078114c153db1f8435010377d6a9babfe3df613
sha256:a54ce2e19aaf0a61609e4bbc7ec01c16bef504e6e1c51e3854120ac76d2dbaeb
ansible@svc01:~$ docker image inspect -f '{{.Created}}' zabbix/zabbix-web-nginx-pgsql:alpine-7.0-latest zabbix/zabbix-web-nginx-pgsql:alpine-7.0.32
2026-10-22T06:31:06.884029269Z
2026-10-22T10:20:56.037204244Z
ansible@svc01:~$ docker run --rm --entrypoint sh zabbix/zabbix-web-nginx-pgsql:alpine-7.0.32 -c '…'
/usr/sbin/php-fpm85: PHP 8.5.12 (fpm-fcgi) (built: Oct 21 2026 16:29:26) (NTS)
```

Komentarz: dwa tagi tej samej wersji wskazywały różne kompilacje
z tego samego dnia; obie zawierają PHP z poprawką PHP2Shell. Obrazy
przypięto skrótem manifestu, jednoznacznie identyfikującym sprawdzony
obraz (ADR-025).

---

## Listing 5.121. Automatyczny certyfikat nowej usługi

```console
keinshur@kv235-965:~$ echo | openssl s_client -connect 192.168.1.41:443 -servername zabbix.homelab.internal 2>/dev/null | openssl x509 -noout -subject
subject=CN=TRAEFIK DEFAULT CERT
…(wdrożenie roli zabbix_server)…
keinshur@kv235-965:~$ echo | openssl s_client -connect 192.168.1.41:443 -servername zabbix.homelab.internal 2>/dev/null | openssl x509 -noout -subject -issuer
subject=CN=zabbix.homelab.internal
issuer=O=Homelab Internal CA, CN=Homelab Internal CA Intermediate CA
```

Komentarz: przed wdrożeniem Traefik nie znał usługi i przedstawiał
certyfikat domyślny; po uruchomieniu kontenera z etykietami Traefik
automatycznie zamówił certyfikat w step-ca.

---

## Listing 5.122. Usługa Zabbix na svc01

```console
keinshur@kv235-965:~$ curl -sS -o /dev/null -w "Interfejs Zabbixa: %{http_code}\n" https://zabbix.homelab.internal/
Interfejs Zabbixa: 200
keinshur@kv235-965:~$ ssh … ansible@192.168.1.41 'docker ps --filter name=zabbix --format "table {{.Names}}\t{{.Status}}"'
NAMES           STATUS
zabbix-web      Up 59 seconds (healthy)
zabbix-server   Up 59 seconds
zabbix-db       Up About a minute (healthy)
```

Komentarz: wdrożenie roli trwało 55 s; ponowne wykonanie nie wprowadza
zmian.

---

## Listing 5.123. Agenty na monitorowanych maszynach

```console
keinshur@kv235-965:~$ ansible monitored -b -m ansible.builtin.shell -a "systemctl is-active zabbix-agent2; grep -E '^(Server|ServerActive|Hostname)=' /etc/zabbix/zabbix_agent2.conf"
homelab | CHANGED | rc=0 >>
active
Server=192.168.1.41
ServerActive=192.168.1.41
Hostname=homelab
dc1 | CHANGED | rc=0 >>
active
…
keinshur@kv235-965:~$ ssh … ansible@192.168.1.41 'for h in …; do docker exec zabbix-server sh -c "nc -z -w 2 $h 10050 …"; done'
192.168.1.30: port 10050 otwarty
192.168.1.40: port 10050 otwarty
192.168.1.41: port 10050 otwarty
```

Komentarz: rola zabbix_agent konfiguruje agenty na wszystkich hostach
grupy monitored (hypervisor, kontroler domeny, host usług).

---

## Listing 5.124. Odrzucanie połączeń z kontenera na tym samym hoście

```console
keinshur@kv235-965:~$ ssh … ansible@192.168.1.41 'sudo grep -i "rejected" /var/log/zabbix/zabbix_agent2.log | tail -3'
2026/10/25 11:11:23.261976 connection from "172.21.0.2" rejected, allowed hosts: "192.168.1.41"
2026/10/25 11:12:23.260973 connection from "172.21.0.2" rejected, allowed hosts: "192.168.1.41"
2026/10/25 11:13:23.261025 connection from "172.21.0.2" rejected, allowed hosts: "192.168.1.41"
```

Komentarz: połączenia z kontenera serwera do agenta na tym samym hoście
nie są maskowane adresem 192.168.1.41. Rozwiązaniem jest stała podsieć
sieci zabbix-agents (172.30.0.0/24) dopuszczona w konfiguracji agenta
na svc01. Test samego otwarcia portu (listing 5.123) nie wykrył tego
problemu.

---

## Listing 5.125. Idempotentna zmiana domyślnego hasła przez API

```console
TASK [Sprawdź, czy konto Admin ma jeszcze domyślne hasło] **********************
ok: [zabbix-api -> localhost]
TASK [Zmień domyślne hasło konta Admin] ****************************************
skipping: [zabbix-api]
TASK [Utwórz grupę hostów] *****************************************************
ok: [zabbix-api]
TASK [Zarejestruj monitorowane maszyny] ****************************************
ok: [zabbix-api] => (item=homelab)
ok: [zabbix-api] => (item=dc1)
ok: [zabbix-api] => (item=svc01)
```

Komentarz: hasło zostało zmienione w pierwszym przebiegu; w kolejnych
logowanie hasłem domyślnym kończy się niepowodzeniem, więc zmiana jest
pomijana. Hosty rejestrowane są modułem idempotentnym.

---

## Listing 5.126. Test katalogu użytkowników w interfejsie Zabbixa

```console
Test authentication
Login successful
User role: User role
User groups: Homelab - podglad
```

Komentarz: wbudowany test potwierdził połączenie LDAPS, konto usługowe,
filtr i mapowanie grup. Logowanie mimo to nie działało, ponieważ
tworzenie kont przy pierwszym logowaniu wymaga LDAP jako domyślnej
metody uwierzytelniania (ADR-026).

---

## Listing 5.127. Idempotentność konfiguracji monitoringu

```console
keinshur@kv235-965:~/…/infra/ansible$ ansible-playbook playbooks/svc.yml | tail -3
svc01                      : ok=45   changed=0    unreachable=0    failed=0    skipped=4 …
keinshur@kv235-965:~/…/infra/ansible$ ansible-playbook playbooks/monitoring.yml | tail -5
dc1                        : ok=4    changed=0 …
homelab                    : ok=4    changed=0 …
svc01                      : ok=5    changed=0 …
keinshur@kv235-965:~/…/infra/ansible$ ansible-playbook playbooks/zabbix-config.yml | grep -E "changed:|PLAY RECAP" -A1
changed: [zabbix-api]
--
zabbix-api                 : ok=8    changed=1 …
```

Komentarz: jedyną zgłaszaną zmianą jest katalog użytkowników, ponieważ
hasło konta usługowego jest w API polem tylko do zapisu.

---

## Listing 5.128. Wykrycie awarii agenta

```console
keinshur@kv235-965:~$ ssh … ansible@192.168.1.40 'sudo systemctl stop zabbix-agent2'
…
Current problems (Global view):
Time         Host  Problem • Severity                                   Duration
02:58:30 PM  dc1   Linux: Zabbix agent is not available (for 3m)  Average  25s
Host availability: 2 Available, 1 Not available
```

Komentarz: problem pojawił się po ok. 3 minutach od zatrzymania agenta,
zgodnie z progiem wyzwalacza. Ikona dostępności zmienia kolor szybciej,
lecz problem powstaje dopiero po przekroczeniu progu, co zapobiega
alarmom przy chwilowych przerwach.

---

## Listingi kodu etapu 8 (z repozytorium)

| Listing | Plik |
|---|---|
| 5.129 | infra/ansible/roles/zabbix_server/templates/docker-compose.yml.j2 |
| 5.130 | infra/ansible/roles/zabbix_agent/tasks/main.yml |
| 5.131 | infra/ansible/playbooks/zabbix-config.yml |
| 5.132 | infra/ansible/inventories/group_vars/zabbix_api/vars.yml |
| 5.133 | infra/ansible/inventories/hosts.yml (grupy monitored i zabbix_api) |

## Do uzupełnienia (etap 8)

- [ ] Czas potwierdzenia naprawy (Recovery time) w teście awarii agenta
- [ ] Zrzuty: pulpit Global view z problemem dc1, problem ze statusem RESOLVED, lista hostów widziana przez Jana (3 hosty) i Annę (4 hosty), dane kontenerów svc01

---
