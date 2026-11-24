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
	clear
	OPCION=$(gum choose \
  	--cursor="➜ " \
  	--cursor.foreground="212" \
  	--header=" Seleciona una opcion  " \
  	--header.foreground="99" \
  	"1. Gestion " \
  	"2. Tareas" \
  	"3. Respaldo" \
  	"4. Seguridad"\
	"5. Salir")

	case "$OPCION" in

  	*"Gestion"*) 
    		#función  gestion.sh
    		echo "Entrando a Gestión..."
   	;;
  	*"Tareas"*) 
    		#función de tareas.sh
    		echo "Entrando a Tareas..."
    	;;
  	*"Respaldo"*) 
		echo "Entrando en Respaldo "
    	;;
  	*"Seguridad"*) 
    		# Aquí llamas a la función de seguridad.sh
   		 echo "Entrando a Seguridad..."
    	;;
	*"Salir"*)
            echo "Saliendo del sistema..."
            exit 0
        ;;
	esac
done
