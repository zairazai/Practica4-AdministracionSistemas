#!/bin/bash

source ./funciones/comunes.sh
source ./funciones/ssh.sh
source ./funciones/dns.sh

verificar_root

echo "=== MENU DE ADMINISTRACION LINUX ==="
echo "1) Configurar SSH"
echo "2) Configurar DNS"
echo "3) Salir"

read -p "Selecciona una opcion: " opcion

case $opcion in
    1)
       configurar_ssh
       ;;

    2) configurar_dns
       ;;

    3)
       echo "Saliendo..."
       exit 0
       ;;

     *)
       echo "Opcion invalida"
       ;;
esac
