#!/bin/bash

source ./funciones/comunes.sh
source ./funciones/ssh.sh
source ./funciones/dns.sh
source ./funciones/dhcp.sh

verificar_root

echo "=== MENU DE ADMINISTRACION LINUX ==="
echo "1) Configurar SSH"
echo "2) Configurar DNS"
echo "3) Configurar DHCP"
echo "4)Salida"

read -p "Selecciona una opcion: " opcion

case $opcion in
    1)
       configurar_ssh
       ;;

    2) configurar_dns
       ;;

    3) configurar_dhcp
       ;;

    4)
       echo "Saliendo..."
       exit 0
       ;;

     *)
       echo "Opcion invalida"
       ;;
esac
