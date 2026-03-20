function Mostrar-Mensaje {
  param (
      [string]$Tipo,
      [string]$Mensaje
  )

  switch ($Tipo) {
      "INFO"  {Write-Host "[INFO] $Mensaje" }
      "OK"    {Write-Host "[OK] $Mensaje" }
      "ERROR" {Write-Host "[ERROR] $Mensaje" }
      "WARN"  {Write-Host "[WARN] $Mensaje" }
      default {Write-Host $Mensaje }
  }
}

function Validar-IPv4 {
    param (
        [string]$IP
    )

    $regex = '^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    if ($IP -notmatch $regex){
         return $false
    }
    $octetos = $IP.Split('.')
    foreach ($octeto in $octetos) {
        if ([int]$octeto -lt 0 -or [int]$octeto -gt 255) {
            return $false
        }
    }

    return $true
}



function Pedir-IPv4 {
   param (
       [string]$Mensaje
   )

   while ($true) {
       $valor = Read-Host "$Mensaje"
       if (Validar-IPv4 $valor) {
           return $valor
       }
       else {
          Mostrar-Mensaje "ERROR" "IPv4 invalida. Intenta de nuevo."
       }
   }

}


function Verificar-Administrador {

  if (-not ([Security.Principal.WindowsPrincipal] `
      [Security.Principal.WindowsIdentity]::GetCurrent()
      ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
     Mostrar-Mensaje "ERROR" "Este script debe ejecutarse como administrador."
     exit
  }
}

function Iniciar-ServicioSeguro {

  param (
    [string]$NombreServicio
  )

  Start-Service $NombreServicio -ErrorAction SilentlyContinue
}

function Habilitar-InicioAutomatico {

  param (
    [string]$NombreServicio
  )

  Set-Service $NombreServicio -StartupType Automatic

}

function Validar-Servicio {
  param (
    [string]$NombreServicio
  )

  $estado = (Get-Service $NombreServicio).Status

  if ($estado -eq "Running") {
     Mostrar-Mensaje "OK" "Servicio $NombreServicio activo correctamente."
  }
  else {
     Mostrar-Mensaje "ERROR" "El servicio $NombreServicio no esta activo."
     exit 1
  }
}
