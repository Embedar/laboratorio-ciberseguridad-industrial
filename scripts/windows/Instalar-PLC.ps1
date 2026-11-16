[CmdletBinding()]
param([string]$RaizLaboratorio=(Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))
$ErrorActionPreference='Stop'
$opts=@('-i',(Join-Path $RaizLaboratorio 'config\ssh\plc_ed25519'),'-o','BatchMode=yes','-o','IdentitiesOnly=yes','-o','StrictHostKeyChecking=yes','-o',('UserKnownHostsFile='+(Join-Path $RaizLaboratorio 'config\ssh\known_hosts')))
& ssh @opts lab@192.168.212.30 'mkdir -p ~/instalacion-plc; test -z "$(ip route show default)"'
if($LASTEXITCODE){throw 'PLC no responde o tiene default route'}
& scp @opts (Join-Path $RaizLaboratorio 'descargas\ModbusPal.jar') 'lab@192.168.212.30:/home/lab/instalacion-plc/'
if($LASTEXITCODE){throw 'Fallo copiar JAR'}
& scp @opts -r (Join-Path $RaizLaboratorio 'scripts\plc') 'lab@192.168.212.30:/home/lab/instalacion-plc/'
if($LASTEXITCODE){throw 'Fallo copiar wrapper'}
& ssh @opts lab@192.168.212.30 'bash ~/instalacion-plc/plc/Instalar-ModbusPal.sh ~/instalacion-plc/ModbusPal.jar ~/instalacion-plc/plc'
if($LASTEXITCODE){throw 'Fallo instalar ModbusPal'}
