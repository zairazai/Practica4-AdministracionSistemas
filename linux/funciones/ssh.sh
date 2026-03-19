
#!/bin/bash
function configurar_ssh() {

echo "Actualizando paquetes...."
apt update > /dev/null 2>&1

echo "Instalando OpenSSH Server..."
apt install -y openssh-server > /dev/null 2>&1

echo "Habilitando servicio SSH..."
systemctl enable ssh > /dev/null 2>&1

echo "Iniciando servicio SSH..."
systemctl start ssh > /dev/null/ 2>&1

echo "Verificando estado del servicio SSH..."
estado=$(systemctl is-active ssh)

if [ "$estado" = "active" ]; then
   echo "SSH activo correctamente."
else
   echo "Error: SSH no esta activo."
   exit 1
fi

}
