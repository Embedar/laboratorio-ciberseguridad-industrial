[CmdletBinding()]
param([string]$ExpectedHostFingerprint,[string]$IpInicial='192.168.212.10')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Get-LabConfig.ps1')
$cfg=Get-LabConfig
$ipParsed=$null
if(-not[Net.IPAddress]::TryParse($IpInicial,[ref]$ipParsed) -or ($IpInicial -ne '192.168.212.10' -and $IpInicial -notmatch ('^'+[regex]::Escape($cfg.NatPrefix)+'\.(\d{1,3})$'))){throw 'IpInicial debe ser .212.10 o pertenecer a NAT local configurada'}
$dir=Join-Path $cfg.RaizLaboratorio 'config\ssh'
New-Item -ItemType Directory -Path $dir -Force | Out-Null
$key=Join-Path $dir 'kali_ed25519'
$known=Join-Path $dir 'kali_known_hosts'
& (Join-Path $PSScriptRoot 'Fijar-HuellaSSH.ps1') -HostIp $IpInicial -KnownHostsFile $known -ExpectedHostFingerprint $ExpectedHostFingerprint -Alias '192.168.212.10'
if(-not(Test-Path -LiteralPath $key)){
  python -c 'import subprocess,sys; subprocess.run(["ssh-keygen","-t","ed25519","-f",sys.argv[1],"-N","","-C","lab-kali"],check=True)' $key
  if($LASTEXITCODE){throw 'Fallo generar clave dedicada'}
}
$opts=@('-o','IdentitiesOnly=yes','-o','StrictHostKeyChecking=yes','-o',"UserKnownHostsFile=$known",'-o','PubkeyAuthentication=no','-o','PreferredAuthentications=password,keyboard-interactive')
Write-Host 'SSH solicitara la contrasena en tu terminal; no se almacena. Solo se envia la clave publica.'
$command='umask 077; mkdir -p "$HOME/.ssh"; touch "$HOME/.ssh/authorized_keys"; IFS= read -r key; key=$(printf "%s" "$key" | tr -d "\r"); grep -qxF "$key" "$HOME/.ssh/authorized_keys" || printf "%s\n" "$key" >> "$HOME/.ssh/authorized_keys"; chmod 600 "$HOME/.ssh/authorized_keys"'
Get-Content -LiteralPath ($key+'.pub') | & ssh @opts ($cfg.KaliUser+'@'+$IpInicial) $command
if($LASTEXITCODE){throw 'No se instalo la clave publica; revisar consola'}
& ssh -i $key -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes -o "UserKnownHostsFile=$known" ($cfg.KaliUser+'@'+$IpInicial) 'id; hostname'
if($LASTEXITCODE){throw 'No se confirmo acceso con clave'}
