# --- Wartości różne dla każdego środowiska (podawane przy uruchomieniu) ---

variable "env_name" {
  description = "Nazwa środowiska, np. env-001"
  type        = string
}

variable "vm_id" {
  description = "Identyfikator VMID środowiska"
  type        = number
}

variable "ip_address" {
  description = "Adres IPv4 z maską, np. 192.168.1.201/24"
  type        = string
}

variable "cores" {
  description = "Liczba rdzeni procesora"
  type        = number
  default     = 2
}

variable "memory_mb" {
  description = "Ilość pamięci RAM w MB"
  type        = number
  default     = 2048
}

# --- Wartości wspólne dla wszystkich środowisk (terraform.tfvars) ---

variable "node_name" {
  type = string
}

variable "template_vm_id" {
  type = number
}

variable "datastore_id" {
  type = string
}

variable "pool_id" {
  type = string
}

variable "gateway" {
  type = string
}

variable "dns_servers" {
  type = list(string)
}

variable "ssh_public_key_path" {
  description = "Ścieżka do klucza publicznego automatyzacji"
  type        = string
}