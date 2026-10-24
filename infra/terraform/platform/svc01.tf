# Host usług w kontenerach Docker (ADR-011).
# Pełny klon na local-lvm, osobny dysk danych dla /var/lib/docker.
module "svc01" {
  source = "../modules/vm"

  name        = "svc01"
  vm_id       = 101
  description = "Host uslug w kontenerach (Docker), zarzadzany przez Terraform"
  tags        = ["docker", "services", "terraform"]

  ip_address = "192.168.1.41/24"
  gateway    = var.gateway
  # dc1 rozwiązuje nazwy usług (homelab.internal), router zapasowo.
  dns_servers = ["192.168.1.40", "192.168.1.1"]

  cores     = 4
  memory_mb = 6144

  node_name          = var.node_name
  template_vm_id     = proxmox_virtual_environment_vm.debian13_template.vm_id
  full_clone         = true
  clone_datastore_id = "local-lvm"
  datastore_id       = "local-lvm"
  on_boot            = true

  data_disk_size_gb      = 40
  data_disk_datastore_id = "local-lvm"

  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
}