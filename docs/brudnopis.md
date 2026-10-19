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
