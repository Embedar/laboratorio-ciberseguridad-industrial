# Informe paso a paso en LaTeX

Versión revisada el 16/11/2026: ocho páginas y nueve imágenes. Mantiene la práctica real del 12/11/2026; amplía montaje, tabla completa, TCP/HTTP/Modbus, investigación, SHA-256, FTK, riesgos y conclusiones.

- `informe_visual.tex`: fuente editable.
- `informe_visual.pdf`: PDF compilado y revisado.
- `imagenes/`: imágenes originales necesarias para compilar.
- `build/`: auxiliares y respaldo de la versión anterior; no se publica.

Abrir el `.tex` en TeXstudio y pulsar F5, o ejecutar `./compilar.ps1` desde PowerShell7 en esta carpeta para guardar auxiliares en build. Requiere TeX Live/pdfLaTeX con los paquetes declarados en el preámbulo.

La correspondencia por requisito está en `../MATRIZ_CUMPLIMIENTO.md`; la guía de todos los comandos está en el README raíz. Las cifras y tramas corresponden a la corrida identificada en el informe, no a una nueva auditoría del 16 de noviembre.
