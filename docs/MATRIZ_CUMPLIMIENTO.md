# Matriz de requisitos, entregables y criterios de evaluación

Fuente: guía académica original, secciones 6, 7, 8 y 10, conservada localmente en `fuentes/Practica_Ciberseguridad.pdf`. Práctica de referencia del 12/11/2026; revisión documental del 17/11/2026. Esta matriz comprueba cobertura y evidencia; la calificación corresponde al docente.

El informe visual contiene trece páginas y nueve imágenes. Las páginas que siguen corresponden al PDF compilado. **R** representa `evidencias/ejecuciones/20261112T163453Z-9047/`; **I**, `evidencias/04-integridad/20261112T163840Z-10974/`.

## 1. Los nueve entregables de la guía

| N.º | Entregable exigido | Dónde está en el informe PDF | Evidencia y comprobación |
|---|---|---|---|
| 1 | Diagrama de infraestructura implementada | Sección 1, pág. 1; montaje págs. 1–2 | Diagrama con roles/IP/recursos; captura de estado de Kali y configuración de red |
| 2 | Tabla de dispositivos, direcciones IP, puertos y servicios | Sección 2, pág. 3: cuatro columnas explícitas; sección 3, pág. 4: inventario completo puerto/servicio | Windows, Kali, víctima y PLC; 30 puertos de víctima y 22/502 del PLC; alcance del sondeo indicado |
| 3 | Evidencias de reconocimiento Nmap | Captura en pág. 3; explicación e inventario en pág. 4 | `R/01-nmap/descubrimiento`, `metasploitable`, `plc`, en formatos NMAP/XML/GNMAP |
| 4 | Capturas y análisis Wireshark | Sección 4, págs. 6–7: capturas HTTP y Modbus, TCP y origen/destino | `R/02-trafico/comunicaciones.pcapng`, CSV, HTTP y lecturas FC03 |
| 5 | Al menos tres riesgos de seguridad | Sección 8, pág. 13: cinco condiciones con evidencia, impacto y medida | Telnet/credencial predeterminada, HTTP legible, Modbus sin autenticación, FTP anónimo y firma SMB desactivada |
| 6 | Prueba controlada de vulnerabilidad | Sección 5, págs. 8–10: investigación, resultado, captura y mitigación | `R/03-vulnerabilidad/telnet.txt`, PCAP y FTP complementario |
| 7 | Cálculo y verificación SHA-256 | Sección 6, pág. 11: procedimiento, captura y ambos hashes íntegros; FTK complementario pág. 12 | `I/SHA256SUMS.txt`, registro, original, copia alterada y verificación; manifiesto de R |
| 8 | Recomendaciones para mejorar la seguridad | Secciones 5 y 8, págs. 8–10 y 13 | Cada riesgo tiene una medida concreta y una forma de corroborarla |
| 9 | Conclusiones del trabajo | Sección 8, pág. 13 | Síntesis del reconocimiento, comunicaciones, acceso controlado e integridad |

## 2. Actividades: cotejo de los 22 subítems

### Actividad 1: reconocimiento (cinco subítems)

| Requisito | Resultado respaldado | PDF |
|---|---|---|
| 6.1.1 Identificar equipos activos | Descubrimiento: `.20` y `.30` activos | Págs. 3–4 |
| 6.1.2 Reconocer IP | Tabla explícita: anfitrión `.1`, Kali `.10`, víctima `.20`, PLC `.30` | Págs. 1–4 |
| 6.1.3 Identificar puertos abiertos | Víctima: 30 abiertos de 65.535 TCP; PLC: abiertos 22/502, únicos puertos sondeados | Págs. 3–4 |
| 6.1.4 Determinar servicios | Tabla completa con puertos/servicios/versiones y etiquetas inciertas conservadas | Pág. 4 |
| 6.1.5 Identificar riesgos asociados | Selección de servicios inseguros y cinco riesgos con impacto/medida | Págs. 4 y 13 |

Evidencia exigida: captura Nmap presente en pág. 3 y tablas de resultados en págs. 3–4. No se examinó UDP. `login?`, `unknown` y `mbap?` conservan la incertidumbre de Nmap; FC03 confirma que TCP 502 corresponde al servicio Modbus.

### Actividad 2: comunicaciones (seis subítems)

| Requisito | Resultado respaldado | PDF |
|---|---|---|
| 6.2.1 Iniciar captura | dumpcap, eth0, 90 segundos, 154 tramas, cero descartes registrados | Págs. 6–7 |
| 6.2.2 Identificar TCP | Tramas 1/2/3: SYN, SYN-ACK, ACK de `.10:37150` a `.20:80` y respuesta | Págs. 6–7 |
| 6.2.3 Analizar HTTP | Trama 4 GET `/`; trama 6 respuesta `200 OK`; contenido legible | Págs. 6–7 |
| 6.2.4 Identificar Modbus TCP | Pares 14/16, 25/27, 35/37; unidad 1, FC03, dirección PDU 0, cantidad 4, valores [250,1000,1,750] | Págs. 6–7 |
| 6.2.5 Reconocer origen/destino | HTTP `.10→.20:80`; Modbus `.10→.30:502`, respuestas en sentido inverso | Págs. 6–7 |
| 6.2.6 Analizar riesgos de información industrial sin protección | Valores recuperados sin autenticación del cliente; riesgo e impacto de lecturas no autorizadas | Págs. 6–7 y 13 |

Evidencia exigida: dos capturas Wireshark con explicación de protocolos en págs. 6–7. Los datos del PLC son simulados; no se probó escritura. La jerarquía de protocolos tiene categorías anidadas, que no deben sumarse como conjuntos independientes.

### Actividad 3: vulnerabilidades (cinco subítems)

| Requisito | Resultado respaldado | PDF |
|---|---|---|
| 6.3.1 Identificar servicios expuestos | Inventario Nmap de víctima y PLC | Págs. 3–4 |
| 6.3.2 Investigar vulnerabilidades | Rapid7: credencial de laboratorio; CWE-1392: credenciales predeterminadas; CWE-319: información sensible en claro; Nmap: alcance de ftp-anon | Págs. 8–10 y referencias pág. 13 |
| 6.3.3 Determinar impacto potencial | Acceso como msfadmin y exposición de credenciales en Telnet; impactos de otras condiciones separados de lo efectivamente probado | Págs. 8–10 y 13 |
| 6.3.4 Prueba controlada | Telnet acepta `msfadmin/msfadmin`; `id` devuelve uid 1000; `uname -a`; cierre de sesión | Págs. 8–10 |
| 6.3.5 Documentar resultado y mitigación | Captura/transcripción; cambiar credencial, retirar Telnet y usar SSH; indicar cómo verificar el cierre/rechazo | Págs. 8–10 y 13 |

Evidencia exigida: descripción, captura y recomendación presentes en págs. 8–10. Restricción cumplida: prueba únicamente contra la víctima autorizada `.20` en la red aislada. FTP anónimo aceptó código 230 y un listado vacío; no se acreditó extracción/carga. No se presenta una categoría CWE ni un banner como CVE explotada.

### Actividad 4: integridad (seis subítems)

| Requisito | Resultado respaldado | PDF |
|---|---|---|
| 6.4.1 Seleccionar evidencia anterior | PCAP de actividad 2, 20.940 bytes | Pág. 11 |
| 6.4.2 Calcular SHA-256 | Fuente/original: `d33b57…69d68c`, valor completo en informe | Pág. 11 |
| 6.4.3 Registrar el resultado | Manifiestos, registro y captura conservados | Pág. 11 |
| 6.4.4 Modificar una copia | Solo segunda copia; sufijo de 39 bytes; tamaño 20.979 bytes | Pág. 11 |
| 6.4.5 Recalcular hash | Copia: `757299…5e48ec`, valor completo diferente | Pág. 11 |
| 6.4.6 Comparar y explicar integridad | Fuente=original; copia diferente; 26/26 entradas de ejecución y 2/2 de integridad verificadas | Pág. 11 |

Evidencia exigida: captura y explicación SHA-256 presentes. FTK incorporó la carpeta e inspeccionó el PCAP, propiedades y hexadecimal (pág. 12). El hash posterior corresponde a Get-FileHash; la revisión es de archivos, sin atribuirle adquisición física ni un contenedor AD1.

## 3. Criterios de evaluación y evidencia para sustentarlos

Se conserva la ponderación de la sección 8 de la guía. El porcentaje es el peso del criterio, no una nota autoasignada.

| Criterio | Peso | Cobertura verificable en la entrega |
|---|---|---|
| Reconocimiento de infraestructura | 20% | Equipos/IP, alcance explícito, tabla de 30 puertos de víctima y 22/502 del PLC, servicios/versiones, captura Nmap y selección de riesgos (págs. 3–4) |
| Análisis de comunicaciones | 20% | Captura real; establecimiento TCP, solicitud/respuesta HTTP, FC03, origen/destino, filtros y riesgos; dos capturas comentadas (págs. 6–7) |
| Identificación de vulnerabilidades | 25% | Fuentes primarias, condición insegura, prueba aislada, resultado comprobado, impacto y mitigación; captura y transcripción (págs. 8–10; síntesis pág. 13) |
| Análisis forense e integridad | 15% | Evidencia seleccionada, SHA-256 registrado, copia modificada, recálculo, comparación e interpretación; capturas de integridad y FTK (págs. 11–12) |
| Informe técnico y recomendaciones | 20% | Nueve entregables dentro del informe; montaje paso a paso, diagrama, tablas, capturas explicadas, cinco medidas verificables, conclusiones y referencias (págs. 1–13) |
| **Total** | **100%** | Los cinco criterios disponen de contenido y evidencia identificables |

## 4. Conservación, ejecución y comprobación

- Pruebas limitadas a `.20/.30`; VMnet1 host-only, rutas locales sin gateway y reenvío desactivado. Host-only también incluye al anfitrión.
- Evidencias organizadas por corrida; originales separados de la copia alterada. El atributo de solo lectura evita accidentes, pero no constituye un bloqueador forense.
- ModbusPal 1.6b proporciona el motor industrial real y atiende FC03; los cuatro registros son constantes de prueba.
- Las medidas propuestas no se aplicaron a la víctima para conservar el entorno didáctico. No se afirman escritura Modbus, acceso root, explotación de CVE ni seguridad de PLC físicos.
- [Comandos rápidos](COMANDOS_RAPIDOS.md): comprobar entregables prácticos conservados o producir una corrida nueva sin reinstalar. Diagramas, tablas, recomendaciones y conclusiones se verifican documentalmente.
- `python scripts/windows/Verificar-Evidencias.py`: 35 comprobaciones, correspondientes a 28 hashes y presencia/formato de siete capturas. No son 35 hashes.

Los hashes/tramas de la corrida original no se atribuyen a comprobaciones futuras. Una corrida nueva conserva sus propios resultados. La revisión documental amplía la exposición de los resultados, sin cambiar los archivos de evidencia originales.

## Revisión didáctica del17/11/2026

Conceptos de TCP, IP, tramas y PCAPNG en pág.5; HTTP y Modbus en págs.6–7; actividad3 desarrollada en págs.8–10. Cada imagen tiene explicación de qué muestra, cómo leerla y qué resultado respalda. La terminal Telnet y el contenido del PCAP se presentan como evidencias diferentes. Se releyeron sin modificarlos los bytes de las tramas65,70,77,84 y100 y el stream TCP4. [Explicación ampliada y comandos](ACTIVIDAD_3_EXPLICADA.md).
