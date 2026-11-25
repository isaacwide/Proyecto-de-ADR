#!/usr/bin/env bash

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FECHA=$(date +"%Y-%m-%d")

# 1. Cargar configuración e interfaz
source "$BASE_DIR/config/tienda.conf"

# 2. Cargamos los modulos
source "$BASE_DIR/gestion/gestion.sh"
source "$BASE_DIR/tareas/tareas.sh"
source "$BASE_DIR/respaldo/respaldo.sh"
source "$BASE_DIR/seguridad/seguridad.sh"


while true; do
    [[ -t 1 ]] && clear
    if command -v gum >/dev/null 2>&1 && [[ -t 0 && -t 1 ]]; then
    OPCION=$(gum choose \
      --cursor="➜ " \
      --cursor.foreground="212" \
      --header=" Seleciona una opcion  " \
      --header.foreground="99" \
      "1. Gestion " \
      "2. Tareas" \
      "3. Respaldo" \
      "4. Seguridad"\
    "5. Salir") || break
    else
        printf '\n1. Gestion\n2. Tareas\n3. Respaldo\n4. Seguridad\n5. Salir\n'
        read -r -p "Seleccione una opción: " OPCION || break
    fi

    case "$OPCION" in

      1|*"Gestion"*)
            #función  gestion.sh
            echo "Entrando a Gestión..."
       ;;
      2|*"Tareas"*)
            #función de tareas.sh
            echo "Entrando a Tareas..."
        ;;
      3|*"Respaldo"*)
        echo "Entrando en Respaldo "
        ;;
      4|*"Seguridad"*)
            seguridad_menu
        ;;
    5|*"Salir"*)
            echo "Saliendo del sistema..."
            exit 0
        ;;
    *) echo "Opción inválida" ;;
    esac
done
