#=======================================
#Script de automatizacion DNS en Windows
#=======================================

function Verificar-InstalacionDNS {
  Mostrar-Mensaje "INFO" "Verificando instalacion del rol DNS..."
  $feature = Get-WindowsFeature -Name DNS

  if ($feature.Installed) {
     Mostrar-Mensaje "OK" "El rol DNS ya esta instalado."
  }
  else {
  
     Mostrar-Mensaje "WARN" "El rol DNS no esta instalado. Instalando..."
     $resultado = Install-WindowsFeature -Name DNS -IncludeManagementTools
     if ($resultado.Success) {
         Mostrar-Mensaje "OK" "Rol DNS instalado correctamente."
     }
     else {
         Mostrar-Mensaje "ERROR" "No se pudo instalar el rol DNS."
         exit 1
     }
  }
}

function Pedir-DatosDNS {

  Mostrar-Mensaje "INFO" "Captura de parametros DNS"

  while ($true) {
     $script:Zona = Read-Host "Dominio a configurar (ej. reprobados.com)"
     if (-not [string]::IsNullOrWhiteSpace($script:Zona)) {
        break
     }
     else {
          Mostrar-Mensaje "ERROR" "El dominio no puede estar vacio."
     }
  }
 
  $script:IPObjetivo = Pedir-IPv4 "IP objetivo para los registros A"

}


function Crear-ZonaDNS {

  Mostrar-Mensaje "INFO" "Verificando si la zona DNS ya existe..."

  $zonaExistente = Get-DnsServerZone -ErrorAction SilentlyContinue | Where-Object { $_.ZoneName -eq $Zona}
  if ($zonaExistente) {
     Mostrar-Mensaje "WARN" "La zona $Zona ya existe. Se reutilizará."
  }
  else {
     Mostrar-Mensaje "INFO" "Creando zona primaria $Zona..."

     Add-DnsServerPrimaryZone -Name $Zona -ZoneFile "$Zona.dns" -DynamicUpdate None | Out-Null
     Mostrar-Mensaje "OK" "Zona DNS creada correctamente."
  }
}


function Crear-RegistrosDNS {

  Mostrar-Mensaje "INFO" "Creando o actualizando registros DNS..."
  #Registro raiz (@)
  $registroRaiz = Get-DnsServerResourceRecord -ZoneName $Zona -RRType "A" -ErrorAction SilentlyContinue |
  Where-Object { $_.HostName -eq "@" }

  if ($registroRaiz) {
     Mostrar-Mensaje "WARN" "El registro A para la raiz ya existe."
  }
  else {
       Add-DnsServerResourceRecordA -ZoneName $Zona -Name "@" -IPv4Address $IPObjetivo | Out-Null
       Mostrar-Mensaje "OK" "Registro A para $Zona creado."
  }

  #Registro www
  $registroWWW = Get-DnsServerResourceRecord -ZoneName $Zona -RRType "A" -ErrorAction SilentlyContinue |
  Where-Object { $_.HostName -eq "www" }

  if ($registroWWW) {
     Mostrar-Mensaje "WARN" "El registro A www ya existe."
  }
  else {
       Add-DnsServerResourceRecordA -ZoneName $Zona -Name "www" -IPv4Address $IPObjetivo | Out-Null
       Mostrar-Mensaje "OK" "Registro A para wwww.$Zona creado."
  }
}
  
function Mostrar-EstadoDNS{

  Mostrar-Mensaje "INFO" "Estado actual del servicio DNS..."
  Get-Service -Name DNS | Format-Table -Autosize
}

function Mostrar-RegistrosDNS {

  Mostrar-Mensaje "INFO" "Mostrando registros creados..."
  Get-DnsServerResourceRecord -ZoneName $Zona | Format-Table -AutoSize
}

function Probar-ResolucionLocal {
  Mostrar-Mensaje "INFO" "Prueba local de resolucion DNS..."
  Write-Host ""
  Write-Host "Resolviendo dominio principal..."
  Resolve-DnsName $Zona -Server 127.0.0.1 

  Write-Host ""
  Write-Host "Resolviendo subdominio www..."
  Resolve-DnsName "www.$Zona" -Server 127.0.0.1 
}

function Configurar-DNS {
Clear-Host
Write-Host "=============================================="
Write-Host "AUTOMATIZACION DE SERVIDOR DNS EN WINDOWS"
Write-Host "=============================================="
Write-Host ""

Verificar-Administrador
Verificar-InstalacionDNS
Pedir-DatosDNS
Crear-ZonaDNS
Crear-RegistrosDNS
Mostrar-EstadoDNS
Mostrar-RegistrosDNS
Probar-ResolucionLocal

Write-Host""
Mostrar-Mensaje "OK" "Proceso completado correctamente."
}