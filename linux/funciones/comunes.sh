#!/bin/bash

function verificar_root() {
  if [ "$EUID" -ne 0 ]; then
       echo "Este script debe ejecutarse como root."
       exit 1
  fi
}

function instalar_paquete() {
   paquete=$1
  apt install -y "$paquete" > /dev/null 2>&1
}

function habilitar_servicio() {
  servicio=$1
  systemctl enable "$servicio" > /dev/null 2>&1
}

function iniciar_servicio() {
  servicio=$1
  systemctl start "$servicio" > /dev/null 2>&1
}

function validar_servicio() {
  servicio=$1
  estado=$(systemctl is-active "$servicio")

  if [ "$estado" = "active" ]; then
      echo "Servicio $servicio activo correctamente."
  else
      echo "Error: el servicio $servicio no esta activo."
      exit 1
  fi
}
