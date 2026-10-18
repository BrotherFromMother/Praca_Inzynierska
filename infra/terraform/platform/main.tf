# Źródła danych: odczyt informacji z Proxmoxa (niczego nie tworzą).
data "proxmox_version" "pve" {}

data "proxmox_virtual_environment_nodes" "all" {}

# Pula zasobów dla środowisk tworzonych przez platformę samoobsługową.
resource "proxmox_virtual_environment_pool" "portal" {
  pool_id = "portal"
  comment = "Srodowiska platformy samoobslugowej (zarzadzane przez Terraform)"
}
