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

root@homelab:~#

```
