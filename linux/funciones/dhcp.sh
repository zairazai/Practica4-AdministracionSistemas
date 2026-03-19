#!/bin/bash

CONFIG_FILE="/etc/dhcp/dhcpd.conf"
INTERFACE_FILE="/etc/default/isc-dhcp-server"
LEASE_FILE="/var/lib/dhcp/dhcpd.leases"
SERVICE_NAME="isc-dhcp-server"

verificar_instalacion(){
  mostrar_mensaje "INFO" "Verificando si $SERVICE_NAME está instalado..."
  if dpkg -s "$SERVICE_NAME" > /dev/null 2>&1; then
     mostrar_mensaje "OK" "$SERVICE_NAME ya está instalado."
  else
     mostrar_mensaje "WARN" "$SERVICE_NAME no está instalado. Instalando..."
     apt update -qq >/dev/null 2>&1
     apt install -y "$SERVICE_NAME" > /dev/null 2>&1

     if dpkg -s "$SERVICE_NAME" > /dev/null 2>&1; then
        mostrar_mensaje "OK"  "Instalación completada con éxito."
     else
        mostrar_mensaje "ERROR" "No se pudo instalar $SERVICE_NAME."
        exit 1
     fi
  fi
}

detectar_interfaz(){
  mostrar_mensaje "INFO" "Interfaces disponibles: "
  ip -brief addr show | awk '{print " - " $1 " -> " $3}'

  while true; do
      read -rp "Ingresa la interfaz para la red interna (ej. enp0s8): " INTERFAZ
      if ip link show "$INTERFAZ" > /dev/null 2>&1; then
          mostrar_mensaje "OK" "Interfaz $INTERFAZ seleccionada. "
          break
      else
          mostrar_mensaje "ERROR" "La interfaz no existe.Intenta nuevamente."
      fi
  done

}

pedir_datos(){
  echo
  mostrar_mensaje "INFO" "Captura de prámetros DHCP"
  read -rp "Nombre descriptivo del ámbito (Scope):" NOMBRE_SCOPE

  IP_INICIAL=$(pedir_ip "Rango inicial")
  IP_FINAL=$(pedir_ip "Rango final")
  GATEWAY=$(pedir_ip "Puerta de enlace (Gateway)")
  DNS=$(pedir_ip "Servidor DNS")

  while true; do
        read -r -p "Tiempo de concesión en segundos (Lease Time, ej. 600) " LEASE_TIME
        if [[ $LEASE_TIME =~ ^[0-9]+$ ]] && (( LEASE_TIME > 0 )); then
          break
        else
           mostrar_mensaje "ERROR" "Debes ingresar un número entero positivo."
        fi
  done

  while true; do
        read -r -p "Tiempo máximo de concesión en segundos (ej. 7200) " MAX_LEASE_TIME
        if [[ $MAX_LEASE_TIME =~ ^[0-9]+$ ]] && ((MAX_LEASE_TIME > 0 )); then
          break
        else
        mostrar_mensaje "ERROR" "Debes ingresar un número entero positivo."
        fi
  done

  while true; do
        read -r -p "Subred (ej. 192.168.100.0): " SUBNET
        if validar_ip "$SUBNET"; then
           break
        else
           mostrar_mensaje "ERROR" "Subred no válida."
        fi
  done

  while true; do
        read -r -p "Máscara de red (ej. 255.255.255.0): " NETMASK
        if  validar_ip "$NETMASK"; then
            break
        else
            mostrar_mensaje "ERROR" "Máscara inválida."
        fi
  done

}

crear_respaldo(){
  if  [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
        mostrar_mensaje "OK" "Respaldo creado: ${CONFIF_FILE}.bak"
  fi
}

escribir_configuracion(){

  mostrar_mensaje "INFO" "Escribiendo configuración DHCP..."

  cat > "$CONFIG_FILE" <<EOF

# Archivo generado automáticamente por script
# Ámbito : $NOMBRE_SCOPE

  default-lease-time $LEASE_TIME;
  max-lease-time $MAX_LEASE_TIME;
  authoritative;

  subnet $SUBNET netmask $NETMASK {
    range $IP_INIICAL $IP_FINAL;
    option routers $GATEWAY;
    option domain-name-servers $DNS;
  }
EOF
    cat > "$INTERFACE_FILE" <<EOF
  INTERFACESv4="$INTERFAZ"
  INTERFACESv6=""
EOF
     mostrar_mensaje "OK" "Archivos de configuración actualizados."
}

validar_configuracion(){
  mostrar_mensaje "INFO" "Validando sintaxis del archivo DHCP..."
  if dhcpd -t -cf /etc/dhcp/dhcpd.conf > /dev/null 2>&1; then
     mostrar_mensaje "OK" "Sintaxis válida."
  else
     mostrar_mensaje "ERROR" "La configuración contiene errores."
     dhcpd -t -cf /etc/dhcp/dhcpd.conf
  exit 1
  fi
}

reiniciar_servicio(){
  mostrar_mensaje "INFO" "Reiniciando servicio DHCP..."

  systemctl restart "$SERVICE_NAME"

  if systemctl is-active --quiet "$SERVICE_NAME"; then
     mostrar_mensaje "OK" "Servicio DHCP activo."
  else
     mostrar_mensaje "ERROR" "El servicio no pudo iniciarse."
     systemctl status "$SERVICE_NAME" --no-pager
     exit 1
  fi
}

mostrar_estado(){
  echo
  mostrar_mensaje "INFO" "Estado actual del servicio:"
  systemctl status "$SERVICE_NAME" --no-pager | head -n 12

}

mostrar_concesiones(){
  echo
  mostrar_mensaje "INFO" "Concesiones registradas:"
  if [[ -f "$LEASE_FILE" ]]; then
     grep -E "lease |client-hostname|hardware ethernet|binding state" "$LEASE_FILE"
  else
     mostrar_mensaje "WARN" "No se encontró el archivo de concesiones."
  fi
}

configurar_dhcp() {

echo "================================================="
echo "AUTOMATIZACIÓN DE SERVIDOR DHCP EN LINUX"
echo "================================================="
echo

verificar_instalacion
detectar_interfaz
pedir_datos
crear_respaldo
escribir_configuracion
validar_configuracion
reiniciar_servicio
mostrar_estado
mostrar_concesiones

echo
mostrar_mensaje "OK" "Proceso completado exitosamente."

}


