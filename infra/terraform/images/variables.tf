variable "node_name" {
  description = "Nazwa węzła Proxmox VE"
  type        = string
}

variable "image_datastore" {
  description = "Magazyn na pobrane obrazy dysków (wymaga typu zawartości import)"
  type        = string
}

variable "debian_image_version" {
  description = "Wydanie obrazu chmurowego Debian 13 (katalog z datą na cloud.debian.org)"
  type        = string
}

variable "debian_image_sha512" {
  description = "Suma kontrolna SHA-512 obrazu, z pliku SHA512SUMS wydania"
  type        = string
}