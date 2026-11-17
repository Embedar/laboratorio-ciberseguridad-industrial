# Guía de lectura y ejecución

La guía completa y vigente de montaje y comandos está en el [README raíz](../README.md). Seguir sus pasos en orden: prerrequisitos/redes, Kali/SSH, componentes, PLC, víctima, comprobación previa, actividades, captura, integridad y exportación.

El [informe PDF](latex/informe_visual.pdf) presenta el procedimiento de la corrida real con imágenes y explicaciones concisas. El [informe técnico](INFORME_TECNICO.md) conserva los resultados ampliados. La [matriz](MATRIZ_CUMPLIMIENTO.md) relaciona los22 subítems y9 entregables con sus evidencias.

## Qué comprobar en cada actividad

1. **Reconocimiento:** equipos activos, IP, puertos, servicios y riesgos; conservar XML/NMAP/GNMAP, tabla y captura.
2. **Comunicaciones:** iniciar captura antes de generar tráfico; identificar TCP, HTTP y Modbus; explicar IP/puertos de origen/destino, solicitud/respuesta y riesgos del contenido legible.
3. **Vulnerabilidades:** investigar con fuentes primarias, escoger una condición observada, probar únicamente la víctima autorizada y registrar resultado, impacto y mitigación. Un banner no prueba una CVE.
4. **Integridad:** seleccionar una evidencia anterior, registrar SHA256, conservar el original, alterar solo una copia, recalcular y explicar la comparación.

Usar una carpeta nueva para cada corrida. Los hashes/tramas/puertos dinámicos del ejemplo no se reutilizan como resultado propio.

FTK ya se utilizó para incorporar la carpeta e inspeccionar el PCAP de referencia, con propiedades y hexadecimal visibles. No se creó AD1; el hash posterior se comprobó externamente con Get-FileHash. Si se exige un contenedor forense adicional, es un procedimiento diferente del ejercicio SHA256 solicitado.

Para el entorno ya instalado: [comandos rápidos por entregable práctico](COMANDOS_RAPIDOS.md).
