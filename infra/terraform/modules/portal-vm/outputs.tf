output "vm_id" {
  description = "Identyfikator VMID środowiska"
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "name" {
  description = "Nazwa środowiska"
  value       = proxmox_virtual_environment_vm.this.name
}

output "ip" {
  description = "Adres IPv4 środowiska (bez maski)"
  value       = split("/", var.ip_address)[0]
}