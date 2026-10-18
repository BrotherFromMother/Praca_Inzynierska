# Połączenie z Proxmox VE dla modułu pobierania obrazów.
# Używa osobnego konta terraform-images@pve z rolą ImageDownloader,
# ograniczoną do magazynu local i węzła homelab (ADR-010).
# Adres, token i ustawienia TLS są odczytywane ze zmiennych środowiskowych:
#   PROXMOX_VE_ENDPOINT, PROXMOX_VE_API_TOKEN, PROXMOX_VE_INSECURE
# (plik ~/.config/homelab/proxmox-images.env, poza repozytorium).
provider "proxmox" {}