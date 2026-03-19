#!/bin/bash


mostrar_mensaje(){
  local tipo="$1"
  local mensaje="$2"

  case "$tipo" in
       INFO) echo "[INFO] $mensaje" ;;
       OK) echo "[OK] $mensaje" ;;
       ERROR) echo "[ERROR] $mensaje" ;;
       WARN) echo "[WARN] $mensaje" ;;
       *) echo "$mensaje" ;;
  esac
}

validar_ip() {

  local ip="$1"

  if ! [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
      return 1
  fi

  IFS='.' read -r o1 o2 o3 o4 <<< "$ip"

  for octeto in "$o1" "$o2" "$o3" "$o4"; do
      if (( octeto < 0 || octeto > 255 )); then
          return 1
      fi
  done
  return 0
}

pedir_ip(){

  local mensaje="$1"
  local valor

  while true; do
      read -r -p "$mensaje: " valor
      if validar_ip "$valor"; then
         echo "$valor"
         return
      else
         mostrar_mensaje "ERROR" "IPv4 inválida. Intenta de nuevo."
      fi
  done
}

verificar_root(){

  if [[ $EUID -ne 0 ]]; then
       mostrar_mensaje "ERROR" "Este script debe ejecutarse con sudo."
       exit 1
  fi
}

function instalar_paquete() {
  local paquete="$1"
  apt install -y "$paquete" > /dev/null 2>&1
}

function habilitar_servicio() {
  local servicio="$1"
  systemctl enable "$servicio" >dev/null 2>&1
}

function iniciar_servicio() {
  local servicio="$1"
  systemctl start "$servicio" > /dev/null 2>&1
}

function validar_servicio() {
  local servicio="$1"
  local estado
  estado=$(systemctl is-active "$servicio")

  if [ "$estado" = "active" ]; then
     echo "Servicio $servicio activo correctamente."
  else
     echo "Error: el servicio $servicio no esta activo."
     exit 1
  fi
}




















