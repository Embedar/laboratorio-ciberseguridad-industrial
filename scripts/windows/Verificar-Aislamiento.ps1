[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string[]]$Vmx,
  [string]$RaizLaboratorio = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
)
# Verifica configuracion de archivos; no demuestra ausencia de routing/ICS en el host.
# No requiere VMware Tools y no cambia VM ni interfaces del host.
$ErrorActionPreference = 'Stop'
$resultados = @()
foreach ($ruta in $Vmx) {
  $errores = New-Object System.Collections.Generic.List[string]
  $adaptadores = @()
  $valores = @{}
  $resuelta = $ruta
  if (-not (Test-Path -LiteralPath $ruta -PathType Leaf)) { $errores.Add('No existe el archivo VMX.') }
  else {
    $resuelta = (Resolve-Path -LiteralPath $ruta).Path
    foreach ($linea in (Get-Content -LiteralPath $resuelta)) {
      if ($linea -match '^\s*(ethernet\d+\.[A-Za-z0-9_.]+)\s*=\s*"([^"]*)"\s*$') {
        $clave = $Matches[1].ToLowerInvariant()
        if ($valores.ContainsKey($clave)) { $errores.Add("Clave de red duplicada: $clave") }
        $valores[$clave] = $Matches[2]
      } elseif ($linea -match '^\s*ethernet\d+\.') {
        $errores.Add("Linea de red no interpretable: $linea")
      }
    }
    $indices = @($valores.Keys | ForEach-Object { if ($_ -match '^(ethernet\d+)\.') { $Matches[1] } } | Sort-Object -Unique)
    foreach ($indice in $indices) {
      $presente = $valores["$indice.present"] -ieq 'TRUE'
      $tipo = $valores["$indice.connectiontype"]
      $red = $valores["$indice.vnet"]
      $adaptadores += [pscustomobject]@{ adaptador=$indice; presente=$presente; tipo=$tipo; vnet=$red; iniciaConectado=$valores["$indice.startconnected"] }
      if ($presente) {
        if ($tipo -ine 'hostonly') { $errores.Add("${indice}: connectionType debe ser hostonly; actual '$tipo'.") }
        if ($red -and $red -ine 'VMnet1') { $errores.Add("${indice}: vnet debe ser VMnet1 o estar omitido para Host-only predeterminado; actual '$red'.") }
      }
    }
    $activos = @($adaptadores | Where-Object { $_.presente })
    if ($activos.Count -ne 1) { $errores.Add("Se exige un unico adaptador presente; encontrados $($activos.Count).") }
  }
  $resultados += [pscustomobject]@{ archivo=$resuelta; correcto=($errores.Count -eq 0); adaptadores=$adaptadores; errores=@($errores) }
}
$dir = Join-Path $RaizLaboratorio 'evidencias\aislamiento'
New-Item -ItemType Directory -Path $dir -Force | Out-Null
$archivo = Join-Path $dir ('vmx-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.json')
[ordered]@{ fechaUtc=(Get-Date).ToUniversalTime().ToString('o'); criterio='Un adaptador presente, connectionType=hostonly, VMnet1 predeterminado o explicito; sin NAT/bridged/adaptador adicional activo.'; limite='Verificacion estatica VMX; comprobar tambien interfaces reales y ausencia de gateway/routing/ICS antes de pruebas.'; resultados=$resultados } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $archivo -Encoding UTF8
$resultados | ConvertTo-Json -Depth 8
Write-Host "Evidencia: $archivo"
if (@($resultados | Where-Object {-not $_.correcto}).Count -gt 0) { exit 2 } else { exit 0 }


