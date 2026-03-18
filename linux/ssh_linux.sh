#!bin/bash/

echo "Actualizando paquetes...."
sudo apt update

echo "Instalando OpenSSH Server..."
sudo apt install -y openssh-server

echo "Habilitando servicio SSH..."
sudo systemctl enable ssh

echo "Ininiciando servicio SSH..."
sudo systemctl start ssh

echo "Estado del servicio SSH:"
sudo systemctl status ssh
