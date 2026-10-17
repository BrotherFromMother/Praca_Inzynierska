```bash
root@homelab:~# pvesm scan nfs 192.168.1.80
/volume1/pve-backup 192.168.1.30
/volume1/pve-vm     192.168.1.30
root@homelab:~# 
```

```bash
root@homelab:~# pvesm status
Name             Type     Status     Total (KiB)      Used (KiB) Available (KiB)        %
local             dir     active        98497780         5536696        87911536    5.62%
local-lvm     lvmthin     active       365760512               0       365760512    0.00%
nas-back          nfs     active      3739615232       133414656      3606200576    3.57%
nas-vm            nfs     active      3739615232       133414656      3606200576    3.57%
root@homelab:~# mount | grep nfs
192.168.1.80:/volume1/pve-vm on /mnt/pve/nas-vm type nfs4 (rw,relatime,vers=4.1,rsize=262144,wsize=262144,namlen=255,hard,fatal_neterrors=none,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.30,local_lock=none,addr=192.168.1.80)
192.168.1.80:/volume1/pve-backup on /mnt/pve/nas-back type nfs4 (rw,relatime,vers=4.1,rsize=262144,wsize=262144,namlen=255,hard,fatal_neterrors=none,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.30,local_lock=none,addr=192.168.1.80)
root@homelab:~#
```
