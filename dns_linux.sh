#!/bin/bash

CONFIG_LOCAL="/etc/bind/named.conf.local"
ZONE_DIR="/var/cache/bind"
SERVICE_NAME="bind9"

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

verificar_instalacion(){

  mostrar_mensaje "INFO" "Verificando instalación de BIND9..."

  if dpkg -s bind9 > /dev/null 2>&1; then
     mostrar_mensaje "OK" "bind9 ya está instalado."
  else
     mostrar_mensaje "WARN" "bind9 no está instalado. Instalando..."
     apt update -qq > /dev/null 2>&1
     apt install -y bind9utils bind9-doc >/dev/null 2>&1

     if dpkg -s bind9 > /dev/null 2>&1;then
        mostrar_mensaje "OK" "bind9 se instaló exitosamente."
     else
        mostrar_mensaje "ERROR" "No se pudo instalar bind9."

         exit 1
     fi
  fi
}

detectar_interfaz(){

  mostrar_mensaje "INFO" "Interfaces disponibles:"
  ip -brief addr show | awk '{print " - " $1 " -> " $3}'

  while true; do
      read -r -p "Ingresa la interfaz de red interna (ej. enp0s8) : " INTERFAZ
      if ip link show "$INTERFAZ" > /dev/null 2>&1; then
          mostrar_mensaje "OK" "Interfaz $INTERFAZ seleccionada."
          break
      else
          mostrar_mensaje "ERROR" "La interfaz no existe. Intenta nuevamente."
      fi
  done
}

verificar_ip_fija(){

  local estado
  estado=$(ip -4 addr show "$INTERFAZ" | grep "inet ")

  if echo "$estado" | grep -q "dynamic"; then
     mostrar_mensaje "WARN" "La interfaz $INTERFAZ tiene IP dinámica."

     while true; do
         read -r -p "¿Deseas asignar IP fija ahora? (s/n): " RESPUESTA
         case "$RESPUESTA" in
               s|S)
                   IP_FIJA=$(pedir_ip "Ingresa la IP fija para el servidor DNS")
                   MASCARA=$(pedir_ip "Ingresa la máscara de red")
                   GATEWAY=$(pedir_ip "Ingresa la puerta de enlace")
                   mostrar_mensaje "INFO" "La configuración de IP fija puede depender del gestor de red (Netplan o NetworkManager)."
                   mostrar_mensaje "INFO" "Realiza la asignación manual si es necesario."
                   break
                   ;;
               n|N)
                   mostrar_mensaje "WARN" "Se continuará usando la IP actual de la interfaz."
                   break
                   ;;
              *)
                   mostrar_mensaje "ERROR" "Respuesta no válida. Usa s o n."
                   ;;
        esac
      done
  else
      mostrar_mensaje "OK" "La interfaz $INTERFAZ ya tiene IP fija o no se detectó como dinámica."
  fi
}

pedir_datos_dns(){

  echo
  mostrar_mensaje "INFO" "Captura de parámetros DNS"

  read -r -p "Dominio a configurar (ej.reprobados.com): " DOMINIO
  IP_OBJETIVO=$(pedir_ip "IP objetivo para los registros A y www")

  ZONE_FILE="$ZONE_DIR/db.$DOMINIO"
}

crear_respaldo(){

  if [[ -f "$CONFIG_LOCAL" ]]; then
     cp "$CONFIG_LOCAL" "${CONFIG_LOCAL}.bak"
     mostrar_mensaje "OK" "Respaldo creado: ${CONFIG_LOCAL}.bak"
  fi
}

escribir_named_conf_local(){

  mostrar_mensaje "INFO" "Escribiendo configuración en named.conf.local..."

  cat > "$CONFIG_LOCAL" <<EOF
zone "$DOMINIO" {
  type master;
  file "$ZONE_FILE";
};
EOF

  mostrar_mensaje "OK" "Archivo named.conf.local actualizado."
}

escribir_archivo_zona(){
  mostrar_mensaje "INFO" "Creando archivo de zona..."

  cat > "$ZONE_FILE" <<EOF
\$TTL 604800
@   IN   SOA $DOMINIO. admin.$DOMINIO. (
         2         ; Serial
         604800    ; Refresh
         86400     ; Retry
         2419200   ; Expire
         604800 )  ; Negative Cache TTL

@        IN  NS  $DOMINIO.

@        IN  A  $IP_OBJETIVO
www      IN  A  $IP_OBJETIVO
EOF

    mostrar_mensaje "OK" "Archivo de zona creado: $ZONE_FILE"
}


validar_configuracion_dns(){

  mostrar_mensaje "INFO" "Validando configuración global..."

  if named-checkconf > /dev/null 2>&1; then
     mostrar_mensaje "OK" "named-checkconf sin errores."
  else
     mostrar_mensaje "ERROR" "Error en named-checkconf."
     exit 1
  fi

  mostrar_mensaje "INFO" "Validando zona DNS..."

  if named-checkzone "$DOMINIO" "$ZONE_FILE" > /dev/null 2>&1; then
     mostrar_mensaje "OK" "Zona DNS válida."
  else
     mostrar_mensaje "ERROR" "Error en el archivo de zona."
     exit 1
  fi
}

reiniciar_servicio_dns(){

  mostrar_mensaje "INFO" "Reiniciando servicio bind9..."
  systemctl restart "$SERVICE_NAME"

  if systemctl is-active --quiet "$SERVICE_NAME"; then
     mostrar_mensaje "OK" "Servicio bind9 activo"
  else
     mostrar_mensaje "ERROR" "No se puede iniciar bind9."
     systemctl status "$SERVICE_NAME" --no-pager
     exit 1
  fi
}

mostrar_estado_dns(){
  echo
  mostrar_mensaje "INFO" "Estado actual del servicio DNS:"
  systemctl status "$SERVICE_NAME" --no-pager | head -n 12
}

probar_resolucion_local(){
  echo
  mostrar_mensaje "INFO" "Probando resolución local..."
  nslookup "$DOMINIO" 127.0.0.1
  nslookup "www.$DOMINIO" 127.0.0.1
}


clear
echo "================================================================"
echo "AUTOMATIZACIÓN DE SERVIDOR DNS EN LINUX"
echo "================================================================"
echo

verificar_root
verificar_instalacion
detectar_interfaz
verificar_ip_fija
pedir_datos_dns
crear_respaldo
escribir_named_conf_local
escribir_archivo_zona
validar_configuracion_dns
reiniciar_servicio_dns
mostrar_estado_dns
probar_resolucion_local

echo
mostrar_mensaje "OK" "Proceso completado exitosamente."
















