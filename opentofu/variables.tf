variable "libvirt_uri" {
  description = "URI de conexión a libvirt"
  type        = string
  default     = "qemu:///system"
}

variable "pool" {
  description = "Pool de almacenamiento donde están la imagen base y los discos"
  type        = string
  default     = "default"
}

variable "imagen_base_deb" {
  description = "Nombre del volumen Debian 13 ya existente en el pool (se clona)"
  type        = string
  default     = "debian13"
}

variable "imagen_base_ubu" {
  description = "Nombre del volumen Debian 13 ya existente en el pool (se clona)"
  type        = string
  default     = "ubuntu"
}
variable "memoria_mb" {
  description = "Memoria RAM de cada máquina, en MB"
  type        = number
  default     = 1024
}

variable "vcpus" {
  description = "CPUs virtuales de cada máquina"
  type        = number
  default     = 1
}

variable "prefijo" {
  description = "Prefijo para nombrar recursos y evitar choques con otros escenarios"
  type        = string
  default     = "p1"
}

variable "usuario" {
  description = "Usuario administrador creado por cloud-init (el que usará Ansible)"
  type        = string
  default     = "debian"
}

variable "clave_publica_ssh" {
  description = "Ruta a la clave pública SSH que se autoriza en las máquinas"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "red_nat_cidr" {
  description = "Rango de la red NAT con DHCP"
  type        = string
  default     = "192.168.100.0/24"
}

variable "red_datos_prefijo" {
  description = "Longitud de prefijo de la red de datos (para las IP estáticas)"
  type        = number
  default     = 24
}

variable "maquinas" {
  description = "Máquinas del escenario. Añadir o quitar una entrada añade o quita la VM"
  type = map(object({
    grupo     = string   # grupo del inventario de Ansible
    ip_datos  = string   # IP estática en la red de datos
    mac_nat   = string   # MAC fija de la interfaz NAT
    mac_datos = string   # MAC fija de la interfaz de datos
  }))
  default = {
    web = {
      grupo     = "servidores_web"
      ip_datos  = "10.10.10.11"
      mac_nat   = "52:54:00:aa:00:01"
      mac_datos = "52:54:00:bb:00:01"
    }
    bd = {
      grupo     = "servidores_bd"
      ip_datos  = "10.10.10.12"
      mac_nat   = "52:54:00:aa:00:02"
      mac_datos = "52:54:00:bb:00:02"
    }
  }
}
