output "debian13_image_id" {
  description = "Identyfikator obrazu Debian 13 w magazynie Proxmox"
  value       = proxmox_download_file.debian13.id
}