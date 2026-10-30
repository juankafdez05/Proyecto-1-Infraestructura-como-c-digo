resource "libvirt_network" "nat" {
  name      = "${var.prefijo}-red-nat"
  mode      = "nat"
  addresses = [var.red_nat_cidr]
  autostart = true

  dhcp {
    enabled = true
  }

  dns {
    enabled = true
  }
}

resource "libvirt_network" "datos" {
  name      = "${var.prefijo}-red-datos"
  mode      = "none"
  autostart = true
}
