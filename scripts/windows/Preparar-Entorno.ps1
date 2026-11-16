[CmdletBinding()]
param(
  [string]$RaizLaboratorio=(Split-Path (Split-Path $PSScriptRoot -Parent) -Parent),
  [string]$KaliVmx,
  [string]$KaliUser='kali',
  [string]$VMwareDir='C:\Program Files\VMware\VMware Workstation',
  [string]$NatPrefix='192.168.123'
)
$ErrorActionPreference='Stop'
foreach($relative in 'descargas','config\ssh','config\legacy-ssh','config\python-deps','vms','evidencias\host','evidencias\00-inventario','evidencias\aislamiento'){
  New-Item -ItemType Directory -Path (Join-Path $RaizLaboratorio $relative) -Force | Out-Null
}
$local=Join-Path $RaizLaboratorio 'config\local.json'
if(Test-Path -LiteralPath $local){Write-Host 'Se conserva config/local.json existente; editarlo manualmente si cambian rutas/usuario.'}
else {
  if(-not $KaliVmx){$KaliVmx=Join-Path $env:USERPROFILE 'Documents\Virtual Machines\Kali\Kali.vmx'}
  [ordered]@{VMwareDir=$VMwareDir;KaliVmx=$KaliVmx;KaliUser=$KaliUser;NatPrefix=$NatPrefix;DhcpLeasesPath='C:\ProgramData\VMware\vmnetdhcp.leases'} | ConvertTo-Json | Set-Content -LiteralPath $local -Encoding UTF8
  Write-Host 'Creado config/local.json local: ajustar rutas y red antes de iniciar VMs. No contiene claves.'
}
. (Join-Path $PSScriptRoot 'Get-LabConfig.ps1')
$cfg=Get-LabConfig -RaizLaboratorio $RaizLaboratorio
foreach($tool in 'python','ssh','ssh-keygen','javac'){
  if(-not(Get-Command $tool -ErrorAction SilentlyContinue)){Write-Warning "Falta herramienta: $tool"}
}
Write-Host ('Raiz: '+$cfg.RaizLaboratorio)
Write-Host 'Requiere Python 3.11+, JDK con javac --release 8, OpenSSH Windows y VMware Workstation. No instala paquetes ni inicia VMs.'
