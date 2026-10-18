```bash
Linux homelab 7.0.2-6-pve #1 SMP PREEMPT_DYNAMIC PMX 7.0.2-6 (2026-05-20T08:55Z) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
root@homelab:~# apt update
...
Processing triggers for postfix (3.10.13-0+deb13u1) ...
Restarting postfix
[1]+  Done                    apt update
```
```bash
root@homelab:~#  cat /etc/pve/jobs.cfg
vzdump: backup-4e5d5c3c-d112
        schedule 02:00
        all 1
        compress zstd
        enabled 1
        fleecing 0
        mailnotification failure
        mailto rafal.important.information@gmail.com
        mode snapshot
        notes-template {{guestname}}
        notification-mode legacy-sendmail
        prune-backups keep-daily=7,keep-weekly=4
        storage nas-backup

root@homelab:~#


```
```bash
root@homelab:~#  cat /etc/pve/jobs.cfg
vzdump: backup-4e5d5c3c-d112
        schedule 02:00
        all 1
        compress zstd
        enabled 1
        fleecing 0
        mailnotification failure
        mailto rafal.important.information@gmail.com
        mode snapshot
        notes-template {{guestname}}
        notification-mode legacy-sendmail
        prune-backups keep-daily=7,keep-weekly=4
        storage nas-backup

root@homelab:~# pveversion
grep -A6 "iface vmbr0" /etc/network/interfaces
pvesm status
mount | grep nfs
timedatectl
chronyc sources
df -Th /
pve-manager/9.2.21/4f6e0ac86f9e8c7f (running kernel: 7.0.14-24-pve)
iface vmbr0 inet static
        address 192.168.1.30/24
        gateway 192.168.1.1
        bridge-ports nic0
        bridge-stp off
        bridge-fd 0

Name              Type     Status     Total (KiB)      Used (KiB) Available (KiB)        %
local              dir     active        98497780         5537228        87911004    5.62%
local-lvm      lvmthin     active       365760512               0       365760512    0.00%
nas-backup         nfs     active      3739615232       134181632      3605433600    3.59%
nas-vm             nfs     active      3739615232       134181632      3605433600    3.59%
192.168.1.80:/volume1/pve-vm on /mnt/pve/nas-vm type nfs4 (rw,relatime,vers=4.1,rsize=262144,wsize=262144,namlen=255,hard,fatal_neterrors=none,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.30,local_lock=none,addr=192.168.1.80)
192.168.1.80:/volume1/pve-backup on /mnt/pve/nas-back type nfs4 (rw,relatime,vers=4.1,rsize=262144,wsize=262144,namlen=255,hard,fatal_neterrors=none,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.30,local_lock=none,addr=192.168.1.80)
192.168.1.80:/volume1/pve-backup on /mnt/pve/nas-backup type nfs4 (rw,relatime,vers=4.1,rsize=262144,wsize=262144,namlen=255,hard,fatal_neterrors=none,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.1.30,local_lock=none,addr=192.168.1.80)
               Local time: Sat 2026-10-17 22:15:16 CEST
           Universal time: Sat 2026-10-17 20:15:16 UTC
                 RTC time: Sat 2026-10-17 20:15:16
                Time zone: Europe/Warsaw (CEST, +0200)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: no
MS Name/IP address         Stratum Poll Reach LastRx Last sample               
===============================================================================
^+ ntp.kdm.wcss.pl               2   9   377   463    -35us[  -35us] +/-   36ms
^+ ip-89-161-47-139.tel.tkb>     1   9   373   199    -16ms[  -16ms] +/-   48ms
^- ip-89-161-47-133.tel.tkb>     1   9   325    78    -16ms[  -16ms] +/-   48ms
^* ntp01.pingless.com            2   8   377   26m  +4355us[+4902us] +/-   25ms
Filesystem           Type  Size  Used Avail Use% Mounted on
/dev/mapper/pve-root ext4   94G  5.3G   84G   6% /
root@homelab:~# 

```




```bash

root@homelab:~#    grep -A8 "iface vmbr0" /etc/network/interfaces
iface vmbr0 inet static
        address 192.168.1.30/24
        gateway 192.168.1.1
        bridge-ports nic0
        bridge-stp off
        bridge-fd 0
        bridge-vlan-aware yes
        bridge-vids 2-4094

root@homelab:~#


```


```bash

keinshur@kv235-965:~$ git --version
python3 --version
pipx --version
keychain --version
git version 2.47.3
Python 3.13.5
1.7.1

 * keychain 2.8.5 ~ http://www.funtoo.org

   Copyright 2002-2006 Gentoo Foundation;
   Copyright 2007 Aron Griffis;
   Copyright 2009-2017 Funtoo Solutions, Inc;
   lockfile() Copyright 2009 Parallels, Inc.

 Keychain is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License version 2 as
 published by the Free Software Foundation.

keinshur@kv235-965:~$


```


```bash

keinshur@kv235-965:~$ ssh -T git@github.com
The authenticity of host 'github.com (140.82.121.3)' can't be established.
ED25519 key fingerprint is SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'github.com' (ED25519) to the list of known hosts.
Enter passphrase for key '/home/keinshur/.ssh/github_ed25519':
Hi BrotherFromMother! You've successfully authenticated, but GitHub does not provide shell access.
keinshur@kv235-965:~$


```
