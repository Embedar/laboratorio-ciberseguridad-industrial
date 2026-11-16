[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$IpAprovisionamiento,
  [string]$ExpectedHostFingerprint,
  [string]$RaizLaboratorio=(Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Get-LabConfig.ps1')
$cfg=Get-LabConfig -RaizLaboratorio $RaizLaboratorio
$parsed=$null
if(-not[Net.IPAddress]::TryParse($IpAprovisionamiento,[ref]$parsed) -or $IpAprovisionamiento -notmatch ('^'+[regex]::Escape($cfg.NatPrefix)+'\.(\d{1,3})$')){throw 'La IP debe pertenecer al prefijo NAT VMware local configurado'}
$lastOctet=[int]($IpAprovisionamiento.Split('.')[-1]); if($lastOctet -lt 1 -or $lastOctet -gt 254){throw 'IP no utilizable'}
New-Item -ItemType Directory -Path (Join-Path $RaizLaboratorio 'evidencias\host') -Force | Out-Null
$vmrun=Join-Path $cfg.VMwareDir 'vmrun.exe'
$vmx=Join-Path $RaizLaboratorio 'vms\plc\PLC.vmx'
$key=Join-Path $RaizLaboratorio 'config\ssh\plc_ed25519'
$known=Join-Path $RaizLaboratorio 'config\ssh\known_hosts'
# Comparar con consola/serial antes de autenticarse en primer uso; luego confianza fijada.
& (Join-Path $PSScriptRoot 'Fijar-HuellaSSH.ps1') -HostIp $IpAprovisionamiento -KnownHostsFile $known -ExpectedHostFingerprint $ExpectedHostFingerprint -Alias '192.168.212.30'
$opts=@('-i',$key,'-o','IdentitiesOnly=yes','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o',"UserKnownHostsFile=$known",'-o','ConnectTimeout=10')
$estado=& ssh @opts "lab@$IpAprovisionamiento" 'cloud-init status --wait && test -f /var/tmp/plc-provisionado && java -version && systemctl is-active ssh open-vm-tools'
if($LASTEXITCODE){throw 'Aprovisionamiento incompleto; no se cambia la red'}
$estado | Set-Content -LiteralPath (Join-Path $RaizLaboratorio 'evidencias\host\plc-aprovisionamiento.txt') -Encoding UTF8
$net=Join-Path $RaizLaboratorio 'config\plc-netplan.yaml'
@"
network:
  version: 2
  ethernets:
    plc:
      match:
        macaddress: '00:50:56:22:00:30'
      set-name: ens33
      dhcp4: false
      dhcp6: false
      addresses: [192.168.212.30/24]
      link-local: []
"@ | Set-Content -LiteralPath $net -Encoding ASCII
& scp @opts $net "lab@${IpAprovisionamiento}:/tmp/plc-netplan.yaml"
if($LASTEXITCODE){throw 'Fallo copiar netplan'}
& ssh @opts "lab@$IpAprovisionamiento" "sudo install -m 600 /tmp/plc-netplan.yaml /etc/netplan/50-cloud-init.yaml && echo 'network: {config: disabled}' | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg >/dev/null && sudo netplan generate && sudo sync"
if($LASTEXITCODE){throw 'Fallo preparar red definitiva'}
& $vmrun -T ws stop $vmx soft
if($LASTEXITCODE){throw 'No fue posible apagar VM limpiamente; no editar VMX'}
$fin=(Get-Date).AddSeconds(60)
do {
  $salida=@(& $vmrun -T ws list)
  if($LASTEXITCODE){throw 'No se pudo verificar apagado'}
  if(-not ($salida -contains $vmx)){break}
  Start-Sleep -Seconds 2
}while((Get-Date) -lt $fin)
if($salida -contains $vmx){throw 'VM sigue encendida; no editar VMX'}
$contenido=Get-Content -LiteralPath $vmx -Raw
if($contenido -notmatch 'ethernet0.connectionType = "nat"'){throw 'Estado VMX inesperado; no editar'}
$contenido=$contenido.Replace('ethernet0.connectionType = "nat"','ethernet0.connectionType = "hostonly"')
if($contenido -match '(?m)^ethernet0.vnet\s*='){$contenido=[regex]::Replace($contenido,'(?m)^ethernet0.vnet\s*=.*$','ethernet0.vnet = "VMnet1"')}
else{$contenido+="`nethernet0.vnet = `"VMnet1`"`n"}
Set-Content -LiteralPath $vmx -Value $contenido -Encoding UTF8
& (Join-Path $PSScriptRoot 'Verificar-Aislamiento.ps1') -Vmx $vmx -RaizLaboratorio $RaizLaboratorio
if($LASTEXITCODE){throw 'No supera aislamiento; no iniciar'}
& $vmrun -T ws start $vmx nogui
if($LASTEXITCODE){throw 'No arranco PLC aislado'}
$ready=$false
$fin=(Get-Date).AddMinutes(3)
do {
  & ssh @opts lab@192.168.212.30 'test -z "$(ip -4 route show default)" && test -z "$(ip -6 route show default)" && ip -4 -o address show dev ens33 | grep -Fq "192.168.212.30/24"' 2>$null
  if($LASTEXITCODE -eq 0){$ready=$true;break}
  Start-Sleep -Seconds 3
}while((Get-Date) -lt $fin)
if(-not $ready){throw 'PLC aislado iniciado pero SSH/IP no listos tras 3 minutos; revisar consola antes de instalar'}
Write-Host 'PLC aislado listo, misma clave host fijada para .30. Ejecutar Instalar-PLC.ps1.'
