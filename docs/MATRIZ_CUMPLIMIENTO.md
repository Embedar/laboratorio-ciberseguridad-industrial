# Matriz de cumplimiento de la práctica de ciberseguridad industrial

Actividad técnica ejecutada el **12 de noviembre de 2026**; revisión documental realizada el **16 de noviembre de 2026**, hora de Bogotá. Fuente de requisitos: PDF académico original suministrado para la práctica (conservado localmente en fuentes/; no redistribuido en GitHub), secciones 4 a 10. Esta matriz contrasta requisitos, evidencias conservadas y contenido necesario en el informe ampliado. No representa una calificación ni certifica aceptación docente.

## 1. Alcance, estados y plan editorial

**Respaldado** indica que existe evidencia local del resultado. **Documentado** indica que el informe explica el resultado. **Verificado en PDF** indica que se comprobó la presencia y maquetación en la revisión final de ocho páginas; no significa una nueva ejecución del laboratorio. **Desviación declarada** corresponde al requisito formal VirtualBox sustituido por VMware a petición del usuario, sin aceptación docente acreditada.

El siguiente reparto fue contrastado con el PDF compilado y sus ocho páginas renderizadas, revisadas el 16 de noviembre de 2026:

| Sección del informe visual | Páginas verificadas | Contenido mínimo |
|---|---|---|
| 1. Montaje | 1–2 | Objetivo, alcance, ocho pasos de preparación, recursos, direcciones, arquitectura y aislamiento |
| 2. Reconocimiento | 3 | Comandos, captura 01 y tabla completa de puertos/servicios observados |
| 3. TCP, HTTP y Modbus | 4 | Capturas 02/03, TCP 1–3, HTTP 4/6, Modbus FC03 y origen/destino |
| 4. Prueba e investigación | 5 | Captura 04, Telnet, FTP, CWE-1392/CWE-319 y fuentes primarias |
| 5. Integridad | 6 | Captura 05, hashes completos, cambio de copia y verificación |
| 6. FTK | 7 | Capturas 06/07, incorporación frente a inspección y ausencia de AD1 |
| 7. Riesgos, conclusiones y referencias | 8 | Tres o más riesgos con impacto/mitigación, resultados, límites y bibliografía |

El informe Markdown conserva el detalle técnico; la versión visual debe ser comprensible por sí sola respecto a los nueve entregables. No basta remitir la tabla obligatoria a archivos externos.

## 2. Índice de evidencias utilizado en la auditoría

Las rutas de esta tabla son relativas a la raíz del laboratorio. El prefijo **R** utilizado en las matrices siguientes corresponde exclusivamente a `evidencias/ejecuciones/20261112T163453Z-9047/`.

| Clave | Archivo o conjunto | Qué acredita |
|---|---|---|
| E01 | `evidencias/aislamiento/vmx-20261112-113453-125.json` | Tres VMX con un adaptador host-only antes de las pruebas; comprobación estática |
| E02 | `R/00-preflight/` | Kali .10/24, eth0, rutas sin default, comprobaciones locales aprobadas |
| E03 | `R/01-nmap/descubrimiento.xml` y `.nmap` | Dos blancos activos .20/.30 |
| E04 | `R/01-nmap/metasploitable.xml` y `.nmap` | 30 puertos TCP abiertos; inventario completo de víctima |
| E05 | `R/01-nmap/plc.xml` y `.nmap` | TCP 22/502 abiertos; solo se examinaron esos dos puertos |
| E06 | `R/02-trafico/comunicaciones.pcapng`, `dumpcap.log`, `paquetes.csv`, `jerarquia-protocolos.txt` | 154 tramas, protocolos y números de trama |
| E07 | `R/02-trafico/http-headers.txt`, `http-body.html`, `http-curl.log` | Solicitud HTTP y respuesta 200 conservadas |
| E08 | `R/02-trafico/modbus-lecturas.txt` | Tres lecturas FC03 con registros [250,1000,1,750] |
| E09 | `R/03-vulnerabilidad/telnet.txt` | Autenticación msfadmin, id/uname y cierre |
| E10 | `R/03-vulnerabilidad/ftp-anonimo.txt` | Código 230, LIST y 226; listado de 0 bytes |
| E11 | `evidencias/04-integridad/20261112T163840Z-10974/` | Original, copia alterada, manifiesto, registro y verificación |
| E12 | `R/SHA256SUMS.txt` y `ejecucion.log` | 26 entradas verificadas; exclusiones documentadas |
| E13 | `evidencias/host/plc-final.txt` | PLC .30, servicio activo, listener TCP 502 y forwarding 0 |
| E14 | `evidencias/00-inventario/victima-ssh-verificada.txt` | Víctima .20 sin gateway en rutas observadas; forwarding IPv4 0 |
| E15 | `evidencias/05-ftk/registro-incorporacion.json`, `registro-inspeccion.json` | Carpeta incorporada e inspección PCAP en FTK 8.3.0.27 |
| E16 | `evidencias/capturas/01-nmap.png` a `05-integridad.png`; `06-ftk-carpeta.jpg`, `07-ftk-inspeccion.jpg` | Vistas gráficas de resultados y operaciones FTK |
| E17 | `evidencias/00-inventario/verificacion-final.json` | 35 comprobaciones: 28 hashes y presencia/formato de 7 imágenes; no son 35 hashes |
| E18 | `docs/arquitectura.png`, `evidencias/capturas/SESION_GRAFICA.txt` | Diagrama y procedencia Xvfb/SSH de las capturas Kali |

## 3. Actividad 1: reconocimiento, cada subítem

| Requisito de la guía | Cumplimiento y observación de evidencia | Correspondencia editorial prevista |
|---|---|---|
| 6.1.1 Identificar equipos activos | Respaldado E03: .20 y .30 activos. No se reconoce toda una red externa | Sección 2, pág. 3: dos blancos y alcance |
| 6.1.2 Reconocer direcciones IP | Respaldado E02/E03/E13/E14: Kali .10, víctima .20, PLC .30 | Sección 1, págs. 1–2; sección 2, pág. 3 |
| 6.1.3 Identificar puertos abiertos | E04: 30 abiertos y 65505 cerrados en víctima; E05: 22/502 abiertos en PLC | Sección 2, pág. 3: tabla y límites de exploración |
| 6.1.4 Determinar servicios | Tabla completa del Markdown coincide con Nmap: FTP, SSH, Telnet, HTTP, Samba y demás filas; etiquetas inciertas se preservan | Sección 2, pág. 3: incluir tabla, no solo ejemplos |
| 6.1.5 Identificar posibles riesgos | Markdown documenta cinco condiciones; cada una debe vincularse a evidencia e impacto | Sección 7, pág. 8 |
| Evidencia: captura y tabla de resultados | E16 captura 01 más E04/E05. Captura existente; tabla obligatoria existe en Markdown y debe estar en PDF ampliado | Sección 2, pág. 3; por comprobar en PDF |

Nmap 7.99 utilizó -sT, -sV, -sC, --version-light y -p- para la víctima; el PLC solo se exploró en TCP 22 y 502. No presentar los dos puertos del PLC como inventario exhaustivo. Los resultados no cubren UDP. Conservar `login?`, `unknown` y `mbap?` como incertidumbres de detección; FC03 complementa la identificación de 502, no borra lo observado por Nmap.

## 4. Actividad 2: comunicaciones, cada subítem

| Requisito de la guía | Cumplimiento y observación de evidencia | Correspondencia editorial prevista |
|---|---|---|
| 6.2.1 Iniciar captura de tráfico | E06: dumpcap sobre eth0 durante 90 s; 154 tramas y 0 descartadas registrados | Sección 3, pág. 4: método y total |
| 6.2.2 Identificar TCP | E06: tramas 1/2/3 SYN, SYN-ACK, ACK, .10:37150 ↔ .20:80 | Sección 3, pág. 4: explicar establecimiento, no solo decir TCP |
| 6.2.3 Analizar solicitudes/respuestas HTTP | E06/E07: trama 4 GET /, trama 6 HTTP 200; cuerpo y encabezados conservados | Sección 3, pág. 4, captura02 |
| 6.2.4 Identificar Modbus TCP | E06/E08: pares 14/16, 25/27, 35/37; unidad 1, FC03, dirección 0, cantidad 4 | Sección 3, pág. 4, captura03 |
| 6.2.5 Reconocer origen y destino | HTTP .10:37150→.20:80; Modbus .10→.30:502 con puertos cliente 54106/46034/46040 | Sección 3, pág. 4: tabla o pie explícito |
| 6.2.6 Analizar riesgos de información industrial sin protección | Datos legibles y registros simulados recuperados sin credenciales en el cliente; no se probó escritura ni un PLC físico | Secciones 3 y 7, págs. 4 y8 |
| Evidencia: capturas Wireshark y explicación | Capturas02/03 más PCAP y CSV originales. Identificar tramas y explicar qué demuestran | Sección 3, pág. 4; por comprobar legibilidad en PDF |

La jerarquía registra 133 tramas TCP, 2 HTTP, 6 Modbus TCP, 33 Telnet y 16 FTP; categorías anidadas, no sumar como conjuntos independientes. El tráfico de fondo DNS/NBNS/SMB no demuestra una ruta a Internet.

## 5. Actividad 3: vulnerabilidades, cada subítem

| Requisito de la guía | Cumplimiento y observación de evidencia | Correspondencia editorial prevista |
|---|---|---|
| 6.3.1 Identificar servicios expuestos | E04/E05 y tabla del Markdown | Sección 2, pág. 3 |
| 6.3.2 Investigar vulnerabilidades asociadas | Revisión documental 16 de noviembre: Rapid7 documenta credencial de laboratorio; CWE-1392 clasifica credenciales por defecto; CWE-319 encuadra exposición de contraseña; ftp-anon documenta alcance de la comprobación. No equivale a CVE explotada | Sección 4, pág. 5: fuente→debilidad→resultado→límite; sección 7 referencias |
| 6.3.3 Determinar impacto potencial | Acceso como msfadmin y credencial visible; registros Modbus legibles; impactos separados de acciones efectivamente probadas | Sección 4, pág. 5 y sección 7, pág. 8 |
| 6.3.4 Realizar prueba controlada | E09: autenticación Telnet aceptada; id devuelve uid 1000; uname confirma sistema. E10: FTP anónimo 230, LIST 226, 0 bytes | Sección 4, pág. 5 y captura 04 |
| 6.3.5 Documentar resultado y mitigación | E09/E10 más tabla de riesgos Markdown; recomendar cambiar credenciales, retirar Telnet/FTP y restringir acceso | Secciones 4 y 7, págs. 5 y8 |
| Restricción: VM autorizada y red aislada | Blanco del script Telnet fijo .20; E01/E02/E13/E14 delimitan red. Host-only incluye anfitrión | Sección 1, págs. 1–2 y sección4, pág. 5 |
| Evidencia: descripción, captura y recomendación | Captura04, transcripciones y fuentes primarias. No se escaló a root, no se instaló persistencia ni se explotó CVE | Sección 4, pág. 5; por comprobar referencia explícita en PDF |

La investigación añadida el 16 de noviembre desarrolla evidencia obtenida el 12 de noviembre; no se debe fechar como una nueva explotación. CWE es una categoría de debilidad, no identificador CVE del producto. FTP anónimo con listado vacío no acredita permiso de subida ni exposición de archivos. Un banner vsftpd 2.3.4 no acredita explotación de su puerta trasera.

## 6. Actividad 4: integridad, cada subítem

| Requisito de la guía | Cumplimiento y observación de evidencia | Correspondencia editorial prevista |
|---|---|---|
| 6.4.1 Seleccionar evidencia anterior | E06: comunicaciones.pcapng generado en actividades previas | Sección 5, pág. 6: indicar nombre/origen |
| 6.4.2 Calcular SHA-256 | Fuente y original comparten hash d33b57…69d68c | Sección 5, pág. 6: hash completo |
| 6.4.3 Registrar resultado | E11: SHA256SUMS.txt y registro.txt conservados | Sección 5, pág. 6, captura 05 |
| 6.4.4 Modificar una copia | Original20940 bytes; alterada 20979 bytes. Sufijo 39 bytes: salto de línea, ALTERACION CONTROLADA DEL LABORATORIO, salto de línea | Sección 5, pág. 6: cambio exacto; fuente conservada |
| 6.4.5 Recalcular hash | Copia alterada 757299…5e48ec, distinta del original | Sección 5, pág. 6: segundo hash completo |
| 6.4.6 Comparar y explicar importancia | Revisión16 de noviembre confirma fuente=original y diferencia de copia; 26/26 entradas de ejecución y 2/2 de integridad correctas | Sección 5, pág. 6: integridad frente a referencia, no autoría |
| Evidencia: captura y explicación de hash | Captura05, originales, manifiestos y verificaciones | Sección 5, pág. 6; por comprobar claridad en PDF |

Hashes íntegros:

- Fuente/original: `d33b57daa6af812c89638e4aaaac74c9a910f7a730d3ba5372326f81fa69d68c`.
- Copia alterada: `75729913650b748c5889879b7e357d9a1759fd8f60f0ad37383b8b63305e48ec`.

Los dos OK del manifiesto de integridad significan que cada archivo coincide con su propia entrada; no que original y alterada sean iguales. El manifiesto de ejecución excluye su propio archivo, el log abierto y ESTADO.txt; tampoco cubre capturas/documentos creados después. Un atributo de solo lectura no es bloqueador forense.

## 7. Los nueve entregables

| Entregable | Evidencia/cobertura documental | Ubicación verificada en informe visual |
|---|---|---|
| 1. Diagrama implementado | Arquitectura real, E01/E02/E13/E14 | Sección 1, págs. 1–2 |
| 2. Tabla dispositivos/IP/puertos/servicios | Tabla Markdown y XML E03/E04/E05; incluye30 puertos víctima y 22/502 PLC | Secciones 1/2, págs. 1–3 |
| 3. Evidencias Nmap | XML/NMAP/GNMAP y captura 01 | Sección 2, pág. 3 |
| 4. Capturas y análisis Wireshark | PCAP/CSV y capturas 02/03; TCP/HTTP/Modbus | Sección 3, pág. 4 |
| 5. Al menos tres riesgos | Cinco condiciones en Markdown; conservar evidencia, impacto y mitigación | Sección 7, pág. 8 |
| 6. Prueba controlada | Telnet y FTP; captura 04; investigación primaria sin CVE explotada | Sección 4, pág. 5 |
| 7. Cálculo y verificación SHA-256 | E11/E12, captura 05 y hashes completos | Sección 5, pág. 6 |
| 8. Recomendaciones | Relacionadas individualmente con los riesgos; son propuestas no aplicadas a víctima | Sección 7, pág. 8 |
| 9. Conclusiones | Resultados reales y límites; no afirmar seguridad industrial general | Sección 7, pág. 8 |

## 8. Herramientas, adaptación y seguridad

| Elemento de la guía | Estado y límite |
|---|---|
| VirtualBox | **Única desviación formal de herramienta:** reemplazado por VMware Workstation por petición del usuario; aceptación docente no acreditada |
| Kali/Nmap/Linux Terminal | Utilizados; resultados y scripts conservados |
| Metasploitable 2 | Imagen importada, no instalada desde cero; víctima en host-only |
| ModbusPal | Motor real 1.6b mediante adaptador Java local headless; no es un simulador Python sustituto. No se acreditó su ventana GUI original, que la guía no exige expresamente |
| Wireshark | Captura con dumpcap y análisis con TShark/Wireshark; vistas reales en sesión Xvfb por SSH |
| FTK Imager | Carpeta incorporada e inspección real del PCAP; capturas 06/07 y registros. Hash calculado externamente con Get-FileHash, no atribuirlo a FTK. No AD1 |
| Red aislada | Tres VMX host-only; comprobaciones locales de rutas/forwarding; host-only incluye Windows. El chequeo VMX no prueba por sí solo ausencia absoluta de ICS |
| Alcance controlado | Solo víctimas virtuales .20/.30; sin pruebas contra redes físicas/Internet |
| Evidencias ordenadas | Corrida única identificada, originales separados de copia alterada, capturas y registros FTK |

El ejemplo 192.168.56.0/24 del PDF es una referencia de comando. El montaje 192.168.212.0/24 y los blancos explícitos no constituyen por sí mismos una omisión del objetivo de reconocimiento. El PLC limpio usó NAT temporal para instalar paquetes antes de quedar aislado; no afirmar ausencia de NAT durante toda la preparación. La víctima no se conectó a NAT para ejecutar la práctica.

## 9. Montaje efectivamente documentado

1. Inventario Windows/VMware; reutilización de Kali existente, evitando duplicar su disco.
2. Descarga e importación Metasploitable 2; CRC del ZIP y hash local; configuración host-only de 512 MB/1 CPU antes de su uso.
3. Configuración víctima .20 y SSH por clave; evidencia posterior sin gateway y forwarding 0.
4. Descarga VMDK Ubuntu y contraste con SHA256SUMS oficial; semilla NoCloud y VM PLC768 MB/1 CPU.
5. Aprovisionamiento temporal del PLC limpio para SSH/Tools/Java; transición a .30 host-only sin gateway; incidencia de nombre de interfaz resuelta con match MAC/nombre persistente.
6. Instalación del motor real ModbusPal 1.6b y servicio de usuario lab con capacidad de abrir502; valores simulados 250, 1000, 1, 750.
7. Comprobación VMX/rutas/interfaces y ejecución de la auditoría; captura, Telnet/FTP y ejercicio de integridad real.
8. Exportación/verificación de evidencias, capturas Xvfb por SSH e incorporación/inspección del PCAP en FTK Windows.

El CRC comprueba coherencia interna del ZIP, no identidad del editor. Un SHA-256 local registra los bytes conservados y permite detectar cambios posteriores; no equivale a firma del proveedor. Para Ubuntu se contrastó con el listado oficial descargado, pero no se afirma una validación de firma GPG de ese listado si no existe evidencia de ella.

## 10. Revisión final de la versión ampliada

La versión ampliada se compiló con pdfLaTeX: ocho páginas, nueve imágenes (arquitectura más ocho capturas), tabla de30 puertos de la víctima y22/502 del PLC, ambos hashes completos, cinco riesgos y fuentes primarias. Se revisaron visualmente las ocho páginas renderizadas y se verificó ausencia de avisos de desbordamiento. La revisión amplía documentación; no repite ataques ni aplica mitigaciones.

Conservar la ponderación original: reconocimiento 20%, comunicaciones 20%, vulnerabilidades 25%, integridad 15%, informe/recomendaciones 20%. No transformar esta correspondencia en una nota asignada.

Fuentes primarias revisadas el16 de noviembre de 2026: [Rapid7, guía de Metasploitable 2](https://docs.rapid7.com/metasploit/metasploitable-2-exploitability-guide/), [MITRE CWE-1392](https://cwe.mitre.org/data/definitions/1392.html), [MITRE CWE-319](https://cwe.mitre.org/data/definitions/319.html) y [Nmap ftp-anon](https://nmap.org/nsedoc/scripts/ftp-anon.html). Sus categorías apoyan la interpretación; las pruebas concretas se atribuyen a los archivos locales.


