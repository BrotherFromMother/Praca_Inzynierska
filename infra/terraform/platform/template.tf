# Szablon maszyny wirtualnej z systemem Debian 13 (ADR-009).
# Dysk tworzony z obrazu chmurowego pobranego przez konfigurację images.
resource "proxmox_virtual_environment_vm" "debian13_template" {
  name        = "tpl-debian13"
  description = "Szablon Debian 13 (genericcloud), zarzadzany przez Terraform"
  tags        = ["debian13", "template", "terraform"]

  node_name = var.node_name
  vm_id     = var.template_vm_id

  template = true
  started  = false

  machine = "q35"

  operating_system {
    type = "l26"
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 2048
  }

  # Agent gościa wyłączony: obraz genericcloud nie zawiera qemu-guest-agent.
  # Agent zostanie zainstalowany przez Ansible.
  agent {
    enabled = false
  }

  scsi_hardware = "virtio-scsi-single"

  disk {
    datastore_id = var.template_datastore
    import_from  = var.debian13_image_id
    interface    = "scsi0"
    file_format  = "qcow2"
    size         = 10
    discard      = "on"
    iothread     = true
  }

  # Napęd cloud-init: konto, klucz SSH i sieć ustawiane w klonach.
  initialization {
    datastore_id = var.template_datastore

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Port szeregowy wymagany przez obrazy chmurowe Debiana
  # (błąd jądra przy powiększaniu dysku bez portu szeregowego).
  serial_device {}
}