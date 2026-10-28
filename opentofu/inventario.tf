resource "local_file" "inventario" {
  filename        = "${path.module}/../ansible/inventario"
  file_permission = "0644"

  content = templatefile("${path.module}/plantillas/inventario.tftpl", {
    usuario  = var.usuario
    maquinas = var.maquinas
    ips_nat  = { for k, vm in libvirt_domain.maquina : k => vm.network_interface[0].addresses[0] }
    grupos = {
      for g in distinct([for m in var.maquinas : m.grupo]) :
      g => [for k, m in var.maquinas : k if m.grupo == g]
    }
  })
}
