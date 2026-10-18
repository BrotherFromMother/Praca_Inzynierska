output "pve_version" {
  description = "Wersja Proxmox VE"
  value       = data.proxmox_version.pve.version
}

output "nodes" {
  description = "Węzły Proxmox VE"
  value       = data.proxmox_virtual_environment_nodes.all.names
}

output "portal_pool" {
  description = "Identyfikator puli dla środowisk portalu"
  value       = proxmox_virtual_environment_pool.portal.pool_id
}
