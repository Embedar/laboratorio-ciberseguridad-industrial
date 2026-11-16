[CmdletBinding()]
param(
  [string]$RaizLaboratorio = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent),
  [switch]$OmitirVmrun
)
$ErrorActionPreference = 'Stop'
$evidencias = Join-Path $RaizLaboratorio 'evidencias\host'
New-Item -ItemType Directory -Path $evidencias -Force | Out-Null
$fallos = New-Object System.Collections.Generic.List[string]
function Consultar-Cim([string]$Clase) {
  try { Get-CimInstance -ClassName $Clase -ErrorAction Stop }
  catch { $fallos.Add("${Clase}: $($_.Exception.Message)"); return $null }
}
$hostInfo = Consultar-Cim 'Win32_ComputerSystem'
$os = Consultar-Cim 'Win32_OperatingSystem'
$cpu = Consultar-Cim 'Win32_Processor'
$programa = @('C:\Program Files\VMware\VMware Workstation','C:\Program Files (x86)\VMware\VMware Workstation') | Where-Object { Test-Path -LiteralPath (Join-Path $_ 'vmrun.exe') } | Select-Object -First 1
$vmrun = if ($programa) { Join-Path $programa 'vmrun.exe' } else { $null }
$ejecutando = @()
$codigoVmrun = $null
if ($vmrun -and -not $OmitirVmrun) {
  $ejecutando = @(& $vmrun -T ws list 2>&1 | ForEach-Object { "$_" })
  $codigoVmrun = $LASTEXITCODE
  if ($codigoVmrun -ne 0) { $fallos.Add('vmrun list no pudo consultar las VM; revisar su salida.') }
}
$servicios = @()
try { $servicios = @(Get-Service | Where-Object { $_.Name -match 'vmware|vmnet' } | Select-Object Name,DisplayName,@{n='Status';e={"$($_.Status)"}}) }
catch { $fallos.Add("Servicios: $($_.Exception.Message)") }
$vmx = @()
$roots = @((Join-Path $env:USERPROFILE 'Documents\Virtual Machines'),(Join-Path $RaizLaboratorio 'vms'))
foreach ($r in $roots) { if (Test-Path -LiteralPath $r) { $vmx += @(Get-ChildItem -LiteralPath $r -Filter '*.vmx' -Recurse -File | Select-Object -ExpandProperty FullName) } }
$informe = [ordered]@{
  fechaUtc = (Get-Date).ToUniversalTime().ToString('o')
  alcance = 'Solo lectura; no inicia, apaga ni modifica VM, servicios o redes.'
  equipo = if($hostInfo) { $hostInfo | Select-Object Manufacturer,Model,TotalPhysicalMemory,HypervisorPresent } else { $null }
  sistema = if($os) { $os | Select-Object Caption,Version,FreePhysicalMemory,TotalVisibleMemorySize } else { $null }
  procesadores = @($cpu | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors,VirtualizationFirmwareEnabled)
  discos = @(Get-PSDrive -PSProvider FileSystem | Select-Object Name,Root,Used,Free)
  vmware = [ordered]@{ instalacion=$programa; version=if($programa){(Get-Item -LiteralPath (Join-Path $programa 'vmware.exe')).VersionInfo.ProductVersion}else{$null}; vmrun=$vmrun; codigoVmrun=$codigoVmrun; salidaVmrun=$ejecutando }
  servicios = $servicios
  configuracionesVmEncontradas = @($vmx | Sort-Object -Unique)
  erroresConsulta = @($fallos)
}
$archivo = Join-Path $evidencias ('inventario-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.json')
$informe | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $archivo -Encoding UTF8
Write-Host "Inventario guardado: $archivo"
$informe | ConvertTo-Json -Depth 8
