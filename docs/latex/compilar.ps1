[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
Push-Location $PSScriptRoot
try {
  New-Item -ItemType Directory -Path 'build' -Force | Out-Null
  & pdflatex.exe -interaction=nonstopmode -halt-on-error -output-directory=build informe_visual.tex
  if($LASTEXITCODE -ne 0){throw 'LaTeX no compiló; consultar build/informe_visual.log'}
  & pdflatex.exe -interaction=nonstopmode -halt-on-error -output-directory=build informe_visual.tex
  if($LASTEXITCODE -ne 0){throw 'Segunda compilación falló'}
  Copy-Item -LiteralPath 'build\informe_visual.pdf' -Destination 'informe_visual.pdf' -Force
  Write-Host 'PDF actualizado: informe_visual.pdf'
} finally { Pop-Location }
