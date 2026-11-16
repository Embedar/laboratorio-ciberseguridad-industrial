[CmdletBinding()]
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Comando)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Get-LabConfig.ps1')
$cfg=Get-LabConfig
$sshDir=Join-Path $cfg.RaizLaboratorio 'config\ssh'
$opts=@('-o','ConnectTimeout=8','-o','BatchMode=yes','-o','IdentitiesOnly=yes','-o','StrictHostKeyChecking=yes','-o',('UserKnownHostsFile='+(Join-Path $sshDir 'known_hosts')),'-i',(Join-Path $sshDir 'plc_ed25519'))
$guestUser='lab'

& ssh.exe @opts "$guestUser@192.168.212.30" @Comando
exit $LASTEXITCODE
