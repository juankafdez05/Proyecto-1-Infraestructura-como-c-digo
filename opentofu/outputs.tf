output "ips" {
  description = "IP de cada máquina: NAT (DHCP) y red de datos (estática)"
  value = {
    for nombre, vm in libvirt_domain.maquina : nombre => {
      nat   = try(vm.network_interface[0].addresses[0], null)
      datos = local.ips_datos[nombre]
    }
  }
}
