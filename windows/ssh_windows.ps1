
Write-Host "Instalando OpensSSH Server..."
Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0'

Write-Host "Iniciando servicio SSH..."
Start-Service sshd

Write-Host "Configurando inicio automatico..."
Set-Service -Name sshd -StartupType Automatic

$regla = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
if (-not $regla) {
  Write-Host "Creando regla del firewall..."
  New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server (TCP-In)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
} else {
   Write-Host "La regla del firewall ya existe."
}

Write-Host "Verificando estado del servicio..."
$estado = (Get-Service sshd).Status

if ($estado -eq "Running") {
   Write-Host "SSH activo correctamente."
} else {
   Write-Host "Error: SSH no esta activo."
}