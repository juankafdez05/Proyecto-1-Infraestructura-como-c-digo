variable "pool" {
  description = "Pool de almacenamiento donde están las imágenes base y los discos"
  type        = string
  default     = "default"
}

variable "imagen_base_deb" {
  description = "Nombre del volumen Debian 13 ya existente en el pool (se clona)"
  type        = string
  default     = "debian13-base.qcow2"
}

variable "imagen_base_ubu" {
  description = "Nombre del volumen Ubuntu ya existente en el pool (se clona)"
  type        = string
  default     = "ubuntu2604-base.qcow2"
}
