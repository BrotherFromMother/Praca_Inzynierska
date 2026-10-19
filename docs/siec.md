# Plan adresacji sieci laboratoryjnej

Sieć: 192.168.1.0/24, brama 192.168.1.1
Topologia: płaska, bez VLAN (most vmbr0 w trybie VLAN aware
jako przygotowanie do ewentualnej segmentacji).

| Adres IP           | Nazwa hosta | Rola                                   | Status     |
|--------------------|-------------|----------------------------------------|------------|
| 192.168.1.1        | router      | brama domyślna, DHCP                   | działa     |
| 192.168.1.30       | homelab     | Proxmox VE 9.2 (Lenovo MiniPC)         | działa     |
| 192.168.1.80       | nas01       | Synology DS225+, NFS (pve-vm, pve-backup) | działa  |
| 192.168.1.32       | rpi01       | Raspberry Pi 5: Zabbix, Tailscale      | planowany  |
| 192.168.1.40       | dc1         | Samba AD DC, DNS                       | planowany  |
| 192.168.1.41       | svc01       | Docker: portal, Traefik, Gitea         | planowany  |
| 192.168.1.200–.239 | –           | pula adresów platformy samoobsługowej  | planowany  |

## Uwagi
- Adresy statyczne i pula portalu muszą leżeć poza zakresem DHCP routera.
- Zakres DHCP routera: 192.168.1.100–192.168.1.199 (sprawdzono 2026-10-19).
- Hypervisor ma drugi interfejs sieciowy (nic1), obecnie nieużywany.
  TODO: ustalić jego typ (`ip -br link`).
