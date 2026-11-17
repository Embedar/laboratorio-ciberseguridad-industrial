# Actividad 3 explicada desde cero

La práctica original se ejecutó el 12/11/2026. Esta explicación se revisó el 17/11/2026 a partir de su transcripción y archivo de tráfico, sin repetir el acceso a la víctima.

## 1. Qué había que demostrar y para qué entregable

El **entregable 6** pide evidencia de una prueba controlada sobre un servicio vulnerable. Aquí se comprobó si Metasploitable 2 aceptaba su usuario y contraseña de instalación mediante Telnet. No se necesitaba ejecutar un ataque complejo: una configuración insegura comprobable también permite estudiar una vulnerabilidad de la infraestructura.

Se eligió Telnet porque el reconocimiento de la actividad 1 había encontrado `23/tcp open telnet` en `192.168.212.20`. La prueba se limitó a esa máquina autorizada y a la red aislada. El resultado también aporta evidencia para los **riesgos del entregable 5** y las **recomendaciones del entregable 8**.

Se estudiaron dos condiciones distintas:

1. La cuenta conservaba una credencial pública predeterminada y la aceptaba.
2. El canal de Telnet transmitía usuario y contraseña sin cifrado.

Cambiar la contraseña corrige la primera condición, pero no protege por sí solo la comunicación Telnet observada; por eso se recomienda también un canal cifrado.

## 2. Qué son TCP, un puerto y Telnet

**IP, Internet Protocol**, permite identificar los equipos de esta red: Kali tiene `192.168.212.10`; la víctima, `192.168.212.20`. Cuando el informe abrevia `.10` o `.20`, se refiere a esas direcciones completas.

**TCP, Transmission Control Protocol**, transporta un flujo de bytes entre dos extremos con control de orden y entrega. No proporciona cifrado por sí mismo. Cada extremo se identifica por una dirección IP y un puerto.

Un **puerto** es un número utilizado para dirigir la conexión al servicio correspondiente. El servidor Telnet de la víctima escuchaba en el puerto **23**; Kali utilizó el puerto temporal **55468** en la corrida original:

```text
Kali (cliente)                         Metasploitable 2 (servidor)
192.168.212.10:55468  <---- TCP ---->   192.168.212.20:23
```

**Telnet** es un protocolo de terminal remota: permite escribir desde un equipo y recibir preguntas o resultados del otro. El cliente envía respuestas a `login:` y `Password:`; si el servidor las acepta, permite utilizar una terminal remota. La [especificación RFC 854](https://www.rfc-editor.org/rfc/rfc854) describe su uso sobre TCP. En esta sesión, los datos viajaron sin cifrarse.

Un puerto abierto indica que es posible contactar un servicio. La autenticación aceptada y el tráfico observado son las comprobaciones posteriores que permiten describir las debilidades.

## 3. Qué son Rapid7, MITRE, CWE y CVE

| Término | Significado | Papel en esta práctica |
|---|---|---|
| Rapid7 | Empresa de ciberseguridad cuya documentación oficial presenta Metasploitable 2 y su credencial de laboratorio | Fuente para conocer el entorno y la credencial pública; no se ejecutó un programa llamado Rapid7 |
| MITRE | Nombre de una organización sin ánimo de lucro que participa en iniciativas de conocimiento de ciberseguridad | Se consultó el catálogo CWE publicado en su sitio; no se instaló MITRE en una VM |
| CWE | Common Weakness Enumeration: catálogo de tipos de debilidades | Permite clasificar la condición observada |
| CWE-1392 | Categoría «Use of Default Credentials»: uso de credenciales predeterminadas | Se relaciona con que la víctima aceptó `msfadmin/msfadmin` |
| CWE-319 | Categoría «Cleartext Transmission of Sensitive Information»: transmisión de información sensible en claro | Se relaciona con la contraseña legible en el tráfico |
| CVE | Common Vulnerabilities and Exposures: sistema de identificadores de vulnerabilidades concretas divulgadas públicamente | Sus identificadores tienen forma `CVE-año-número`. Esta práctica no demostró explotación de una CVE específica |

Los números **1392 y 319 identifican categorías de debilidad**. No son puertos ni números de trama. Las referencias ayudan a explicar lo observado; la demostración procede de las evidencias del laboratorio.

Fuentes: [Rapid7, Metasploitable 2](https://docs.rapid7.com/metasploit/metasploitable-2/), [MITRE, organización](https://www.mitre.org/who-we-are), [CWE-1392](https://cwe.mitre.org/data/definitions/1392.html), [CWE-319](https://cwe.mitre.org/data/definitions/319.html) y [descripción del programa CVE](https://www.cve.org/Resources/Media/Archives/OldWebsite/index.html).

## 4. Qué se hizo, paso a paso

1. **Comprobar el servicio.** Nmap encontró Telnet en la víctima. Nmap es el programa de reconocimiento que identifica equipos, puertos y servicios.
2. **Mantener activa la captura.** Dumpcap registraba la interfaz `eth0` de Kali durante 90 segundos, como parte de la actividad 2. Esa captura incluyó también la sesión Telnet.
3. **Abrir la conexión.** El script propio `Prueba-Telnet.py` inició el cliente Telnet hacia `.20:23`. Utiliza **pexpect**, una biblioteca Python que espera preguntas de terminal y envía respuestas.
4. **Enviar una credencial conocida.** Ante `login:` y `Password:` se envió una vez `msfadmin` en ambos casos. Es la credencial pública de esta máquina didáctica; no se adivinó mediante fuerza bruta.
5. **Comprobar la identidad.** Tras aceptar la sesión, `id` devolvió `uid=1000(msfadmin)`. UID significa identificador de usuario; el valor 1000 identifica a msfadmin en esa máquina. **Root** es la cuenta administrativa de UID 0: el resultado no demuestra acceso root.
6. **Consultar el sistema.** `uname -a` mostró información del sistema Linux y su kernel, el núcleo del sistema operativo.
7. **Cerrar.** `exit` terminó la sesión. No se ordenó modificar archivos ni elevar privilegios; el sistema puede registrar normalmente el inicio de sesión.
8. **Contrastar con la red.** Se abrió el PCAP en Wireshark para comprobar qué bytes viajaron durante esa misma sesión.

## 5. Cómo leer la captura de la terminal

![Sesión Telnet y consultas de identidad](latex/imagenes/04-telnet.png)

Esta imagen respalda el **entregable 6**. Debe leerse de arriba hacia abajo:

| Parte de la captura | Qué significa |
|---|---|
| Blanco `.20:23` y credencial de prueba | Delimita el destino autorizado y el intento realizado |
| `RESULTADO: acceso con credencial por defecto y consultas confirmados` | Resumen de la ejecución del script |
| `msfadmin@metasploitable:~$` | Indicador de que se obtuvo una terminal como msfadmin dentro de la víctima |
| `id` y `uid=1000(msfadmin)` | Consulta y respuesta que confirman la identidad |
| `uname -a` y la línea Linux | Consulta y respuesta con información del sistema |
| `logout` / conexión cerrada | Terminación de la sesión |

La transcripción completa está en `evidencias/ejecuciones/20261112T163453Z-9047/03-vulnerabilidad/telnet.txt`. La imagen es una vista de esa transcripción. **Las tramas 65 y 70 no aparecen en esta imagen**: pertenecen al archivo de tráfico que se explica a continuación.

## 6. Qué es el PCAP, de dónde salió y qué es una trama

**PCAP significa Packet Capture**, captura de paquetes. Se usa habitualmente para nombrar un archivo que conserva tráfico. En este laboratorio el formato concreto es **PCAPNG, Packet Capture Next Generation**, con extensión `.pcapng`. No es una captura de pantalla: almacena bytes de comunicaciones y metadatos que Wireshark puede volver a interpretar.

Se generó durante la actividad 2: primero se inició dumpcap en Kali, después se produjeron las comunicaciones HTTP, Modbus y Telnet, y finalmente se cerró el archivo. La corrida original conserva **154 tramas y 20.940 bytes** en:

```text
evidencias/ejecuciones/20261112T163453Z-9047/02-trafico/comunicaciones.pcapng
```

La ruta parte de la raíz del laboratorio en Windows; en Kali está bajo `~/lab-plc/`. **Dumpcap** registra; **Wireshark** interpreta y muestra; **TShark** consulta el mismo tráfico desde la terminal.

Una **trama** es una unidad registrada en la interfaz de red. En esta sesión contiene un paquete IP con datos TCP. Wireshark presenta cada registro en una fila, con un número en la columna **No.**: «trama 65» significa la fila 65 de este archivo. Un filtro puede ocultar otras filas sin cambiar su número. Una captura nueva tendrá sus propios números.

## 7. Cómo localizar las tramas y entender «en claro»

En Wireshark:

1. File → Open → abrir el PCAP de referencia.
2. Aplicar `telnet` para mostrar ese protocolo. Arriba aparecen filas de tráfico; Source y Destination indican origen y destino.
3. Aplicar `frame.number == 65 || frame.number == 70` para localizar las dos filas citadas.
4. Seleccionar una y usar Follow → TCP Stream; mostrar como **ASCII**, una representación de caracteres de texto. Así se reconstruyen las preguntas del servidor y las respuestas del cliente. En esta corrida es el stream TCP 4.

| Trama | Dirección | Datos enviados | Interpretación por el contexto de la sesión |
|---|---|---|---|
| 65 | `.10:55468 → .20:23` | `msfadmin` y salto de línea | Respuesta a la petición de usuario |
| 70 | `.10:55468 → .20:23` | `msfadmin` y salto de línea | Respuesta a la petición de contraseña |
| 77 | `.10:55468 → .20:23` | `id` y salto de línea | Consulta de identidad |
| 84 | `.10:55468 → .20:23` | `uname -a` y salto de línea | Consulta del sistema |
| 100 | `.10:55468 → .20:23` | `exit` y salto de línea | Cierre de sesión |

**En claro significa sin cifrado:** esos datos se pueden interpretar como texto sin una clave de descifrado. Los bytes de las filas 65 y 70 son `6d736661646d696e0a` en hexadecimal: representan `msfadmin` y un salto de línea. Como usuario y contraseña son iguales, se distinguen por las preguntas previas y su posición en la conversación.

Que el terminal no muestre lo escrito después de `Password:` solo oculta el eco en pantalla; no protege la transmisión. Un observador necesitaría acceso a la captura o al trayecto de comunicación para leerla. El laboratorio demuestra que la contraseña está en los datos capturados; no demuestra la presencia de un tercero escuchando.

## 8. Cómo corroborarlo con comandos

Sin iniciar nuevas conexiones: en **PowerShell**, consultar el PCAP guardado con el TShark instalado en Windows:

```powershell
Set-Location 'C:\Users\Lorenzo\Documents\Laboratorio-Ciberseguridad-PLC'
$P = '.\evidencias\ejecuciones\20261112T163453Z-9047\02-trafico\comunicaciones.pcapng'
& 'C:\Program Files\Wireshark\tshark.exe' -r $P -Y 'frame.number == 65 or frame.number == 70 or frame.number == 77 or frame.number == 84 or frame.number == 100' -T fields -e frame.number -e ip.src -e ip.dst -e tcp.srcport -e tcp.dstport -e tcp.payload
& 'C:\Program Files\Wireshark\tshark.exe' -r $P -q -z follow,tcp,ascii,4
```

La primera orden muestra filas, extremos y bytes; la segunda reconstruye la conversación. Si se prefiere TShark de Kali, usar las mismas opciones cambiando la ruta al PCAP por la de `~/lab-plc/`.

Para **repetir** la prueba y crear tráfico nuevo, seguir [COMANDOS_RAPIDOS.md](COMANDOS_RAPIDOS.md), sección 3: inicia la captura antes de Telnet y conserva cada corrida por separado. Los números 65/70 solo corresponden a la evidencia original.

## 9. Resultado, impacto y recomendación

Se comprobó acceso como msfadmin con una credencial conocida: se relaciona con CWE-1392. Además, la contraseña viajó legible: se relaciona con CWE-319. Conocer la credencial permite asumir esa identidad; observar una comunicación sin cifrar puede exponerla. No se demostró root ni la explotación de una CVE específica.

Se recomienda sustituir credenciales predeterminadas, retirar Telnet y administrar mediante **SSH, Secure Shell**, con autenticación adecuada y comunicación cifrada. La validación posterior sería comprobar que TCP 23 ya no acepta conexiones y que la credencial anterior se rechaza. Las medidas están propuestas; no se aplicaron a la víctima didáctica.

Como complemento se comprobó **FTP, File Transfer Protocol**, un protocolo de transferencia de archivos: permitió autenticación `anonymous`, código `230`, y devolvió un listado vacío. No se acreditó lectura de archivos, carga ni una puerta trasera. Su documentación de referencia es [Nmap ftp-anon](https://nmap.org/nsedoc/scripts/ftp-anon.html). La demostración principal del entregable 6 es Telnet; FTP aporta otra condición para el análisis de riesgos.
