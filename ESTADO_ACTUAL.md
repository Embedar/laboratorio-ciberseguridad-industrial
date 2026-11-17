# Estado del laboratorio y documentación

## Configuración y práctica de referencia

Actividad real del12/11/2026: Kali.10 (4096MB/2CPU), Metasploitable2.20 (512MB/1CPU), Ubuntu/ModbusPal.30 (768MB/1CPU), red host-onlyVMnet1 192.168.212.0/24. Se verificaron SSH, rutas sin gateway, forwarding0 y FC03. Consulta del16/11/2026: las VMs estaban apagadas; esta revisión no vuelve a ejecutar las pruebas de red.

Las cuatro actividades yFTK están acreditadas por la corrida20261112T163453Z-9047, sus manifiestos, capturas y la inspección delPCAP. Resultados:30puertosTCP víctima; PLC22/502;154tramas/20940bytes;HTTP200;registros250,1000,1,750;Telnet con credencial sintética yFTP anónimo vacío.

## Revisión del16/11/2026

- PDF ampliado a9páginas y9imágenes, con montaje en8pasos y explicación de cada actividad.
- Tabla completa de puertos/servicios, TCP/origen-destino, investigación primaria, hashes completos y cinco riesgos con mitigación.
- docs/MATRIZ_CUMPLIMIENTO.md:22subítems y9entregables cotejados con evidencias y páginas.
- README: montaje desde clon nuevo y comandos por etapa; configuración local y huellas antes de autenticación.
- Correcciones de fuentes: directorios iniciales, rutas/usuario parametrizados, aliasSSH, compilación del wrapper, readinessFC03 y capturas de la corrida indicada.
- Validados parsers/sintaxis, fixtures sin red y autoprueba Java sin sockets. Las35 comprobaciones de evidencias originales siguen correctas (28hashes y7formatos de imagen). No se repitió la instalación completa en nuevasVMs.

## Publicación

Repositorio publicado y verificado el16/11/2026: privado, cuenta personal Embedar, rama main: https://github.com/Embedar/laboratorio-ciberseguridad-industrial . Se clonó desde GitHub y35/35 comprobaciones de evidencia pasaron, sin carpetas privadas locales. Se publica únicamente documentación/fuentes propias y evidencias revisadas. Configuración privada, claves, discos, dependencias, programas de terceros y PDF académico original quedan fuera del índiceGit.

ModbusPal usa su motor real sin GUI; no se creóAD1. Las mitigaciones están propuestas, no aplicadas a la víctima.

## Continuación

Leer README.md para montar/repetir; docs/INFORME_TECNICO.md para detalle, docs/latex/informe_visual.pdf para lectura y docs/MATRIZ_CUMPLIMIENTO.md para cotejar requisitos. La carpeta del robotSTM32 y su firmware no se modificaron.


Actualización: tabla explícita dispositivo/IP/puertos/servicios en el PDF, matriz de los cinco criterios y guía docs/COMANDOS_RAPIDOS.md para el entorno instalado.
