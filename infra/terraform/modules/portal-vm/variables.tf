variable "name" {
  description = "Nazwa środowiska (nazwa maszyny i nazwa hosta)"
  type        = string
}

variable "vm_id" {
  description = "Identyfikator VMID środowiska (zakres 2000–2999)"
  type        = number

  validation {
    condition     = var.vm_id >= 2000 && var.vm_id <= 2999
    error_message = "VMID środowiska musi należeć do zakresu 2000–2999."
  }
}

variable "ip_address" {
  description = "Adres IPv4 z maską, np. 192.168.1.201/24"
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

variable "node_name" {
  description = "Nazwa węzła Proxmox VE"
  type        = string
}

variable "template_vm_id" {
  description = "VMID szablonu, z którego klonowane jest środowisko"
  type        = number
}

variable "datastore_id" {
  description = "Magazyn napędu cloud-init (ten sam co szablonu, ADR-003)"
  type        = string
}

variable "pool_id" {
  description = "Pula zasobów, do której trafia środowisko"
  type        = string
}

variable "ssh_username" {
  description = "Nazwa konta tworzonego przez cloud-init"
  type        = string
  default     = "ansible"
}

variable "ssh_public_key" {
  description = "Klucz publiczny SSH konta automatyzacji"
  type        = string
}