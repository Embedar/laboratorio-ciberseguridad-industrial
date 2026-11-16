[CmdletBinding()]
param(
  [string]$RaizLaboratorio=(Split-Path (Split-Path $PSScriptRoot -Parent) -Parent),
  [switch]$Metasploitable,
  [switch]$CompilarWrapper
)
$ErrorActionPreference='Stop'
python -c 'import sys; assert sys.version_info >= (3,11), "Se requiere Python 3.11+"'
if($LASTEXITCODE){throw 'Se requiere Python 3.11+'}
New-Item -ItemType Directory -Path (Join-Path $RaizLaboratorio 'descargas') -Force | Out-Null
$jar=Join-Path $RaizLaboratorio 'descargas\ModbusPal.jar'
$expected='cbc6423b8a39ada050c790b86d0eecd08b88c2d37a73382cd20a68b382101aec'
if(-not(Test-Path -LiteralPath $jar)){
  $part=$jar+'.part'
  Invoke-WebRequest 'https://downloads.sourceforge.net/project/modbuspal/modbuspal/RC%20version%201.6b/ModbusPal.jar' -OutFile $part
  if((Get-FileHash -LiteralPath $part -Algorithm SHA256).Hash -ine $expected){throw 'JAR distinto del binario 1.6b validado; no se instala'}
  Move-Item -LiteralPath $part -Destination $jar
}
if((Get-FileHash -LiteralPath $jar -Algorithm SHA256).Hash -ine $expected){throw 'Hash de JAR no coincide'}
Write-Host 'ModbusPal verificado. Hash local de referencia del proyecto; no es firma del proveedor.'
if($Metasploitable){
  $zip=Join-Path $RaizLaboratorio 'descargas\metasploitable-linux-2.0.0.zip'
  if(-not(Test-Path -LiteralPath $zip)){
    if([IO.Path]::GetFullPath($RaizLaboratorio) -ne [IO.Path]::GetFullPath((Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))){throw 'Descarga por rangos requiere scripts dentro de la raiz elegida'}
    python (Join-Path $PSScriptRoot 'download_metasploitable_parallel.py')
    if($LASTEXITCODE){throw 'Fallo descarga Metasploitable'}
  }
  python -c 'import pathlib,sys,zipfile; p=pathlib.Path(sys.argv[1]); assert p.stat().st_size==865084584,"Tamano ZIP incorrecto"; z=zipfile.ZipFile(p); assert z.testzip() is None,"CRC ZIP incorrecto"; print("ZIP tamano y CRC OK")' $zip
  if($LASTEXITCODE){throw 'ZIP no supera validacion'}
}
if($CompilarWrapper){
  & javac --release 8 -cp $jar -d (Join-Path $RaizLaboratorio 'scripts\plc') (Join-Path $RaizLaboratorio 'scripts\plc\ModbusPalHeadless.java')
  if($LASTEXITCODE){throw 'Fallo compilacion Java; instalar JDK'}
  & java -Xms32m -Xmx128m '-Djava.awt.headless=true' -cp ($jar+[IO.Path]::PathSeparator+(Join-Path $RaizLaboratorio 'scripts\plc')) ModbusPalHeadless --self-test
  if($LASTEXITCODE){throw 'Fallo self-test Java'}
}
