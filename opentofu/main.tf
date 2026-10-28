locals {
  clave_ssh = trimspace(file(pathexpand(var.clave_publica_ssh)))

  # Traduce la etiqueta de cada máquina ("debian"/"ubuntu") al volumen base real
  imagenes = {
    debian = var.imagen_base_deb
    ubuntu = var.imagen_base_ubu
  }
}

# Disco de cada VM: clon ligero (backing file) de su imagen base
resource "libvirt_volume" "disco" {
  for_each = var.maquinas

  name             = "${var.prefijo}-${each.key}.qcow2"
  pool             = var.pool
  base_volume_name = local.imagenes[each.value.imagen]
  base_volume_pool = var.pool
  format           = "qcow2"
}

# ISO de cloud-init de cada VM
resource "libvirt_cloudinit_disk" "init" {
  for_each = var.maquinas

  name = "${var.prefijo}-${each.key}-init.iso"
  pool = var.pool

  user_data = templatefile("${path.module}/plantillas/user-data.tftpl", {
    hostname  = each.key
    usuario   = var.usuario
    clave_ssh = local.clave_ssh
  })

  network_config = templatefile("${path.module}/plantillas/network-config.tftpl", {
    mac_nat       = each.value.mac_nat
    mac_datos     = each.value.mac_datos
    ip_datos      = each.value.ip_datos
    prefijo_datos = var.red_datos_prefijo
  })
}

# Las máquinas virtuales
resource "libvirt_domain" "maquina" {
  for_each = var.maquinas

  name      = "${var.prefijo}-${each.key}"
  memory    = var.memoria_mb
  vcpu      = var.vcpus
  cloudinit = libvirt_cloudinit_disk.init[each.key].id

  # Interfaz 0: NAT con DHCP. Se espera a que tenga IP para poder mostrarla.
  network_interface {
    network_id     = libvirt_network.nat.id
    mac            = each.value.mac_nat
    wait_for_lease = true
  }

  # Interfaz 1: red de datos (IP estática, no hay DHCP que esperar)
  network_interface {
    network_id = libvirt_network.datos.id
    mac        = each.value.mac_datos
  }

  disk {
    volume_id = libvirt_volume.disco[each.key].id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "spice"
    listen_type = "none"
    autoport    = true
  }
}
