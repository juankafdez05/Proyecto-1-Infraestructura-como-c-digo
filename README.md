# Proyecto 1: Infraestructura como código

Escenario con **OpenTofu** (libvirt/KVM) configurado con **Ansible** para poner en
producción un libro de visitas en PHP con MariaDB (`guestbook_php`).

## Escenario

```
                 Equipo anfitrión
                        |
          p1-red-nat (NAT + DHCP, 192.168.150.0/24)
              |                         |
        +-----------+             +-----------+
        |    web    |             |    bd     |
        | Debian 13 |             |  Ubuntu   |
        | Apache+PHP|             |  MariaDB  |
        +-----------+             +-----------+
              |                         |
              +--- p1-red-datos (aislada, 10.10.10.0/24) ---+
         10.10.10.11                10.10.10.12
```

| Máquina | SO | Red NAT (DHCP) | Red de datos (estática) |
|---|---|---|---|
| web | Debian 13 | 192.168.150.0/24 | 10.10.10.11/24 |
| bd | Ubuntu | 192.168.150.0/24 | 10.10.10.12/24 |

- `p1-red-nat`: acceso desde el equipo anfitrión y salida a internet.
- `p1-red-datos`: red aislada, solo comunica `web` y `bd`.
- Las máquinas son clones ligeros (qcow2 con imagen base) configurados con cloud-init.

## Requisitos

- OpenTofu >= 1.6 y libvirt/QEMU (usuario en el grupo `libvirt`)
- Imágenes cloud base de Debian 13 y Ubuntu en el pool `default`
- Ansible y la colección `community.mysql`
- Una clave SSH pública (`~/.ssh/id_ed25519.pub` por defecto)

## Despliegue

```bash
cd opentofu
cp terraform.tfvars.example terraform.tfvars   # ajusta imágenes, red y clave
tofu init
tofu apply

cd ../ansible
ansible-galaxy collection install -r requirements.yml   # solo la primera vez
ansible-playbook site.yaml
```

`tofu apply` genera `ansible/inventario` con las IP del escenario (grupos
`servidores_web` y `servidores_bd`), nunca se escribe a mano.

Para acceder a la aplicación por su nombre, añade al `/etc/hosts` del equipo la
IP NAT de `web` (sale en `tofu output`) con el nombre definido en
`ansible/group_vars/servidores_web.yaml` (`web_servername`).

## Variables

- OpenTofu (`opentofu/variables.tf`): imágenes base (`imagen_base_deb`,
  `imagen_base_ubu`), memoria (`memoria_mb`), CPUs, rango de la red NAT, clave
  SSH y el mapa `maquinas` (añadir o quitar una entrada añade o quita la VM).
- Ansible (`ansible/group_vars/`): paquetes comunes, nombre de la base de datos,
  usuario y contraseña, nombre del virtual host y repositorio de la aplicación.

## Qué hace cada rol

- `commons`: actualiza el sistema e instala los paquetes comunes.
- `bd`: instala MariaDB escuchando solo en la red de datos, crea la base de datos,
  un usuario con permisos `SELECT` e `INSERT` que solo puede conectarse desde la
  IP de `web`, e importa las tablas de forma idempotente.
- `web`: instala Apache con PHP, activa `rewrite`, crea el virtual host, descarga
  la aplicación y genera `config.php` desde una plantilla.

## Comprobaciones

- Segunda ejecución de `ansible-playbook site.yaml`: `changed=0`.
- La base de datos solo acepta conexiones desde `web`.
- `tofu destroy`, `tofu apply` y `ansible-playbook site.yaml` reconstruyen el
  escenario completo.

## Estructura

- `opentofu/`: redes, discos, cloud-init, máquinas, output e inventario.
- `ansible/`: `site.yaml`, roles `commons`, `bd` y `web`, y `group_vars/`.
