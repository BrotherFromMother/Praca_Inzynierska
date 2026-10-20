# Środowisko użytkownika: klon połączony szablonu Debian 13.
# Konfiguracja dostępu (konto, klucz, sieć) przekazywana przez cloud-init.
resource "proxmox_virtual_environment_vm" "this" {
  name        = var.name
  description = "Srodowisko platformy samoobslugowej, zarzadzane przez Terraform"
  tags        = ["portal", "terraform"]

  node_name = var.node_name
  vm_id     = var.vm_id
  pool_id   = var.pool_id

  on_boot         = false
  started         = true
  stop_on_destroy = true

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"

  clone {
    vm_id = var.template_vm_id
    full  = false
  }

  operating_system {
    type = "l26"
  }

  cpu {
    cores = var.cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.memory_mb
  }

  agent {
    enabled = false
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  serial_device {}

  initialization {
    datastore_id = var.datastore_id

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_account {
      username = var.ssh_username
      keys     = [var.ssh_public_key]
    }
  }
}