[CmdletBinding()]
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Comando)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Get-LabConfig.ps1')
$cfg=Get-LabConfig
$sshDir=Join-Path $cfg.RaizLaboratorio 'config\ssh'
$opts=@('-o','ConnectTimeout=8','-o','BatchMode=yes','-o','IdentitiesOnly=yes','-o','StrictHostKeyChecking=yes','-o',('UserKnownHostsFile='+(Join-Path $sshDir 'victima_known_hosts')),'-i',(Join-Path $sshDir 'victima_rsa'))
$guestUser='msfadmin'
# Compatibilidad heredada solo para esta VM; no modifica ssh_config global.
$opts+=@('-o','HostKeyAlgorithms=+ssh-rsa','-o','PubkeyAcceptedAlgorithms=+ssh-rsa','-o','KexAlgorithms=+diffie-hellman-group14-sha1')
& ssh.exe @opts "$guestUser@192.168.212.20" @Comando
exit $LASTEXITCODE
