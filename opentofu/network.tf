resource "libvirt_network" "nat" {
  name      = "p1-red-nat"
  mode      = "nat"
  addresses = ["192.168.150.0/24"]
  autostart = true

  dhcp {
    enabled = true
  }

  dns {
    enabled = true
  }
}

resource "libvirt_network" "datos" {
  name      = "p1-red-datos"
  mode      = "none"
  autostart = true
}
