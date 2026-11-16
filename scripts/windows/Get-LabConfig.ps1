function Get-LabConfig {
  [CmdletBinding()]
  param([string]$RaizLaboratorio=(Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))
  $root=[IO.Path]::GetFullPath($RaizLaboratorio)
  $path=Join-Path $root 'config\local.json'
  if(-not(Test-Path -LiteralPath $path)){throw 'Falta config/local.json. Ejecutar Preparar-Entorno.ps1 y ajustar la configuracion local.'}
  $cfg=Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
  foreach($name in 'VMwareDir','KaliVmx','KaliUser','NatPrefix','DhcpLeasesPath'){
    if(-not $cfg.$name){throw "Falta campo de configuracion: $name"}
  }
  if($cfg.KaliUser -notmatch '^[a-z_][a-z0-9_-]*$'){throw 'KaliUser invalido'}
  if($cfg.NatPrefix -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}$'){throw 'NatPrefix debe tener tres octetos'}
  foreach($part in $cfg.NatPrefix.Split('.')){if([int]$part -gt 255){throw 'NatPrefix invalido'}}
  $cfg | Add-Member -NotePropertyName RaizLaboratorio -NotePropertyValue $root -Force
  return $cfg
}
