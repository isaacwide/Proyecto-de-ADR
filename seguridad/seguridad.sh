#!/usr/bin/env bash

seguridad_menu() {
    local opcion

    while true; do

        echo
        echo "==== Menu de Seguridad y Monitoreo ===="
        echo "1. Revisar Cacti"
        echo "2. Revisar Nagios"
        echo "3. Capturar tráfico con tshark"
        echo "4. Explorar equipos con Nmap"
        echo "5. Volver"

        read -r -p "Seleccione una opción: " opcion || return 0

        case "$opcion" in
            1) seguridad_cacti ;;
            2) seguridad_nagios ;;
            3) seguridad_captura ;;
            4) seguridad_nmap ;;
            5) return ;;
            *) echo "Opción invalida" ;;
        esac
        # Conserva el resultado en pantalla durante el uso interactivo.
        if [[ -t 0 && -t 1 ]]; then
            read -r -p "Presiona Enter para continuar..." || return 0
        fi
    done
}

# Consulta servicios; no los inicia ni modifica su configuración.
seguridad_servicio() {
    local servicio="$1" carga estado

    if ! command -v systemctl >/dev/null 2>&1; then
        echo "Esta consulta requiere Linux con systemd (no funciona en Git Bash)."
        return 2
    fi

    if ! carga=$(systemctl show "$servicio" --property=LoadState --value 2>/dev/null); then
        echo "No se pudo consultar systemd. Comprueba el entorno y los permisos."
        return 2
    fi

    if [[ "$carga" == "not-found" || -z "$carga" ]]; then
        echo "$servicio: servicio no encontrado."
        return 1
    fi

    estado=$(systemctl is-active "$servicio" 2>/dev/null)
    echo "$servicio: ${estado:-estado desconocido}"
    [[ "$estado" == "active" ]]
}

seguridad_cacti() {
    local resultado=0 codigo url="${CACTI_URL:-http://localhost/cacti/}"

    echo "=== Servicios de Cacti en Fedora ==="
    seguridad_servicio httpd || resultado=$?
    [[ "$resultado" == 2 ]] && return 2
    seguridad_servicio snmpd || resultado=$?
    [[ "$resultado" == 2 ]] && return 2

    if ! command -v curl >/dev/null 2>&1; then
        echo "Falta curl para consultar la página de Cacti."
        return 1
    fi

    case "$url" in
        http://*|https://*) ;;
        *) echo "CACTI_URL debe comenzar con http:// o https://."; return 1 ;;
    esac

    echo "Consultando: $url"
    if ! codigo=$(curl --silent --show-error --location --max-redirs 3 \
        --proto '=http,https' --proto-redir '=http,https' \
        --connect-timeout 3 --max-time 10 --output /dev/null \
        --write-out '%{http_code}' --url "$url"); then
        echo "No se pudo conectar con la página de Cacti."
        return 1
    fi

    case "$codigo" in
        2??) echo "La página respondió (HTTP $codigo)." ;;
        401|403) echo "Acceso restringido (HTTP $codigo); revisa la autenticación y los permisos."; resultado=1 ;;
        *) echo "Respuesta HTTP inesperada: $codigo"; resultado=1 ;;
    esac

    echo "Abre $url en el navegador y verifica que las gráficas tengan datos recientes."
    echo "La respuesta HTTP por sí sola no confirma que las gráficas estén actualizadas."
    return "$resultado"
}

seguridad_nagios() {
    local destino resultado=0

    echo "=== Estado de Nagios ==="
    seguridad_servicio nagios || resultado=$?
    [[ "$resultado" == 2 ]] && return 2

    read -r -p "IP o nombre de una terminal POS (Enter para volver): " destino || return "$resultado"
    [[ -z "$destino" ]] && return "$resultado"

    # Acepta direcciones y nombres, evitando opciones o expresiones de shell.
    if [[ ! "$destino" =~ ^[a-zA-Z0-9][a-zA-Z0-9.:-]*$ ]]; then
        echo "Introduce una sola IP o nombre de equipo, sin espacios."
        return 1
    fi

    if ! command -v ping >/dev/null 2>&1; then
        echo "Falta ping para comprobar conectividad."
        return 1
    fi

    echo "Comprobando conectividad con $destino..."
    if ping -c 3 -W 2 "$destino"; then
        echo "La terminal responde a ping."
    else
        echo "Sin respuesta a ping: puede haber un problema de red o un bloqueo de ICMP."
        resultado=1
    fi

    echo "Esta consulta es puntual; el monitoreo continuo de POS se configura en Nagios."
    return "$resultado"
}

seguridad_captura() {
    local archivo filtro
    local -a argumentos

    if ! command -v tshark >/dev/null 2>&1; then
        echo "tshark no está instalado o no está disponible en PATH."
        return 1
    fi

    if [[ -z "$INTERFAZ_RED" || -z "$DIR_BACKUP" ]]; then
        echo "Falta configurar INTERFAZ_RED o DIR_BACKUP."
        return 1
    fi

    # -D lista interfaces sin iniciar una captura.
    echo "Interfaces disponibles:"
    if ! tshark -D; then
        echo "No se pudieron consultar las interfaces. Revisa los permisos de captura."
        return 1
    fi

    echo "Interfaz configurada: $INTERFAZ_RED"
    read -r -p "Filtro de captura (ejemplo: tcp; Enter para todo): " filtro || return 0

    if ! mkdir -p -- "$DIR_BACKUP"; then
        echo "No se pudo crear la carpeta de capturas: $DIR_BACKUP"
        return 1
    fi

    # Un nombre único evita sobrescribir capturas anteriores.
    if ! archivo=$(mktemp --suffix=.pcap "$DIR_BACKUP/captura_pos_XXXXXXXX"); then
        echo "No se pudo crear el archivo de captura. Revisa los permisos de $DIR_BACKUP."
        return 1
    fi

    argumentos=(-i "$INTERFAZ_RED" -a duration:30 -F pcap -w "$archivo")
    if [[ -n "$filtro" ]]; then
        argumentos+=(-f "$filtro")
    fi

    echo "Capturando durante 30 segundos en $INTERFAZ_RED..."
    if tshark "${argumentos[@]}"; then
        echo "Captura guardada en: $archivo"
    else
        echo "La captura falló. Revisa la interfaz, el filtro y los permisos de captura."
        echo "Puede haber quedado un archivo vacío o parcial en: $archivo"
        return 1
    fi
}

# Valida una sola dirección IPv4, sin rangos ni opciones adicionales.
seguridad_ipv4_valida() {
    local parte
    [[ "$1" =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]] || return 1
    for parte in "${BASH_REMATCH[@]:1}"; do
        (( 10#$parte <= 255 )) || return 1
    done
}

seguridad_nmap() {
    local opcion destino prefijo

    if ! command -v nmap >/dev/null 2>&1; then
        echo "Nmap no está instalado o no está disponible en PATH."
        return 1
    fi

    echo "=== Diagnóstico con Nmap ==="
    echo "1. Buscar equipos en la subred de la tienda"
    echo "2. Revisar puertos y servicios de un equipo"
    echo "3. Volver"
    read -r -p "Seleccione una opción: " opcion || return 0

    case "$opcion" in
        1)
            if [[ -z "$SUBRED_TIENDA" ]]; then
                echo "Falta configurar SUBRED_TIENDA."
                return 1
            fi

            prefijo="${SUBRED_TIENDA##*/}"
            if [[ "$SUBRED_TIENDA" != */* || ! "$prefijo" =~ ^[0-9]{1,2}$ ]] ||
                ! seguridad_ipv4_valida "${SUBRED_TIENDA%/*}"; then
                echo "SUBRED_TIENDA debe ser una subred IPv4, por ejemplo 192.168.10.0/24."
                return 1
            fi
            if (( 10#$prefijo > 32 )); then
                echo "El prefijo de la subred debe estar entre 0 y 32."
                return 1
            fi

            echo "Buscando equipos en la red del laboratorio: $SUBRED_TIENDA"
            if ! nmap -sn "$SUBRED_TIENDA"; then
                echo "La búsqueda falló. Revisa la conexión y el mensaje de Nmap."
                return 1
            fi
            echo "Compara los equipos encontrados con el inventario de equipos autorizados."
            ;;
        2)
            read -r -p "IPv4 del equipo autorizado del laboratorio (Enter para volver): " destino || return 0
            [[ -z "$destino" ]] && return 0
            if ! seguridad_ipv4_valida "$destino"; then
                echo "Introduce una sola IPv4 válida, sin rangos ni subredes."
                return 1
            fi

            echo "Revisando puertos y versiones de servicios en $destino..."
            if ! nmap -sV "$destino"; then
                echo "El escaneo falló. Revisa la conexión y el mensaje de Nmap."
                return 1
            fi
            ;;
        3) return 0 ;;
        *) echo "Opción inválida"; return 1 ;;
    esac
}

# Permite ejecutar el módulo solo; al usar source únicamente define funciones.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    seguridad_base=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
    if [[ ! -r "$seguridad_base/config/tienda.conf" ]]; then
        echo "No se encontró la configuración: $seguridad_base/config/tienda.conf"
        exit 1
    fi
    source "$seguridad_base/config/tienda.conf" || exit 1
    unset seguridad_base
    seguridad_menu
fi
