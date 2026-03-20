.(Join-Path $PSScriptRoot 'funciones\comunes.ps1')
.(Join-Path $PSScriptRoot 'funciones\ssh.ps1')
.(Join-Path $PSScriptRoot 'funciones\dns.ps1')

Write-Host "=== MENU WINDOWS ==="
Write-Host "1) Configurar SSH"
Write-Host "2) Configurar DNS"
Write-Host "3) Salir"

$opcion = Read-Host "Selecciona una opcion"

switch ($opcion) {
      "1" { Configurar-SSH }
      "2" { Configurar-DNS }
      "3" {exit }
      default { Write-Host "Opcion invalida"}
}
