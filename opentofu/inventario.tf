resource "local_file" "inventario" {
  filename        = "${path.module}/../ansible/inventario"
  file_permission = "0644"

  content = templatefile("${path.module}/plantillas/inventario.tftpl", {
    ips_nat   = { for k, vm in libvirt_domain.maquina : k => try(vm.network_interface[0].addresses[0], "") }
    ips_datos = local.ips_datos
  })
}
