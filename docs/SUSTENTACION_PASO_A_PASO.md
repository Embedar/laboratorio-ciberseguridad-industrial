# Sustentación del laboratorio: secuencia de demostración

Usa el entorno ya instalado. Presenta el informe en el orden siguiente y conserva una terminal de Kali abierta para mantener las variables de la demostración. Ejecuta una orden, espera su resultado, explica lo observado y toma la captura antes de continuar. Si una orden falla, conserva su salida y corrige la causa; un fallo no confirma el resultado esperado.

Las únicas máquinas examinadas son Metasploitable `192.168.212.20` y el PLC simulado `192.168.212.30`. Kali es `192.168.212.10`. Los números de trama, tamaños y hashes serán los de esta corrida; no deben sustituirse por los de una práctica anterior.

## Preparación antes de exponer

En **PowerShell de Windows**:

```powershell
Set-Location 'C:\Users\Lorenzo\Documents\Laboratorio-Ciberseguridad-PLC'
```

```powershell
.\scripts\windows\Laboratorio.ps1 -Accion Iniciar
```

Esperar a que arranquen y comprobar:

```powershell
.\scripts\windows\Laboratorio.ps1 -Accion Estado
```

Observar las tres direcciones, adaptadores host-only, rutas locales sin gateway, forwarding `0` y ModbusPal `active`. No continuar si hay una interfaz externa activa o una ruta de salida ajena al laboratorio.

Abrir una terminal **Bash de Kali** en su escritorio. También se puede acceder por SSH desde PowerShell:

```powershell
.\scripts\windows\SSH-Kali.ps1
```

En esa terminal **Bash**:

```bash
set -o pipefail
R="$HOME/lab-plc/evidencias/sustentaciones/$(date -u +%Y%m%dT%H%M%SZ)-$$"
mkdir -p "$R"/{03-nmap,04-trafico,06-prueba,07-integridad}
printf 'Carpeta de esta demostración: %s\n' "$R"
```

Guardar la ruta impresa. Si se usa una corrida ya capturada, asignar `R` a su ruta existente y no ejecutar el bloque de creación anterior. La distribución sigue el orden del informe:

| Carpeta | Contenido |
|---|---|
| `03-nmap/` | Descubrimiento y sondeos de puertos/servicios |
| `04-trafico/` | Captura HTTP/Modbus y su análisis |
| `06-prueba/` | Sesión controlada Telnet, captura de red y comprobaciones |
| `07-integridad/` | Original, copia alterada, SHA-256 y verificación |

## 1. Diagrama de la infraestructura virtual implementada

Mostrar el diagrama del informe. Señalar Windows, la red aislada, Kali, la víctima y el PLC. Explicar que ModbusPal simula registros industriales y que el anfitrión también pertenece a la red host-only.

No hay una orden que produzca por sí sola el diagrama. Para contrastar la dirección de Kali en la terminal:

```bash
ip -br address
```

**Observar:** `eth0` con `192.168.212.10/24`. Un bridge Docker inactivo no se utiliza en la práctica.

```bash
ip route
```

**Observar:** ruta directa al laboratorio y ausencia de `default`.

```bash
sysctl net.ipv4.ip_forward net.ipv6.conf.all.forwarding
```

Si alguno de los valores es `1`, corregirlo antes de iniciar sondeos o capturas:

```bash
sudo sysctl -w net.ipv4.ip_forward=0 net.ipv6.conf.all.forwarding=0
```

```bash
sysctl net.ipv4.ip_forward net.ipv6.conf.all.forwarding
```

Comprobar que ambos quedaron en `0`. Esto no requiere detener Docker ni cambiar su configuración. Revisar también IPv6:

```bash
ip -6 route show default
```

**Explicar:** «La comunicación se mantiene dentro de la red del laboratorio y Kali no reenvía tráfico entre redes». No afirmar aislamiento confirmado si aparece una ruta por defecto, un adaptador externo activo o reenvío `1`.

## 2. Tabla de dispositivos, direcciones IP, puertos y servicios identificados

Mostrar la tabla del informe. Identificar cada equipo por su IP y señalar que los resultados del reconocimiento se obtienen en el siguiente apartado. El anfitrión y Kali no fueron blancos del inventario de puertos.

Explicar un ejemplo: `23/tcp open telnet` significa que la víctima acepta conexiones TCP al servicio de terminal remota en el puerto 23. `open` no significa, por sí solo, que una vulnerabilidad esté demostrada.

## 3. Evidencias del reconocimiento realizado con Nmap

### 3.1 Descubrir los blancos

En **Bash de Kali**:

```bash
nmap -n -sn -PS22,502 192.168.212.20 192.168.212.30 -oA "$R/03-nmap/descubrimiento"
```

**Observar:** ambos equipos activos. **Explicar:** «Esta orden reconoce los dos destinos autorizados; todavía no realiza el inventario completo de sus servicios». Guardar una captura con la orden y las IP visibles.

### 3.2 Explorar los servicios de la víctima

```bash
nmap -n -sT -sV -sC --version-light --script-timeout 30s --host-timeout 600s -p- 192.168.212.20 -oA "$R/03-nmap/metasploitable"
```

**Observar:** columnas PORT, STATE, SERVICE y VERSION. La orden puede tardar varios minutos. `-sT` utiliza conexiones TCP, `-sV` identifica servicios, `-sC` ejecuta scripts predeterminados y `-p-` recorre los 65.535 puertos TCP. Los ficheros NMAP/XML/GNMAP conservan el resultado.

Si la salida excede la pantalla, mostrar las filas de puertos para una captura legible:

```bash
awk '/^Nmap scan report/ || /^PORT / || /^[0-9]+\/tcp/ || /^Nmap done/' "$R/03-nmap/metasploitable.nmap"
```

**Explicar:** «Aquí relaciono cada puerto abierto con el servicio detectado. Las etiquetas inciertas se conservan y los puertos dinámicos pueden variar entre corridas».

### 3.3 Comprobar los puertos previstos del PLC

```bash
nmap -n -sT -sV -sC --version-light --script-timeout 30s -p 22,502 192.168.212.30 -oA "$R/03-nmap/plc"
```

**Observar:** 22/SSH y 502 abierto. **Explicar:** «En el PLC solo examiné estos dos puertos. La identificación industrial se complementa con una lectura Modbus válida».

## 4. Capturas y análisis del tráfico en Wireshark

PCAP es el nombre habitual de un archivo de tráfico; aquí se utiliza el formato PCAPNG. Cada fila numerada de Wireshark es un registro de ese archivo. Dumpcap registra, Wireshark permite inspeccionar y TShark consulta desde la terminal.

### 4.1 Iniciar una captura nueva

```bash
P="$R/04-trafico/comunicaciones.pcapng"
dumpcap -i eth0 -f 'host 192.168.212.20 or host 192.168.212.30' -w "$P" > "$R/04-trafico/dumpcap.log" 2>&1 &
CAP=$!
trap 'kill -INT "$CAP" 2>/dev/null || true' EXIT
```

Esperar dos segundos y comprobar que sigue activa:

```bash
sleep 2
kill -0 "$CAP"
test -s "$P" && printf 'Captura activa: %s\n' "$P"
```

**Explicar:** «La captura comienza antes de generar las comunicaciones; así conserva también el establecimiento TCP». La captura sigue activa hasta el paso 4.4.

### 4.2 Solicitar una página HTTP

```bash
curl --noproxy '*' --connect-timeout 5 --max-time 15 -f -v --dump-header "$R/04-trafico/http-headers.txt" --output "$R/04-trafico/http-body.html" http://192.168.212.20/ 2> "$R/04-trafico/http-curl.log"
```

```bash
cat "$R/04-trafico/http-headers.txt"
```

**Observar:** respuesta `200 OK`. **Explicar:** «Kali solicitó la página principal y la víctima la entregó por HTTP». Guardar captura de la orden y de los encabezados.

### 4.3 Leer registros del PLC con Modbus

```bash
python3 ~/lab-plc/scripts/kali/modbus_read.py --host 192.168.212.30 --port 502 --unit 1 --address 0 --count 4 | tee "$R/04-trafico/modbus-lecturas.txt"
```

**Observar:** `[250,1000,1,750]`. **Explicar:** «La función 03 lee cuatro registros, desde la dirección de protocolo 0 de la unidad 1. Son enteros simulados, sin unidades físicas asignadas. No estoy escribiendo registros». Guardar la captura del comando y su respuesta.

### 4.4 Cerrar y comprobar el archivo

```bash
kill -INT "$CAP"
wait "$CAP"
trap - EXIT
```

```bash
capinfos "$P" | tee "$R/04-trafico/archivo.txt"
```

**Observar:** archivo existente, tamaño y cantidad de paquetes propios de esta corrida. No deben coincidir necesariamente con otra demostración.

### 4.5 Mostrar TCP y HTTP en la terminal

```bash
HTTP_STREAM=$(tshark -r "$P" -Y 'http.request' -T fields -e tcp.stream | sed -n '1p')
test -n "$HTTP_STREAM"
tshark -r "$P" -Y "tcp.stream == $HTTP_STREAM" -T fields -E header=y -e frame.number -e ip.src -e ip.dst -e tcp.srcport -e tcp.dstport -e _ws.col.Info | tee "$R/04-trafico/tcp-http.tsv"
```

**Observar:** SYN, SYN-ACK y ACK, seguidos de GET y respuesta 200. **Explicar:** «TCP establece la conexión; después HTTP transporta la petición y respuesta. El filtro utiliza el stream encontrado en este archivo, sin fijar números de otra corrida».

### 4.6 Mostrar Modbus en la terminal y en Wireshark

```bash
tshark -r "$P" -Y 'modbus' -T fields -E header=y -e frame.number -e ip.src -e ip.dst -e tcp.srcport -e tcp.dstport -e modbus.func_code -e _ws.col.Info | tee "$R/04-trafico/modbus.tsv"
```

**Observar:** consulta `.10→.30:502`, respuesta en sentido inverso y función 03. Guardar la captura de ambas filas.

En **el escritorio de Kali**, desde esa misma terminal:

```bash
wireshark -r "$P" &
```

Aplicar `http` y seleccionar petición/respuesta; después aplicar `modbus` y seleccionar la respuesta para desplegar los registros. Tomar una captura por vista. Si se trabaja por SSH sin escritorio, abrir Wireshark en Kali y seleccionar la ruta de `$P` impresa con `printf '%s\n' "$P"`.

## 5. Identificación de al menos tres riesgos de seguridad

Mostrar la tabla de riesgos y señalar la evidencia correspondiente:

| Condición observada | Qué mostrar | Qué explicar |
|---|---|---|
| HTTP sin cifrado | GET, respuesta y contenido en Wireshark | Un observador con acceso al trayecto puede leer datos enviados del mismo modo |
| Lectura Modbus sin autenticación | Respuesta de registros y tráfico 502 | Un cliente con alcance a esta red pudo leer la simulación sin aportar credenciales |
| Telnet y credencial predeterminada | La sesión y captura del apartado siguiente | La credencial conocida permitió asumir la identidad msfadmin; el canal también expuso su contraseña |

No es necesario ejecutar un ataque diferente por cada fila. Las consecuencias potenciales deben distinguirse de los hechos que sí se observaron.

## 6. Evidencia de una prueba controlada de vulnerabilidad

La [explicación de Telnet, Rapid7, MITRE, CWE y CVE](ACTIVIDAD_3_EXPLICADA.md) permite preparar la explicación oral. Rapid7 y MITRE son fuentes consultadas; la conexión se realiza con el cliente Telnet y el script local. CWE-1392 describe credenciales predeterminadas y CWE-319 transmisión sensible sin cifrado. No se atribuye una CVE explotada a esta prueba.

### 6.1 Capturar la sesión de la prueba

En **Bash de Kali**:

```bash
PT="$R/06-prueba/telnet.pcapng"
dumpcap -i eth0 -f 'host 192.168.212.20 and tcp port 23' -w "$PT" > "$R/06-prueba/dumpcap.log" 2>&1 &
CAP=$!
trap 'kill -INT "$CAP" 2>/dev/null || true' EXIT
sleep 2
kill -0 "$CAP"
test -s "$PT"
```

### 6.2 Ejecutar el acceso controlado

Para mostrar la interacción manual en el escritorio, ejecutar `TERM=xterm telnet 192.168.212.20 23`. Esperar a ver `login:` antes de escribir `msfadmin`; esperar `Password:` antes de introducir la misma contraseña pública. Ya dentro, ejecutar una orden por vez: `id`, `uname -a` y `exit`. Tomar una captura en cada estado. Si el banner tarda, esperar su aparición; no escribir las respuestas anticipadamente.

Para una repetición automatizada de la misma comprobación:


```bash
python3 ~/lab-plc/scripts/kali/Prueba-Telnet.py --host 192.168.212.20 --timeout 60 | tee "$R/06-prueba/telnet.txt"
```

**Observar:** acceso aceptado con la credencial pública del laboratorio, `uid=1000(msfadmin)`, respuesta de `uname -a` y cierre. **Explicar:** «El script inicia sesión una vez, consulta identidad/sistema y sale. El resultado acredita msfadmin, no root; no modifica archivos mediante sus comandos». Guardar captura de la consulta y respuestas.

### 6.3 Cerrar la captura y encontrar su conversación

```bash
kill -INT "$CAP"
wait "$CAP"
trap - EXIT
TELNET_STREAM=$(tshark -r "$PT" -Y 'telnet' -T fields -e tcp.stream | sed -n '1p')
test -n "$TELNET_STREAM"
```

```bash
tshark -r "$PT" -Y 'telnet and tcp.len > 0' -T fields -E header=y -e frame.number -e ip.src -e ip.dst -e tcp.srcport -e tcp.dstport -e tcp.payload | tee "$R/06-prueba/datos-telnet.tsv"
```

```bash
tshark -r "$PT" -q -z "follow,tcp,ascii,$TELNET_STREAM" | tee "$R/06-prueba/conversacion.txt"
```

**Observar:** las preguntas `login:`/`Password:` y las respuestas `msfadmin`, junto con `id`, `uname -a` y `exit`. Si la conversación excede la pantalla, abrir el archivo con `less "$R/06-prueba/conversacion.txt"` y salir con `q`.

**Explicar:** «La terminal y el archivo de red son evidencias distintas. La terminal confirma el acceso; el PCAP permite ver lo transmitido. La contraseña es legible sin una clave de descifrado, aunque su eco no aparezca en la terminal».

En **el escritorio de Kali**:

```bash
wireshark -r "$PT" &
```

Aplicar `telnet`, seleccionar una fila y usar Follow → TCP Stream, vista ASCII. Localizar las preguntas del servidor y las respuestas del cliente. Tomar una captura de la conversación legible. En esta corrida no se buscan obligatoriamente las tramas 65 y 70 de la práctica anterior.

## 7. Cálculo y verificación de hashes SHA-256

### 7.1 Seleccionar el archivo y registrar su hash

En **Bash de Kali**, se conserva como fuente el archivo HTTP/Modbus ya cerrado:

```bash
sha256sum "$P" | tee "$R/07-integridad/hash-fuente.txt"
```

**Observar:** 64 caracteres hexadecimales y el nombre del PCAP. **Explicar:** «SHA-256 resume los bytes del archivo; sirve como referencia para comprobar si cambian».

### 7.2 Conservar el original y alterar solamente una copia

```bash
bash ~/lab-plc/scripts/kali/Integridad.sh "$P" | tee "$R/07-integridad/resultado.txt"
```

La salida indica dónde quedaron el original, la segunda copia con el sufijo de prueba y el manifiesto. Guardar captura de hashes y comparaciones.

### 7.3 Verificar y reunir las copias en la carpeta de demostración

```bash
I=$(sed -n 's/^Resultados: //p' "$R/07-integridad/resultado.txt")
test -d "$I"
(cd "$I" && sha256sum -c SHA256SUMS.txt)
```

```bash
sha256sum "$P" "$I/original.evidencia" "$I/copia-alterada.evidencia"
```

**Observar:** fuente y original con el mismo resumen; copia alterada con otro. Los dos `OK` del manifiesto validan las entradas respectivas: no significan que las dos copias sean iguales.

```bash
cp -a "$I/." "$R/07-integridad/"
```

Se copian resultados ya generados, sin volver a alterar sus bytes. La carpeta queda reunida para conservar y exportar la demostración.

### 7.4 Revisar el archivo con FTK Imager

Exportar la corrida a Windows siguiendo el [README, sección 10](../README.md#10-exportar-verificar-e-inspeccionar-en-ftk), ajustando el origen a `~/lab-plc/evidencias/sustentaciones/` y su identificador real.

En FTK Imager: File → Add Evidence Item → Contents of a Folder → carpeta `04-trafico` exportada. Seleccionar `comunicaciones.pcapng`, mostrar propiedades, tamaño y hexadecimal; guardar una captura. El análisis de protocolos se muestra en Wireshark. El cálculo Windows, si se necesita contrastar la transferencia, corresponde a `Get-FileHash -Algorithm SHA256` sobre la ruta exportada.

### 7.5 Sellar los resultados de la corrida

En **Bash de Kali**, después de cerrar las capturas y guardar sus archivos:

```bash
(cd "$R" && find . -type f ! -name SHA256SUMS.txt -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS.txt)
(cd "$R" && sha256sum -c SHA256SUMS.txt)
```

El manifiesto registra los archivos presentes en ese momento; si se añaden imágenes después, incluirlas en una nueva verificación. Mostrar el resultado de la comprobación y conservar su salida.

### Capturas de la demostración conservada

Las imágenes nuevas se reúnen en `capturas/` junto a la corrida. Usar esta secuencia para recorrerlas en el informe:

| Archivo | Paso que debe verse |
|---|---|
| `01-estado` | IP, rutas y reenvío desactivado |
| `02-descubrimiento` | Reconocimiento de los dos blancos |
| `03-nmap-victima` / `04-nmap-plc` | Puertos y servicios de cada equipo |
| `05-inicio-captura` | Inicio de registro antes de generar tráfico |
| `06-http` / `07-modbus` | Solicitud HTTP y lectura de registros |
| `08-tcp` / `09-http-analisis` / `10-modbus-analisis` | Análisis de la captura cerrada |
| `11-telnet` / `12-telnet-trafico` | Sesión de terminal y evidencia de red, por separado |
| `13-hash-original` / `14-copia-alterada` / `15-verificacion` | Hash de referencia, modificación de copia y comparación |

Las extensiones y vistas adicionales se consultan en el índice de la corrida. Cada captura debe mostrar su comando y el resultado correspondiente con un tamaño de letra legible; una imagen de una corrida anterior no se presenta como ejecución nueva.

## 8. Recomendaciones para mejorar la seguridad de la infraestructura industrial

Mostrar las medidas junto a sus evidencias: sustituir credenciales predeterminadas, retirar Telnet, administrar por SSH, proteger HTTP con HTTPS, restringir clientes Modbus y retirar servicios innecesarios.

Explicar cómo se comprobaría cada cambio: rechazo de la credencial anterior, puerto Telnet cerrado, canal HTTPS validado o acceso Modbus bloqueado desde un cliente no autorizado. No aplicar esas modificaciones durante la demostración del entorno vulnerable: modificarían las condiciones que se están mostrando.

## 9. Conclusiones del trabajo

Cerrar con los resultados observados en la corrida: equipos/servicios reconocidos, solicitud/respuesta HTTP, lectura Modbus, identidad obtenida por Telnet, contraseña visible en la captura y detección de la copia alterada mediante SHA-256.

Mostrar al final la ruta conservada:

```bash
printf 'Evidencia de esta sustentación: %s\n' "$R"
```

Los comandos, archivos originales y capturas deben corresponder a esa misma demostración. El diagrama, las tablas, las recomendaciones y las conclusiones se presentan desde el informe.

## Evidencias de la demostración registrada

La corrida `20261117T124816Z-27489` conserva22 capturas nuevas en `evidencias/sustentaciones/20261117T124816Z-27489/capturas/`. Las cuatro imágenes `11a` a `11d` muestran login, petición de contraseña, identidad y cierre. `12-telnet-trafico.png` reconstruye el texto del cliente a partir del PCAP; puede repetirse con `python3 ~/lab-plc/scripts/kali/Leer-Telnet-PCAP.py "$PT"`. Las imágenes 16–19 muestran Wireshark. Para comprobar la copia exportada: `python scripts/windows/Verificar-Sustentacion.py` desde Windows.
