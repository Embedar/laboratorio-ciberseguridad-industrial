# Validación de la entrega y del repositorio

Revisión del17/11/2026. La auditoría del laboratorio corresponde al12/11/2026; no se repitieron ataques ni se modificaron las VMs durante la revisión documental.

| Comprobación | Resultado |
|---|---|
| Cotejo académico |22subítems,9entregables y5criterios de evaluación relacionados con evidencia y sección/página en MATRIZ_CUMPLIMIENTO.md |
| PDF LaTeX |13páginas,9imágenes; compilación pdfLaTeX en dos pasadas, sin avisos de desbordamiento; páginas renderizadas y revisadas visualmente |
| Evidencias de referencia |26/26 hashes de ejecución y2/2 de integridad correctos;7capturas principales presentes y con formato válido |
| Clonación desde GitHub |El repositorio privado publicado se clonó de nuevo; commit coincidente y35/35 comprobaciones correctas, sin config/descargas/vms/fuentes |
| Exportación del índice Git |Se creó una carpeta temporal exclusivamente con los archivos preparados;35/35 comprobaciones de evidencia pasaron también allí |
| Enlaces locales |19referencias locales Markdown verificadas en esa exportación, sin destinos ausentes |
| Python y Bash publicados |11fuentesPython analizadas con AST y6scriptsBash con bash -n, sin errores |
| PowerShell publicado |15fuentes analizadas con Parser, sin errores |
| Inicialización desde carpeta limpia |Preparar-Entorno creó directorios/configuración; una segunda llamada conservó exactamente la configuración previa. No se arrancaron VMs |
| Adaptador Java |Recompilado desde fuente con --release8 y JAR verificado; self-test correcto de unidad/registros sin abrir sockets |
| Huellas/readiness |Fixtures sin red para comparación SHA256/MD5, rechazo de clave distinta y flujo de preparación; instalador exige respuestaFC03 real en su uso normal |
| Publicación |Lista explícita de archivos; config/descargas/vms/fuentes/build excluidos; validación del índice para claves privadas, tokens, artefactos bloqueados y tamaño |

Las evidencias se marcan -text en .gitattributes para conservar sus bytes y hashes al clonar en Windows. Los scripts.sh usan LF. Las credenciales sintéticas públicas de Metasploitable se conservan deliberadamente para explicar la prueba; las credenciales personales y claves privadas no forman parte de Git.

## Alcance real de estas comprobaciones

El montaje funcional y sus comunicaciones se validaron en la corrida original. Las mejoras de bootstrap se comprobaron con sintaxis, fixtures, exportación limpia y compilación, pero no se reinstaló un juego completo de VMs nuevas desde cero el16/11/2026. Por tanto no se presenta esa instalación nueva como ejecutada.

La tabla de servicios conserva incertidumbres de Nmap. No se atribuye explotación de CVE, escrituraModbus, extracciónFTP, adquisiciónAD1 ni aplicación de mitigaciones no realizadas.

Para verificar los artefactos incluidos: `python scripts/windows/Verificar-Evidencias.py`. Antes de un commit: `python scripts/windows/Validar-Publicacion.py --staged`. Consultar el README para repetir la práctica en una corrida nueva y registrar sus propios resultados.


## Revisión anterior del16/11: informe y guía de comprobación

Se añadieron la tabla explícita dispositivo/IP/puertos/servicios y el inventario completo adyacente; se retiraron las notas de operación del control del computador. La matriz conserva los cinco criterios con su ponderación y ubicación de evidencias. El PDF final de nueve páginas se compiló en dos pasadas sin avisos Overfull/Underfull, se renderizó y se revisaron sus nueve páginas. Se comprobaron ambos SHA-256 completos dentro del PDF.

La nueva docs/COMANDOS_RAPIDOS.md separa consulta de evidencias conservadas y repetición con carpetas nuevas para el entorno instalado. Sus cinco bloques Bash pasaron bash -n y sus cinco bloques PowerShell pasaron el Parser. Se comprobaron los enlaces locales añadidos. Las evidencias originales siguen verificando35/35. No se encendieron las VMs ni se repitieron sondeos durante esta revisión documental; estos controles de sintaxis no se presentan como una nueva ejecución de red.

## Ampliación didáctica del17/11/2026

El PDF vigente tiene13páginas y9imágenes; reemplaza la edición anterior de9páginas. Se separaron conceptos de tráfico, lectura HTTP/Modbus y las tres partes de actividad3. Se actualizaron las ubicaciones en la matriz. El PCAP original se consultó con TShark sin modificarlo: tramas65/70,77,84 y100, conexión .10:55468→.20:23, stream4. Los bytes confirman usuario, contraseña de laboratorio y comandos. La explicación distingue la imagen de terminal de los datos del PCAP y las categorías CWE de identificadores CVE. Las páginas se revisaron renderizadas y la compilación final no informa Overfull/Underfull. No se repitieron conexiones de prueba a las VMs.
