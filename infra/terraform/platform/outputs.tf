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
output "debian13_template_id" {
  description = "Identyfikator VMID szablonu Debian 13"
  value       = proxmox_virtual_environment_vm.debian13_template.vm_id
}