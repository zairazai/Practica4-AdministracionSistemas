
#funcion para verificar instalacion del rol DHCP 
function Verificar-InstalacionDHCP {

  Mostrar-Mensaje "INFO" "Verificando instalacion del rol DHCP..."
  $feature = Get-WindowsFeature -Name DHCP

  if ($feature.Installed) {
     Mostrar-Mensaje "OK" "El rol DHCP ya esta instalado."
  }
  else {
     Mostrar-Mensaje "WARN" " El rol DHCP no esta instalado. Instalando..."
     $resultado = Install-WindowsFeature -Name DHCP -IncludeManagementTools
     if ($resultado.Success) {
     Mostrar-Mensaje "OK" "Rol DHCP instalado correctamente."
     }
     else {
     Mostrar-Mensaje "ERROR" "No se pudo instalar el rol DHCP."
     exit 1
     }
  }
}



#funcion para solicitar datos (configuracion dinamica)
function Pedir-DatosDHCP {
  Mostrar-Mensaje "INFO" "Captura de parametros DHCP"

#nombre del scope
while ($true) {
  $global:ScopeName = Read-Host "Nombre descriptivo del ambito (scope)"
  if (-not [string]::IsNullOrWhiteSpace($global:ScopeName)) {
     break
  }
  else {
      Mostrar-Mensaje "ERROR" "El nombre del Scope no puede estar vacio."
  }
}

#rango de IPs
$global:StartIP = Pedir-IPv4 "IP inicial (ej. 192.168.100.50)"
$global:EndIP = Pedir-IPv4 "IP final (ej. 192.168.100.150)"

#mascara
$global:SubnetMask = Pedir-IPv4 "Gateway/Router (ej.192.168.100.1)"

#DNS
$global:DNS =Pedir-IPv4 "Servidor DNS (ej.192.168.100.20)"

#Dominio
  while ($true) {
       $global:Domain = Read-Host "Dominio DNS (ej.reprobados.com)"
       if (-not [string]::IsNullOrWhiteSpace($global:Domain)) {
          break
       }
       else {
           Mostrar-Mensaje "ERROR" "El dominio no puede estar vacio."
       }
  }
#tiempo de concesion
$global:LeaseHours = Pedir-EnteroPositivo "Tiempo de concesion en hrs (ej. 8)"

#convertir lease a timespan
$global:LeaseDuration = New-TimeSpan -Hours $global:LeaseHours

#calcular scopeid a partir de la ip inicial 
$octetos = $global:StartIP.Split('.')
$global:ScopeId = "$($octetos[0]).$($octetos[1]).$($octetos[2]).0"

}

#funcion para crear scope si no existe
function Crear-ScopeDHCP {
 Mostrar-Mensaje "INFO" "Verificando si scoope ya existe..."
#buscar si ya existe por nombre o red
 $scopeExistente = Get-DhcpServerv4Scope -ErrorAction SilentlyContinue |
      Where-Object {$_.Name -eq $ScopeName -or $_.ScopeId.ToString() -eq $ScopeId }
 if ($scopeExistente) {
    Mostrar-Mensaje "WARN" "El scope ya existe. Se reutilizara."
 }
 else {
    Mostrar-Mensaje "INFO" "Creando Scope DHCP..."
    Add-DhcpServerv4Scope `
       -Name $global:ScopeName `
       -StartRange $global:StartIP `
       -EndRange $global:EndIP `
       -SubnetMask $global:SubnetMask `
       -LeaseDuration $global:LeaseDuration | Out-Null
    Mostrar-Mensaje "OK" "Scope DHCP creado correctamente."
 }
}

#funcion para configurar opciones del scope
function Configurar-OpcionesDHCP {
  Mostrar-Mensaje "INFO" "Configurando opciones del Scope..."
  Set-DhcpServerv4OptionValue `
     -ScopeId $global:ScopeId `
     -Router $global:Gateway `
     -DnsServer $global:DNS `
     -DnsDomain $global:Domain | Out-Null
   Mostrar-Mensaje "OK" "Opciones DHCP configuradas correctamente."
}

#funcion para activar y validar DHCP
function Validar-ServicioDHCP {
  Mostrar-Mensaje "INFO" "Iniciando servicio DHCP..."
  Start-Service DHCPServer -ErrorAction SilentlyContinue
  $servicio = Get-Service DHCPServer
  if ($servicio.Status -eq "Running") {
     Mostrar-Mensaje "OK" "Servicio DHCP activo."
  }
  else {
     Mostrar-Mensaje "ERROR" "El servicio DHCP no esta activo."
     exit 1
  }
}

#funcion para mostrar estado del serv
function Mostrar-EstadoDHCP {
  Write-Host ""
  Mostrar-Mensaje "INFO" "Estado actual del servicio DHCP: "
  Get-Service DHCPServer | Format-Table -Autosize
}

#funcion para mostrar scopes
function Mostrar-ScopeDHCP {
  Write-Host ""
  Mostrar-Mensaje "INFO" "Scopes configurados:"
  Get-DhcpServerv4Scope | Format-Table -AutoSize
}

#funcion para mostrar opciones del scope 
function Mostrar-OpcionesDHCP {
  Write-Host ""
  Mostrar-Mensaje "INFO" "Opciones configuradas del Scope: "
  Get-DhcpServerv4OptionValue -ScopeId $ScopeId | Format-Table -AutoSize
}

#funcion para mostrar leases activas
function Mostrar-LeasesDHCP {
  Write-Host ""
  Mostrar-Mensaje "INFO" "Concesiones (leases) activas:"
  Get-DhcpServerv4Lease -ScopeId $ScopeId | Format-Table -Autosize
}

function Configurar-DHCP {
Clear-Host 
Write-Host "============================================"
Write-Host "AUTOMATIZACION DE SERVIDOR DHCP EN WINDOWS"
Write-Host "============================================"
Write-Host ""

Verificar-Administrador
Verificar-InstalacionDHCP
Pedir-DatosDHCP
Crear-ScopeDHCP
Configurar-OpcionesDHCP
Validar-ServicioDHCP
Mostrar-EstadoDHCP
Mostrar-ScopeDHCP
Mostrar-OpcionesDHCP
Mostrar-LeasesDHCP

Write-Host ""
Mostrar-Mensaje "OK" "Proceso completado correctamente."
}