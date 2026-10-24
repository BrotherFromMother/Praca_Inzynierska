# Maszyna wirtualna klonowana z szablonu Debian 13 (ADR-013).
# Konfiguracja dostępu (konto, klucz, sieć) przekazywana przez cloud-init.
resource "proxmox_virtual_environment_vm" "this" {
  name        = var.name
  description = var.description
  tags        = var.tags

  node_name = var.node_name
  vm_id     = var.vm_id
  pool_id   = var.pool_id

  on_boot         = var.on_boot
  started         = true
  stop_on_destroy = true

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"

  clone {
    vm_id        = var.template_vm_id
    full         = var.full_clone
    datastore_id = var.clone_datastore_id
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

  # Opcjonalny dysk danych (scsi1), tworzony tylko gdy podano rozmiar.
  dynamic "disk" {
    for_each = var.data_disk_size_gb == null ? [] : [var.data_disk_size_gb]

    content {
      datastore_id = var.data_disk_datastore_id
      interface    = "scsi1"
      size         = disk.value
      file_format  = "raw"
      discard      = "on"
      iothread     = true
    }
  }

  initialization {
    datastore_id = var.datastore_id
    upgrade      = false

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