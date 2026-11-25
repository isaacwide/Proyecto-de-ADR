# Seguridad y monitoreo

El módulo reúne consultas para Cacti, Nagios, tshark y Nmap. Está preparado
para Fedora con systemd. Las consultas no instalan herramientas ni arrancan
servicios automáticamente.

## Ejecución

Desde la raíz del repositorio:

```bash
bash main.sh
```

Selecciona `4. Seguridad`. Si `gum` no está disponible, el menú principal
ofrece las mismas opciones mediante números.

También puedes abrir el módulo directamente:

```bash
bash seguridad/seguridad.sh
```

Para cargar las funciones sin abrir el menú:

```bash
source config/tienda.conf
source seguridad/seguridad.sh
seguridad_menu
```

Guarda los scripts como UTF-8 con saltos de línea LF.

## Configuración

Confirma los valores de `config/tienda.conf` con el responsable de integración:

| Variable | Uso |
| --- | --- |
| `SUBRED_TIENDA` | Subred IPv4 del laboratorio para descubrir equipos, por ejemplo `192.168.10.0/24`. |
| `INTERFAZ_RED` | Interfaz de captura. Consulta los nombres disponibles con `tshark -D`. |
| `DIR_BACKUP` | Carpeta donde se guardan las capturas; el usuario debe poder crear archivos allí. |

Cacti se consulta por defecto en `http://localhost/cacti/`. Para otra dirección,
define `CACTI_URL` en la configuración o pásala al ejecutar el módulo:

```bash
CACTI_URL=http://localhost/cacti/ bash seguridad/seguridad.sh
```

`localhost` se refiere al equipo donde ejecutas el script.

## Opciones

1. **Cacti:** consulta los servicios `httpd` y `snmpd` y el estado HTTP de su
   página con `curl`. Abre la página en el navegador para confirmar que las
   gráficas tienen datos recientes. Una página accesible no confirma que el
   recolector de Cacti ni sus gráficas estén funcionando correctamente.
2. **Nagios:** consulta el servicio `nagios` y permite enviar tres pings a una
   terminal POS. La falta de respuesta también puede deberse a un bloqueo de
   ICMP. El monitoreo continuo y las alertas requieren configurar Nagios.
3. **tshark:** lista interfaces y captura durante 30 segundos en la interfaz
   configurada. Admite un filtro de captura opcional como `tcp` o
   `host 192.168.10.20`. Guarda un `.pcap` con nombre único en `DIR_BACKUP`.
   Si falla, informa dónde podría quedar un archivo parcial. La captura
   requiere permisos de captura y escritura en el destino.
4. **Nmap:** ofrece descubrimiento de equipos con `-sn` sobre la subred
   configurada y detección de servicios con `-sV` sobre una sola IPv4. No
   realiza un escaneo de todos los puertos. Compara los equipos descubiertos
   con el inventario de autorizados para identificar los que deban revisarse.
5. **Volver:** regresa al menú principal o termina si abriste el módulo solo.

## Dependencias y estado de validación

En Linux se necesitan `systemctl`, `curl`, `ping`, `tshark`, `nmap` y las
herramientas básicas de Bash/GNU. Cacti, Nagios, Apache y SNMP requieren
instalación y configuración en la VM para verificar su operación real.
Ejecuta capturas y escaneos en la red autorizada del laboratorio.

En Git Bash puedes revisar sintaxis y navegación. Las consultas de servicios
requieren Linux con systemd; el módulo informa cuando ese entorno falta.

Se verificó la sintaxis local y el comportamiento mediante herramientas
simuladas. Quedan pendientes las pruebas de servicios, conectividad,
capturas, escaneos y actualización de gráficas en la VM.
