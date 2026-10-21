# Kontroler domeny Samba AD (ad.homelab.internal), ADR-012.
# Pełny klon na local-lvm: usługa krytyczna niezależna od NAS i szablonu (ADR-003).
module "dc1" {
  source = "../modules/vm"

  name        = "dc1"
  vm_id       = 100
  description = "Kontroler domeny Samba AD (ad.homelab.internal), zarzadzany przez Terraform"
  tags        = ["dc", "samba-ad", "terraform"]

  ip_address = "192.168.1.40/24"
  gateway    = var.gateway
  # Najpierw sam dc1 (po instalacji Samby), zapasowo router.
  dns_servers = ["192.168.1.40", "192.168.1.1"]

  cores     = 2
  memory_mb = 2048

  node_name          = var.node_name
  template_vm_id     = proxmox_virtual_environment_vm.debian13_template.vm_id
  full_clone         = true
  clone_datastore_id = "local-lvm"
  datastore_id       = "local-lvm"
  on_boot            = true

  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
}