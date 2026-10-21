```console 
keinshur@kv235-965:~/projekty/Praca_Inzynierska/infra/terraform/platform$ ssh homelab 'qm config 9000'
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
keinshur@kv235-965:~/projekty/Praca_Inzynierska/infra/terraform/platform$ ssh homelab 'pvesm list nas-vm --vmid 9000'
Volid                               Format  Type             Size VMID
nas-vm:9000/base-9000-disk-0.qcow2  qcow2   images    10737418240 9000
nas-vm:9000/vm-9000-cloudinit.qcow2 qcow2   images        4194304 9000
keinshur@kv235-965:~/projekty/Praca_Inzynierska/infra/terraform/platform$ 

```
```console
keinshur@kv235-965:~/projekty/Praca_Inzynierska/infra/ansible$ time ansible-playbook -i "192.168.1.201," -u ansible --private-key ~/.ssh/portal_automation_ed25519 playbooks/provision.yml
ansible-playbook -i "192.168.1.201," -u ansible --private-key ~/.ssh/portal_automation_ed25519 playbooks/provision.yml

PLAY [Konfiguracja środowiska użytkownika] *****************************************************************************

TASK [Gathering Facts] *************************************************************************************************
ok: [192.168.1.201]

TASK [base : Zaktualizuj listę pakietów i system] **********************************************************************
ok: [192.168.1.201]

TASK [base : Zainstaluj pakiety bazowe] ********************************************************************************
changed: [192.168.1.201]

TASK [base : Ustaw strefę czasową] *************************************************************************************
changed: [192.168.1.201]

TASK [base : Sprawdź, czy aktualizacja wymaga ponownego uruchomienia] **************************************************
ok: [192.168.1.201]

TASK [base : Uruchom ponownie system, jeśli wymaga tego aktualizacja] **************************************************
skipping: [192.168.1.201]

PLAY RECAP *************************************************************************************************************
192.168.1.201              : ok=5    changed=2    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0


real    0m25.298s
user    0m1.696s
sys     0m0.330s

PLAY [Konfiguracja środowiska użytkownika] *****************************************************************************

TASK [Gathering Facts] *************************************************************************************************
ok: [192.168.1.201]

TASK [base : Zaktualizuj listę pakietów i system] **********************************************************************
ok: [192.168.1.201]

TASK [base : Zainstaluj pakiety bazowe] ********************************************************************************
ok: [192.168.1.201]

TASK [base : Ustaw strefę czasową] *************************************************************************************
ok: [192.168.1.201]

TASK [base : Sprawdź, czy aktualizacja wymaga ponownego uruchomienia] **************************************************
ok: [192.168.1.201]

TASK [base : Uruchom ponownie system, jeśli wymaga tego aktualizacja] **************************************************
skipping: [192.168.1.201]

PLAY RECAP *************************************************************************************************************
192.168.1.201              : ok=5    changed=0    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0

keinshur@kv235-965:~/projekty/Praca_Inzynierska/infra/ansible$
```

```console
keinshur@kv235-965:~/projekty/Praca_Inzynierska/infra/ansible$ ssh -i ~/.ssh/portal_automation_ed25519 ansible@192.168.1.201 'docker --version && docker compose version && docker run --rm hello-world'
Docker version 29.9.1, build dfc520d
Docker Compose version v5.6.0
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
4f55086f7dd0: Pulling fs layer
4f55086f7dd0: Download complete
4f55086f7dd0: Pull complete
d5e71e642bf5: Download complete
Digest: sha256:11a3eb1597e864c51b3f56733cb2e8a90bf0c284bfc05f9444d81c558bc848aa
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/

keinshur@kv235-965:~/projekty/Praca_Inzynierska/infra/ansible$

```