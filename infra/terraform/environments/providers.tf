# Połączenie z Proxmox VE.
# Adres, token i ustawienia TLS są odczytywane ze zmiennych środowiskowych:
#   PROXMOX_VE_ENDPOINT, PROXMOX_VE_API_TOKEN, PROXMOX_VE_INSECURE
# (plik ~/.config/homelab/proxmox.env, poza repozytorium; ADR-008).
provider "proxmox" {}
