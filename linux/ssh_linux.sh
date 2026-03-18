#!bin/bash

echo "Actualizando paquetes...."
apt update

echo "Instalando OpenSSH Server..."
apt install -y openssh-server

echo "Habilitando servicio SSH..."
systemctl enable ssh

echo "Iniciando servicio SSH..."
systemctl start ssh

echo "Verificando estado del servicio SSH..."
estado=$(systemctl is-active ssh)

if [ "$estado" = "active" ]; then
   echo "SSH activo correctamente."
else
   echo "Error: SSH no esta activo."
   exit 1
fi
