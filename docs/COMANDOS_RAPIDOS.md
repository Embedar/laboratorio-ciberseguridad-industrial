# Comprobación rápida del laboratorio ya instalado

Para el entorno existente: Kali `192.168.212.10`, víctima `192.168.212.20` y PLC ModbusPal `192.168.212.30`. No reinstala ni cambia la configuración. Ejecutar los bloques en el orden indicado. Las comprobaciones de red se limitan a estos dos blancos del laboratorio.

## 1. Abrir la carpeta e iniciar las máquinas

En **PowerShell de Windows**:

```powershell
Set-Location 'C:\Users\Lorenzo\Documents\Laboratorio-Ciberseguridad-PLC'
.\scripts\windows\Laboratorio.ps1 -Accion Iniciar
# Esperar a que arranquen; consultar hasta que respondan los tres invitados.
.\scripts\windows\Laboratorio.ps1 -Accion Estado
.\scripts\windows\SSH-PLC.ps1 'systemctl is-active modbuspal-lab; ss -lnt sport = :502'
.\scripts\windows\SSH-Kali.ps1 'python3 ~/lab-plc/scripts/kali/modbus_read.py --host 192.168.212.30 --port 502 --unit 1 --address 0 --count 4'
```

Esperado: adaptadores host-only, direcciones `.10/.20/.30`, sin gateway en los invitados, forwarding `0`, servicio `active`, escucha `502` y registros `[250,1000,1,750]`. Si el estado falla, resolverlo antes de seguir. Estos valores prueban el servicio ModbusPal en funcionamiento; no son mediciones físicas.

## 2. Revisar los entregables conservados, sin repetir pruebas

En **PowerShell**, con las VMs incluso apagadas:

```powershell
$R = Join-Path $PWD 'evidencias\ejecuciones\20261112T163453Z-9047'
$I = Join-Path $PWD 'evidencias\04-integridad\20261112T163840Z-10974'

# Entregable 3: Nmap, equipos activos, puertos y servicios.
Get-Content "$R\01-nmap\descubrimiento.nmap"
Get-Content "$R\01-nmap\metasploitable.nmap"
Get-Content "$R\01-nmap\plc.nmap"

# Entregable 4: protocolos, origen/destino y lecturas Modbus.
Get-Content "$R\02-trafico\jerarquia-protocolos.txt"
Import-Csv "$R\02-trafico\paquetes.csv" | Format-Table -AutoSize
Get-Content "$R\02-trafico\modbus-lecturas.txt"

# Entregable 6: resultado de la prueba controlada y FTP complementario.
Get-Content "$R\03-vulnerabilidad\telnet.txt"
Get-Content "$R\03-vulnerabilidad\ftp-anonimo.txt"

# Entregable 7: hashes, registro de modificación y verificación.
Get-Content "$I\SHA256SUMS.txt"
Get-Content "$I\registro.txt"
Get-FileHash -Algorithm SHA256 "$R\02-trafico\comunicaciones.pcapng", "$I\original.evidencia", "$I\copia-alterada.evidencia"
python .\scripts\windows\Verificar-Evidencias.py
if ($LASTEXITCODE -ne 0) { throw 'Falló la verificación de evidencias' }
```

Esperado: dos blancos activos; víctima con 30 puertos TCP abiertos; PLC con 22/502 comprobados; 154 tramas; HTTP `200`; tres lecturas FC03; Telnet `uid=1000(msfadmin)` y FTP `230` con listado vacío. Fuente/original comparten SHA-256 `d33b57daa6af812c89638e4aaaac74c9a910f7a730d3ba5372326f81fa69d68c`; copia alterada `75729913650b748c5889879b7e357d9a1759fd8f60f0ad37383b8b63305e48ec`. El verificador debe informar `correctos: 35`, `total: 35` (28 hashes y siete imágenes).

Para inspeccionar el PCAP en Wireshark de Windows, si está instalado:

```powershell
& 'C:\Program Files\Wireshark\Wireshark.exe' "$R\02-trafico\comunicaciones.pcapng"
```

En esa captura: `tcp.stream == 0` muestra el inicio TCP, `http` las tramas 4/6, `modbus` las parejas 14/16, 25/27 y 35/37, y `telnet` la sesión controlada. Los números pertenecen solo a esta corrida. Si Wireshark no está instalado en Windows, usar el del escritorio de Kali y abrir la misma corrida bajo `~/lab-plc/evidencias/ejecuciones/`.

## 3. Repetir las comprobaciones prácticas con resultados nuevos

Los comandos de esta sección se ejecutan en **la misma terminal Bash de Kali**; conservarla abierta para mantener `R`, `P` e `I`. Se puede usar el escritorio de Kali o entrar desde PowerShell:

```powershell
.\scripts\windows\SSH-Kali.ps1
```

### Preparar la corrida y comprobar la red

En **Bash de Kali**:

```bash
set -euo pipefail
ip -br address
ip -4 route show table all
ip -6 route show table all
test "$(sysctl -n net.ipv4.ip_forward)" = 0
test "$(sysctl -n net.ipv6.conf.all.forwarding)" = 0
test -z "$(ip -4 route show default)"
test -z "$(ip -6 route show default)"
dumpcap -D
R="$HOME/lab-plc/evidencias/comprobaciones/$(date -u +%Y%m%dT%H%M%SZ)-$$"
mkdir -p "$R"/{01-nmap,02-trafico,03-vulnerabilidad,04-integridad}
printf 'Nueva comprobación: %s\n' "$R"
```

Continuar solo si la interfaz operativa es `eth0` con `.10/24`, sin interfaz externa activa, sin rutas por defecto y sin reenvío. Si cambia el nombre de la interfaz, ajustar el `-i eth0` de la captura. La comprobación de los tres adaptadores se hizo en Windows, sección 1.

### Entregable 3: reconocimiento Nmap

```bash
nmap -n -sn -PS22,502 192.168.212.20 192.168.212.30 -oA "$R/01-nmap/descubrimiento"
nmap -n -sT -sV -sC --version-light --script-timeout 30s --host-timeout 600s -p- 192.168.212.20 -oA "$R/01-nmap/metasploitable"
nmap -n -sT -sV -sC --version-light --script-timeout 30s -p 22,502 192.168.212.30 -oA "$R/01-nmap/plc"
```

Comprobar IP, estado `open`, servicio y versión. El sondeo completo de la víctima tarda unos minutos; los puertos dinámicos pueden variar. El PLC solo se examina en 22/502. Conservar XML/NMAP/GNMAP y una captura de la terminal.

### Entregables 4 y 6: capturar tráfico y probar los servicios

Se inicia la captura **antes** de generar HTTP, Modbus, Telnet y FTP. Todo queda en una carpeta nueva:

```bash
P="$R/02-trafico/comunicaciones.pcapng"
dumpcap -i eth0 -f 'host 192.168.212.20 or host 192.168.212.30' -a duration:90 -w "$P" > "$R/02-trafico/dumpcap.log" 2>&1 &
CAP=$!
trap 'kill -INT "$CAP" 2>/dev/null || true' EXIT
sleep 2
kill -0 "$CAP"
test -s "$P"
curl --noproxy '*' --connect-timeout 5 --max-time 10 -f -v --dump-header "$R/02-trafico/http-headers.txt" --output "$R/02-trafico/http-body.html" http://192.168.212.20/ 2> "$R/02-trafico/http-curl.log"
for intento in 1 2 3; do
  python3 ~/lab-plc/scripts/kali/modbus_read.py --host 192.168.212.30 --port 502 --unit 1 --address 0 --count 4 | tee -a "$R/02-trafico/modbus-lecturas.txt"
done
python3 ~/lab-plc/scripts/kali/Prueba-Telnet.py --host 192.168.212.20 --timeout 10 | tee "$R/03-vulnerabilidad/telnet.txt"
# FTP es complementario: registrar también un posible rechazo.
if curl --noproxy '*' --connect-timeout 5 --max-time 10 --user 'anonymous:lab@example.invalid' -v ftp://192.168.212.20/ > "$R/03-vulnerabilidad/ftp-anonimo.txt" 2>&1; then
  cat "$R/03-vulnerabilidad/ftp-anonimo.txt"
else
  cat "$R/03-vulnerabilidad/ftp-anonimo.txt"
  echo 'FTP anónimo no confirmado en esta corrida'
fi
wait "$CAP"
trap - EXIT
capinfos "$P"
tshark -r "$P" -q -z io,phs | tee "$R/02-trafico/protocolos.txt"
tshark -r "$P" -Y 'tcp.flags.syn == 1 or http or modbus or telnet' -T fields -E header=y -e frame.number -e ip.src -e ip.dst -e tcp.srcport -e tcp.dstport -e _ws.col.Info | tee "$R/02-trafico/analisis.tsv"
```

Esperado: HTTP `200`, FC03 unidad 1/dirección 0/cantidad 4 con `[250,1000,1,750]`; Telnet acepta la credencial pública de la víctima y muestra `uid=1000(msfadmin)`. Esto comprueba credenciales predeterminadas y exposición en claro, no explotación de una CVE ni acceso root. La duración acota la captura: si un protocolo no aparece porque terminó tarde, revisar los tiempos y repetir en otra carpeta; no atribuirle tráfico ausente.

En **el escritorio de Kali**, abrir el archivo de esa nueva corrida:

```bash
wireshark -r "$P"
```

Si se usó SSH sin escritorio, abrir Wireshark en Kali y buscar la ruta que imprimió `printf`; no requiere ejecutar la GUI desde SSH. Seleccionar el SYN de una conexión y seguir su stream para reconocer SYN/SYN-ACK/ACK; aplicar `http`, `modbus` / `tcp.port == 502` y `telnet`. Registrar IP/puertos, solicitud/respuesta y valores. Guardar las capturas de **esta corrida**; sus tramas y tamaño serán diferentes de los de referencia.

### Entregable 7: integridad de la nueva evidencia

```bash
bash ~/lab-plc/scripts/kali/Integridad.sh "$P" | tee "$R/04-integridad/resultado.txt"
I=$(sed -n 's/^Resultados: //p' "$R/04-integridad/resultado.txt")
test -d "$I"
(cd "$I" && sha256sum -c SHA256SUMS.txt)
sha256sum "$P" "$I/original.evidencia" "$I/copia-alterada.evidencia"
test "$(sha256sum "$P" | cut -d ' ' -f1)" = "$(sha256sum "$I/original.evidencia" | cut -d ' ' -f1)"
test "$(sha256sum "$I/original.evidencia" | cut -d ' ' -f1)" != "$(sha256sum "$I/copia-alterada.evidencia" | cut -d ' ' -f1)"
cat "$I/registro.txt"
printf 'Fuente = original; copia alterada distinta. Integridad comprobada.\n'
printf 'Tráfico: %s\nIntegridad: %s\n' "$R" "$I"
```

El original queda conservado; solo otra copia recibe el sufijo de prueba. Ambos `OK` del manifiesto verifican sus respectivos archivos, **no** igualdad entre ambos. Guardar captura de hashes y comparación.

## 4. Inspección en FTK y evidencias de riesgos

Para corroborar la referencia en **FTK Imager**: File → Add Evidence Item → Contents of a Folder → elegir la carpeta `02-trafico` de la sección 2; seleccionar `comunicaciones.pcapng` en Evidence Tree. Comprobar propiedades, tamaño `20.940 bytes` y hexadecimal. Recalcular SHA-256 con el bloque PowerShell anterior; el cálculo corresponde a Get-FileHash. Para datos nuevos, exportar las rutas impresas siguiendo el [README, sección 10](../README.md#10-exportar-verificar-e-inspeccionar-en-ftk).

El entregable 5 se respalda en lo observado: Telnet con credencial predeterminada/en claro, HTTP sin cifrar y lectura Modbus sin autenticación; FTP anónimo y SMB complementan el análisis. Las recomendaciones, conclusiones, diagrama y tablas se revisan en el informe, sin un comando adicional. No modificar servicios antes de demostrar las condiciones del laboratorio.

## Alternativa: repetir la práctica completa en una sola orden

Desde **PowerShell**, después de comprobar el montaje:

```powershell
.\scripts\windows\SSH-Kali.ps1 'bash ~/lab-plc/scripts/kali/Ejecutar-practica.sh eth0'
```

Incluye comprobación previa estricta, las cuatro actividades y manifiesto; imprime las rutas nuevas y detiene la secuencia ante errores. Es una alternativa a la sección 3, no es necesario ejecutar ambas. Consultar resultados propios y tomar las capturas correspondientes.

