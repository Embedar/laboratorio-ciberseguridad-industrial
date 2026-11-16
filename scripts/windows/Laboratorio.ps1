[CmdletBinding()]
param([ValidateSet('Estado','Iniciar')][string]$Accion='Estado')
$ErrorActionPreference='Stop'
$labRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. (Join-Path $PSScriptRoot 'Get-LabConfig.ps1')
$cfg=Get-LabConfig -RaizLaboratorio $labRoot
$vmrunPath=Join-Path $cfg.VMwareDir 'vmrun.exe'
$victima=(Get-Content -LiteralPath (Join-Path $labRoot 'config\victima-importada.json') -Raw | ConvertFrom-Json).vmx
$maquinas=@($cfg.KaliVmx,(Join-Path $labRoot 'vms\plc\PLC.vmx'),$victima)
& (Join-Path $PSScriptRoot 'Verificar-Aislamiento.ps1') -Vmx $maquinas
if ($LASTEXITCODE -ne 0) { throw 'No iniciar: aislamiento incorrecto' }
if($Accion -eq 'Iniciar') {
  $activas=(& $vmrunPath list) -join "`n"
  if($LASTEXITCODE -ne 0){throw 'No se pudo obtener estado VMware'}
  foreach($vmx in $maquinas){
    if($activas -notmatch [regex]::Escape($vmx)){
      & $vmrunPath start $vmx nogui
      if($LASTEXITCODE -ne 0){throw "No se pudo iniciar $vmx"}
    }
  }
  Write-Host 'Las VMs pueden tardar en arrancar. Volver a consultar Estado en unos segundos.'
}
& $vmrunPath list
if($Accion -eq 'Estado'){
  & (Join-Path $PSScriptRoot 'SSH-Kali.ps1') 'hostname; ip -br address; ip route; sysctl net.ipv4.ip_forward'
  & (Join-Path $PSScriptRoot 'SSH-Victima.ps1') 'hostname; ifconfig eth0; route -n; /sbin/sysctl net.ipv4.ip_forward'
  & (Join-Path $PSScriptRoot 'SSH-PLC.ps1') 'hostname; ip -br address; ip route; sysctl net.ipv4.ip_forward; systemctl is-active modbuspal-lab'
}
