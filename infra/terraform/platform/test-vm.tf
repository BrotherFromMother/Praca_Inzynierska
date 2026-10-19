# Maszyna testowa etapu 3: weryfikacja łańcucha Terraform -> cloud-init -> Ansible.
# Plik zostanie usunięty po zakończeniu testu, a maszyna razem z nim.
resource "proxmox_virtual_environment_vm" "test_clone" {
  name        = "test-debian13"
  description = "Maszyna testowa etapu 3 (klon szablonu), zarzadzana przez Terraform"
  tags        = ["debian13", "terraform", "test"]

  node_name = var.node_name
  vm_id     = 2999
  pool_id   = proxmox_virtual_environment_pool.portal.pool_id

  on_boot         = false
  started         = true
  stop_on_destroy = true

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"

  clone {
    vm_id = proxmox_virtual_environment_vm.debian13_template.vm_id
    full  = false

  }

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

  agent {
    enabled = false
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  serial_device {}

  # Konfiguracja przekazywana do cloud-init przy pierwszym uruchomieniu.
  initialization {
    datastore_id = var.template_datastore

    ip_config {
      ipv4 {
        address = "192.168.1.200/24"
        gateway = "192.168.1.1"
      }
    }

    dns {
      servers = ["192.168.1.1"]
    }

    user_account {
      username = "ansible"
      keys     = [trimspace(file(pathexpand("~/.ssh/homelab_ed25519.pub")))]
    }
  }
}