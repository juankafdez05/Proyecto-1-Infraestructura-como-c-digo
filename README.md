# Proyecto 1: Infraestructura como código

Escenario con **OpenTofu** (libvirt/KVM) configurado con **Ansible** para poner en
producción un libro de visitas en PHP con MariaDB (`guestbook_php`).

Repositorio: https://github.com/juankafdez05/Proyecto-1-Infraestructura-como-c-digo

## Escenario

```
                 Equipo anfitrión
                        |
          p1-red-nat (NAT + DHCP, 192.168.150.0/24)
              |                         |
        +-----------+             +-----------+
        |    web    |             |    bd     |
        | Debian 13 |             |  Ubuntu   |
        |           |             |   26.04   |
        | Apache+PHP|             |  MariaDB  |
        +-----------+             +-----------+
              |                         |
              +--- p1-red-datos (aislada, 10.10.10.0/24) ---+
         10.10.10.11                10.10.10.12
```

| Máquina | SO | Red NAT (DHCP) | Red de datos (estática) |
|---|---|---|---|
| web | Debian 13 | 192.168.150.0/24 | 10.10.10.11/24 |
| bd | Ubuntu 26.04 | 192.168.150.0/24 | 10.10.10.12/24 |

- `p1-red-nat`: acceso desde el equipo anfitrión y salida a internet.
- `p1-red-datos`: red aislada, solo comunica `web` y `bd`.
- Las máquinas son clones ligeros (qcow2 con imagen base) configurados con cloud-init.

## Requisitos

- OpenTofu >= 1.6 y libvirt/QEMU (usuario en el grupo `libvirt`)
- Imágenes cloud base de Debian 13 y Ubuntu 26.04 en el pool `default`
- Ansible y la colección `community.mysql`
- Una clave SSH pública, escrita en los ficheros `opentofu/cloud-init/user-data-*.yaml`

## Despliegue

```bash
cd opentofu
# Opcional: cp terraform.tfvars.example terraform.tfvars para cambiar los valores por defecto
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

- OpenTofu (`opentofu/variables.tf`): solo el pool y las imágenes base
  (`imagen_base_deb`, `imagen_base_ubu`). La lista de máquinas está en `main.tf`
  (`local.maquinas`) y su configuración en `opentofu/cloud-init/`.
- Ansible (`ansible/group_vars/`): paquetes comunes, nombre de la base de datos,
  usuario y contraseña, nombre del virtual host y repositorio de la aplicación.

## Configuración con cloud-init

Cada máquina tiene dos ficheros en `opentofu/cloud-init/`, que OpenTofu graba en
su ISO de cloud-init:

- `user-data-<máquina>.yaml`: hostname, usuario, clave SSH, zona horaria, idioma y paquetes.
- `network-config-<máquina>.yaml`: DHCP en `ens3` (red NAT) e IP estática en `ens4`
  (red de datos). OpenTofu lee de aquí la IP de datos para generar el inventario.

cloud-init deja el sistema base listo y Ansible instala después los servicios;
`site.yaml` espera a que cloud-init termine antes de empezar.

Las tarjetas se identifican por su nombre, así que las MAC no son fijas y la IP de
la red NAT puede cambiar entre despliegues. La zona horaria, el idioma, el usuario y
la clave están repetidos en cada `user-data`: si cambian, hay que cambiarlos en todos.

Detalles de los ficheros `user-data`:

- `bootcmd` activa el idioma en `/etc/locale.gen` antes del módulo `locale`. En
  Debian es necesario: `locale-gen` solo genera los locales activos en ese
  fichero y, sin este paso, cloud-init termina con error y `site.yaml` se detiene.
- `runcmd` arranca `qemu-guest-agent`, porque en Debian no arranca solo al
  instalarlo durante el primer arranque.
- `packages` es para lo que el sistema necesita antes de Ansible. Los paquetes
  comunes siguen en el rol `commons` (`paquetes_comunes`).

cloud-init solo aplica esta configuración en el primer arranque de cada instancia.
Para aplicar un cambio de estos ficheros en un escenario ya creado, reconstrúyelo:

```bash
cd opentofu
tofu destroy
tofu apply
cd ../ansible
ansible-playbook site.yaml
```

## Qué hace cada rol

- `commons`: actualiza el sistema e instala los paquetes comunes.
- `bd`: instala MariaDB escuchando solo en la red de datos, crea la base de datos,
  un usuario con permisos `SELECT` e `INSERT` que solo puede conectarse desde la
  IP de `web`, e importa las tablas de forma idempotente.
- `web`: instala Apache con PHP, activa `rewrite`, crea el virtual host, descarga
  la aplicación y genera `config.php` desde una plantilla.

## Comprobaciones

- `cloud-init status` muestra `done` en `web` y `bd`, con la zona horaria y el
  idioma configurados en OpenTofu.
- Segunda ejecución de `ansible-playbook site.yaml`: `changed=0`.
- La base de datos solo acepta conexiones desde `web`.
- `tofu destroy`, `tofu apply` y `ansible-playbook site.yaml` reconstruyen el
  escenario completo.

## Estructura

- `opentofu/`: redes, discos, máquinas, output e inventario.
- `opentofu/cloud-init/`: ficheros de cloud-init de cada máquina (`user-data` y `network-config`).
- `ansible/`: `site.yaml`, roles `commons`, `bd` y `web`, y `group_vars/`.
