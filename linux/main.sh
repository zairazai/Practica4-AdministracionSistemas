#!/bin/bash

source ./funciones/ssh.sh

echo "=== MENU DE ADMINISTRACION LINUX ==="
echo "1) Configurar SSH"
echo "2) Salir"

read -p "Selecciona una opcion: " opcion

case $opcion in
    1)
       configurar_ssh
       ;;
    2)
       echo "Saliendo..."
       exit 0

       ;;
     *)
       echo "Opcion invalida"
       ;;
esac
