# Informe de pruebas

Todas las órdenes se lanzan desde mi equipo, en el directorio `ansible/` del repositorio, salvo que se diga otra cosa. Antes de empezar, `/etc/hosts` de mi equipo tiene `www.juanka.org` con la IP de `web` y `logs.juanka.org` con la IP de `analizador`, las dos sacadas de `tofu output`.

## Modificación 1: centralización de registros en analizador

Qué demuestra: los registros de `web` llegan solos a `analizador` por la red de datos, y allí siguen aunque se borren en `web`.

### 1.1. Una visita a la aplicación llega a analizador

* Dónde: en mi equipo, en el directorio `ansible/`
* Orden:

  ```
  curl -s -o /dev/null -w "%{http_code}\n" "http://www.juanka.org/?prueba=informe1"
  ansible analizador -m shell -a "journalctl --directory=/var/log/journal/remote -t apache-access --no-pager | grep prueba=informe1"
  ```

* Resultado esperado: el `curl` devuelve `200`, y en `analizador` aparece una línea que empieza por la fecha, seguida de `web apache-access[...]:`, y que contiene `"GET /?prueba=informe1 HTTP/1.1" 200`.

### 1.2. Si se borran los registros de web, en analizador siguen

* Dónde: en mi equipo, en el directorio `ansible/`
* Orden:

  ```
  ansible web -a "journalctl --rotate --vacuum-time=1s"
  ansible web -m shell -a "journalctl -t apache-access --no-pager | grep -c prueba=informe1 || true"
  ansible analizador -m shell -a "journalctl --directory=/var/log/journal/remote -t apache-access --no-pager | grep -c prueba=informe1"
  ```

* Resultado esperado: la primera orden muestra líneas `Deleted archived journal ...`. En `web` la cuenta es `0`: ya no queda esa visita. En `analizador` la cuenta es `1`: la copia central sigue.

## Modificación 2: análisis de las visitas con Matomo

Qué demuestra: Matomo está instalado y responde en `logs.juanka.org`, y las visitas al libro de visitas entran en Matomo y quedan guardadas en la base de datos de `bd`.

### 2.1. Matomo responde en su nombre

* Dónde: en mi equipo
* Orden:

  ```
  curl -s http://logs.juanka.org | grep -o "<title>[^<]*"
  ```

* Resultado esperado: `<title>Sign in - Matomo`, que es la pantalla de inicio de sesión. Significa que el asistente de instalación ya lo completó la receta.

### 2.2. Las visitas al libro de visitas quedan registradas en Matomo

* Dónde: en mi equipo, en el directorio `ansible/`
* Orden (la importación la lanza un temporizador cada 5 minutos; aquí la lanzamos a mano):

  ```
  for i in 1 2 3; do curl -s -o /dev/null -w "%{http_code}\n" "http://www.juanka.org/?prueba=informe2"; done
  ansible analizador -a "systemctl start matomo-importar.service"
  ansible bd -a "mariadb -e \"SELECT name FROM matomo.matomo_log_action WHERE name LIKE '%prueba=informe2%'\""
  ```

* Resultado esperado: tres `200`. En `bd` sale al menos una fila con `www.juanka.org/?prueba=informe2`, que es la página visitada tal como la ha guardado Matomo en su base de datos.

## Modificación 3: copias de seguridad semanales en un disco aparte

Qué demuestra: la copia se guarda en el disco extra de `analizador`, y con ella se recuperan los mensajes del libro de visitas si se pierden.

### 3.1. La copia se hace y se guarda en el disco de copias

* Dónde: en mi equipo, en el directorio `ansible/`
* Orden (la copia la lanza un temporizador los domingos a las 00:00; aquí la lanzamos a mano):

  ```
  ansible analizador -a "systemctl start copia-seguridad.service"
  ansible analizador -m shell -a "findmnt -n -o SOURCE,TARGET /backups; ls /backups/registros /backups/mariadb"
  ```

* Resultado esperado: `/dev/vdb /backups` (el disco extra montado), y en cada carpeta un fichero con la fecha y la hora de hoy: `registros-AAAA-MM-DD_HHMMSS.export.gz` y `guestbook-AAAA-MM-DD_HHMMSS.sql.gz`.

### 3.2. Con la copia se recuperan los mensajes borrados

* Dónde: en mi equipo, en el directorio `ansible/`
* Orden:

  ```
  ansible bd -a "mariadb -e 'SELECT COUNT(*) AS mensajes FROM guestbook.messages; DELETE FROM guestbook.messages; SELECT COUNT(*) AS mensajes FROM guestbook.messages'"
  ansible analizador -m shell -a 'cp $(ls -t /backups/mariadb/*.sql.gz | head -1) /tmp/ultima.sql.gz'
  ansible analizador -m fetch -a "src=/tmp/ultima.sql.gz dest=/tmp/ultima.sql.gz flat=yes"
  ansible bd -m copy -a "src=/tmp/ultima.sql.gz dest=/tmp/ultima.sql.gz"
  ansible bd -m shell -a "zcat /tmp/ultima.sql.gz | mariadb && mariadb -e 'SELECT COUNT(*) AS mensajes FROM guestbook.messages'"
  ```

* Resultado esperado: la primera orden muestra `mensajes` con el número de mensajes que hay (como mínimo 1, el que se publica en la prueba común) y después `0`. La última orden vuelve a mostrar el mismo número del principio. Al recargar `http://www.juanka.org` en el navegador, los mensajes vuelven a aparecer.
