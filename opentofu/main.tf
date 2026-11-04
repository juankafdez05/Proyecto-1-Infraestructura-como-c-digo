locals {
  # Máquinas del escenario y la imagen que clona cada una.
  # El resto de su configuración está en la carpeta cloud-init/
  maquinas = {
    web = var.imagen_base_deb
    bd  = var.imagen_base_ubu
  }

  # La IP de datos se escribe solo en cloud-init: aquí se lee de cada fichero
  ips_datos = {
    for nombre, imagen in local.maquinas : nombre => split("/",
      yamldecode(file("${path.module}/cloud-init/network-config-${nombre}.yaml")).ethernets.ens4.addresses[0]
    )[0]
  }
}

# Disco de cada VM: clon ligero (backing file) de su imagen base
resource "libvirt_volume" "disco" {
  for_each = local.maquinas

  name             = "p1-${each.key}.qcow2"
  pool             = var.pool
  base_volume_name = each.value
  base_volume_pool = var.pool
  format           = "qcow2"
}

# ISO de cloud-init de cada VM
resource "libvirt_cloudinit_disk" "init" {
  for_each = local.maquinas

  name           = "p1-${each.key}-init.iso"
  pool           = var.pool
  user_data      = file("${path.module}/cloud-init/user-data-${each.key}.yaml")
  network_config = file("${path.module}/cloud-init/network-config-${each.key}.yaml")
}

# Las máquinas virtuales
resource "libvirt_domain" "maquina" {
  for_each = local.maquinas

  name      = "p1-${each.key}"
  memory    = 1024
  vcpu      = 1
  cloudinit = libvirt_cloudinit_disk.init[each.key].id

  # Interfaz 0 (ens3): NAT con DHCP. Se espera a que tenga IP para poder mostrarla.
  network_interface {
    network_id     = libvirt_network.nat.id
    wait_for_lease = true
  }

  # Interfaz 1 (ens4): red de datos (IP estática, no hay DHCP que esperar)
  network_interface {
    network_id = libvirt_network.datos.id
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
