# Obraz chmurowy Debian 13 (genericcloud, amd64), przypięty do konkretnego
# wydania i weryfikowany sumą SHA-512 (ADR-009).
# Proxmox pobiera plik bezpośrednio z serwera Debiana, przez API (ADR-010).
resource "proxmox_download_file" "debian13" {
  node_name    = var.node_name
  datastore_id = var.image_datastore
  content_type = "import"

  url       = "https://cloud.debian.org/images/cloud/trixie/${var.debian_image_version}/debian-13-genericcloud-amd64-${var.debian_image_version}.qcow2"
  file_name = "debian-13-genericcloud-amd64-${var.debian_image_version}.qcow2"

  checksum           = var.debian_image_sha512
  checksum_algorithm = "sha512"
  upload_timeout     = 1800
}