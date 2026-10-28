# Proyecto 1: Infraestructura como código

Escenario con OpenTofu (libvirt) y configuración con Ansible.

## Escenario

| Máquina | SO | Red NAT (DHCP) | Red de datos (estática) |
|---|---|---|---|
| web | Debian 13 | dinámica en 192.168.150.0/24 | 10.10.10.11/24 |
| bd | Ubuntu | dinámica en 192.168.150.0/24 | 10.10.10.12/24 |

- `p1-red-nat`: NAT con DHCP, acceso desde el equipo y salida a internet.
- `p1-red-datos`: red aislada, solo comunica `web` y `bd`.

## Requisitos
- OpenTofu >= 1.6 y libvirt/QEMU (usuario en el grupo `libvirt`)
- Imágenes cloud base de Debian 13 y Ubuntu en el pool `default`
- Una clave SSH pública

## Despliegue
```bash
cd opentofu
cp terraform.tfvars.example terraform.tfvars   # ajusta imágenes, red y clave
tofu init
tofu apply
```
Genera `ansible/inventario` automáticamente.

## Estructura
- `opentofu/`: redes, discos, cloud-init, máquinas, output e inventario
- `ansible/`: configuración (pendiente)
