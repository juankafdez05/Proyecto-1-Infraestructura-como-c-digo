output "ips" {
  description = "IP de cada máquina: NAT (DHCP) y red de datos (estática)"
  value = {
    for nombre, vm in libvirt_domain.maquina : nombre => {
      nat   = vm.network_interface[0].addresses[0]
      datos = var.maquinas[nombre].ip_datos
    }
  }
}
