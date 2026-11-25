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
        done
}

seguridad_cacti() {
    echo "Pendiente : revisar sevicios y gráficas de Cacti. "
}

seguridad_nagios() {
    echo "Pendiente: revisar nagios y conectividad de terminales POS."   # Aquí puedes agregar el código para revisar Nagios
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

seguridad_nmap() {
    if ! command -v nmap >/dev/null 2>&1; then
        echo "Nmap no está instalado o no está disponible en PATH."
        return 1
    fi

    if [[ -z "$SUBRED_TIENDA" ]]; then
        echo "Falta configurar SUBRED_TIENDA."
        return 1
    fi

    echo "Buscando equipos en: $SUBRED_TIENDA"
    nmap -sn "$SUBRED_TIENDA"
}
