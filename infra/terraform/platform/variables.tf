variable "node_name" {
  description = "Nazwa węzła Proxmox VE"
  type        = string
}

variable "template_vm_id" {
  description = "Identyfikator VMID szablonu maszyny wirtualnej"
  type        = number
}

variable "template_datastore" {
  description = "Magazyn dysku szablonu i jego klonów (ADR-003)"
  type        = string
}

variable "debian13_image_id" {
  description = "Identyfikator obrazu Debian 13 w magazynie (wynik konfiguracji images)"
  type        = string
}
variable "gateway" {
  description = "Brama domyślna sieci"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Ścieżka do klucza publicznego automatyzacji"
  type        = string
}