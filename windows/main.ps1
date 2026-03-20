.(Join-Path $PSScriptRoot 'funciones\ssh.ps1')

Write-Host "=== MENU WINDOWS ==="
Write-Host "1) Configurar SSH"
Write-Host "2) Salir"

$opcion = Read-Host "Selecciona una opcion"

switch ($opcion) {
      "1" { Configurar-SSH }
      "2" {exit }
      default { Write-Host "Opcion invalida"}
}
