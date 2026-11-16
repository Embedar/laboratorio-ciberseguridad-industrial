[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$HostIp,
  [Parameter(Mandatory=$true)][string]$KnownHostsFile,
  [string]$ExpectedHostFingerprint,
  [string[]]$Alias=@()
)
$ErrorActionPreference='Stop'
$parsed=$null
if(-not [Net.IPAddress]::TryParse($HostIp,[ref]$parsed) -or $HostIp -notmatch '^192\.168\.(212|123)\.\d+$'){
  # Admitir la NAT local configurada sin aceptar nombres/opciones de shell.
  if(-not [Net.IPAddress]::TryParse($HostIp,[ref]$parsed) -or $parsed.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork){throw 'HostIp debe ser IPv4 literal de la VM local'}
}
$selected=$null
$scan=@()
if(Test-Path -LiteralPath $KnownHostsFile){
  $existing=@(& ssh-keygen -F $HostIp -f $KnownHostsFile 2>$null | Where-Object {$_ -and $_ -notmatch '^#'})
  if($LASTEXITCODE -eq 0 -and $existing.Count -gt 0 -and -not $ExpectedHostFingerprint){$selected=$existing[0]}
}
if(-not $selected){
  if(-not $ExpectedHostFingerprint -or $ExpectedHostFingerprint -notmatch '^SHA256:[A-Za-z0-9+/]+={0,2}$'){
    throw 'Primer uso: indicar -ExpectedHostFingerprint SHA256:... observado en consola del invitado. La huella se compara antes de guardar o autenticar.'
  }
  $scan=@(& python (Join-Path $PSScriptRoot 'Obtener-ClaveSSH.py') --host $HostIp --expected $ExpectedHostFingerprint)
  if($LASTEXITCODE -ne 0 -or -not $scan){throw 'SSH no esta listo o huella distinta. No se autentica ni se guarda clave.'}
}
$temp=[IO.Path]::GetTempFileName()
try{
  foreach($line in @($scan)){
    if($selected){break}
    Set-Content -LiteralPath $temp -Value $line -Encoding ASCII
    $details=(& ssh-keygen -lf $temp -E sha256 2>$null) -join ' '
    if($LASTEXITCODE -eq 0 -and ($details -split '\s+') -contains $ExpectedHostFingerprint){$selected=$line;break}
  }
  if(-not $selected){throw 'Huella distinta de la consola: no se acepta ni autentica'}
  $fields=$selected -split '\s+'
  $parent=Split-Path $KnownHostsFile -Parent
  New-Item -ItemType Directory -Path $parent -Force | Out-Null
  foreach($name in @($HostIp)+$Alias){
    $address=$null
    if(-not [Net.IPAddress]::TryParse($name,[ref]$address)){throw 'Alias debe ser IPv4 literal'}
    $entry="$name $($fields[1]) $($fields[2])"
    if(Test-Path -LiteralPath $KnownHostsFile){
      $previous=@(& ssh-keygen -F $name -f $KnownHostsFile 2>$null | Where-Object {$_ -notmatch '^#'})
      if($LASTEXITCODE -eq 0 -and $previous.Count -gt 0){
        if(-not ($previous | Where-Object {($_ -split '\s+')[1] -eq $fields[1] -and ($_ -split '\s+')[2] -eq $fields[2]})){throw "Ya existe otra clave para $name; investigar antes de reemplazar"}
        continue
      }
    }
    Add-Content -LiteralPath $KnownHostsFile -Value $entry -Encoding ASCII
  }
  if($ExpectedHostFingerprint){Write-Host ('Huella contrastada y fijada: '+$ExpectedHostFingerprint)}
  else{Write-Host 'Se conserva clave previamente fijada; alias agregado sin escaneo de red'}
} finally {Remove-Item -LiteralPath $temp -Force}
