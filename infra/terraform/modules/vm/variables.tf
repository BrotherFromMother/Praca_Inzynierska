# --- Tożsamość maszyny ---

variable "name" {
  description = "Nazwa maszyny (nazwa w Proxmox i nazwa hosta)"
  type        = string
}

variable "vm_id" {
  description = "Identyfikator VMID (100–199 platforma, 2000–2999 środowiska testowe)"
  type        = number

  validation {
    condition     = var.vm_id >= 100 && var.vm_id < 9000
    error_message = "VMID musi należeć do zakresu 100–8999 (9000 i wyżej to szablony)."
  }
}

variable "description" {
  description = "Opis maszyny widoczny w Proxmox"
  type        = string
  default     = "Maszyna zarzadzana przez Terraform"
}

variable "tags" {
  description = "Etykiety maszyny w Proxmox"
  type        = list(string)
  default     = ["terraform"]
}

# --- Sieć ---

variable "ip_address" {
  description = "Adres IPv4 z maską, np. 192.168.1.40/24"
  type        = string
}

variable "gateway" {
  description = "Brama domyślna"
  type        = string
}

variable "dns_servers" {
  description = "Lista serwerów DNS"
  type        = list(string)
}

# --- Zasoby ---

variable "cores" {
  description = "Liczba rdzeni procesora"
  type        = number
  default     = 2

  validation {
    condition     = var.cores >= 1 && var.cores <= 4
    error_message = "Liczba rdzeni musi należeć do zakresu 1–4."
  }
}

variable "memory_mb" {
  description = "Ilość pamięci RAM w MB"
  type        = number
  default     = 2048

  validation {
    condition     = var.memory_mb >= 1024 && var.memory_mb <= 8192
    error_message = "Pamięć RAM musi należeć do zakresu 1024–8192 MB."
  }
}

# --- Klonowanie i umieszczenie ---

variable "node_name" {
  description = "Nazwa węzła Proxmox VE"
  type        = string
}

variable "template_vm_id" {
  description = "VMID szablonu, z którego klonowana jest maszyna"
  type        = number
}

variable "full_clone" {
  description = "Pełny klon (niezależny od szablonu) zamiast klonu połączonego"
  type        = bool
  default     = false
}

variable "clone_datastore_id" {
  description = "Magazyn dysku pełnego klonu; dla klonu połączonego musi być pusty"
  type        = string
  default     = null

  validation {
    condition     = var.full_clone == (var.clone_datastore_id != null)
    error_message = "Magazyn podaje się wyłącznie dla pełnego klonu; klon połączony pozostaje w magazynie szablonu."
  }
}

variable "datastore_id" {
  description = "Magazyn napędu cloud-init"
  type        = string
}

variable "pool_id" {
  description = "Pula zasobów; brak oznacza maszynę poza pulą"
  type        = string
  default     = null
}

variable "on_boot" {
  description = "Automatyczne uruchamianie po starcie hypervisora"
  type        = bool
  default     = false
}

# --- Dostęp ---

variable "ssh_username" {
  description = "Nazwa konta tworzonego przez cloud-init"
  type        = string
  default     = "ansible"
}

variable "ssh_public_key" {
  description = "Klucz publiczny SSH konta automatyzacji"
  type        = string
}