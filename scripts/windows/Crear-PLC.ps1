[CmdletBinding()]
param([string]$RaizLaboratorio=(Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Get-LabConfig.ps1')
$cfg=Get-LabConfig -RaizLaboratorio $RaizLaboratorio
New-Item -ItemType Directory -Path (Join-Path $RaizLaboratorio 'descargas') -Force | Out-Null
$base='https://cloud-images.ubuntu.com/releases/noble/release/'
$nombre='ubuntu-24.04-server-cloudimg-amd64.vmdk'
$imagen=Join-Path $RaizLaboratorio ('descargas\'+$nombre)
$sumas=Join-Path $RaizLaboratorio 'descargas\ubuntu-SHA256SUMS'
if(-not (Test-Path -LiteralPath $sumas)){Invoke-WebRequest ($base+'SHA256SUMS') -OutFile $sumas}
if(-not (Test-Path -LiteralPath $imagen)){Invoke-WebRequest ($base+$nombre) -OutFile $imagen}
$linea=Get-Content -LiteralPath $sumas | Where-Object {$_ -match ('\s\*?'+[regex]::Escape($nombre)+'$')}
if(-not $linea){throw 'No se encontro SHA256 oficial'}
$esperado=($linea -split '\s+')[0]
$hash=(Get-FileHash -LiteralPath $imagen -Algorithm SHA256).Hash
if($hash -ine $esperado){throw 'Hash de imagen no coincide'}
$deps=Join-Path $RaizLaboratorio 'config\python-deps'
if(-not (Test-Path -LiteralPath (Join-Path $deps 'pycdlib'))){python -m pip install --target $deps pycdlib; if($LASTEXITCODE){throw 'Fallo pycdlib'}}
$vm=Join-Path $RaizLaboratorio 'vms\plc'
if(Test-Path -LiteralPath (Join-Path $vm 'PLC.vmx')){throw 'VM existente; no se sobrescribe ni se arranca automaticamente'}
python (Join-Path $PSScriptRoot 'crear-plc.py') --root $RaizLaboratorio
if($LASTEXITCODE){throw 'Fallo generar VMX/ISO'}
$manager=Join-Path $cfg.VMwareDir 'vmware-vdiskmanager.exe'
& $manager -r $imagen -t 0 (Join-Path $vm 'PLC.vmdk')
if($LASTEXITCODE){throw 'Fallo convertir VMDK'}
Write-Host 'VM creada; NAT temporal solo para instalar paquetes. Arrancar con vmrun; finalizar mediante Finalizar-PLC.ps1 antes de la practica.'
