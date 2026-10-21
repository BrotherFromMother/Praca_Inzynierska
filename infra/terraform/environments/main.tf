# Jedno środowisko użytkownika na workspace (ADR-013).
module "env" {
  source = "../modules/portal-vm"

  name       = var.env_name
  vm_id      = var.vm_id
  ip_address = var.ip_address
  cores      = var.cores
  memory_mb  = var.memory_mb

  node_name      = var.node_name
  template_vm_id = var.template_vm_id
  datastore_id   = var.datastore_id
  pool_id        = var.pool_id
  gateway        = var.gateway
  dns_servers    = var.dns_servers
  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
}