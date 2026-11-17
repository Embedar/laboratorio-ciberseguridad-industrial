#!/usr/bin/env bash
# Capturas reales de terminal y Wireshark, en una corrida nueva del laboratorio.
set -Eeuo pipefail
export R="$HOME/lab-plc/evidencias/sustentaciones/$(date -u +%Y%m%dT%H%M%SZ)-$$"
mkdir -p "$R"/{00-red,03-nmap,04-trafico,06-prueba,07-integridad,capturas,pasos,ui/qterminal.org}
printf '%s\n' "$R" > "$HOME/lab-plc/ULTIMA_SUSTENTACION.txt"
export QT_LOGGING_RULES='*.debug=false'
export XDG_CONFIG_HOME="$R/ui"
cat > "$R/ui/qterminal.org/qterminal.ini" <<'INI'
[General]
fontFamily=DejaVu Sans Mono
fontSize=16
TerminalTransparency=0
colorScheme=Linux
AskOnExit=false
HistoryLimited=false
MenuVisible=false
SavePosOnExit=false
SaveSizeOnExit=false
ChangeWindowTitle=true
INI
[[ $(sysctl -n net.ipv4.ip_forward) == 0 && $(sysctl -n net.ipv6.conf.all.forwarding) == 0 ]]
[[ -z $(ip -4 route show default) && -z $(ip -6 route show default) ]]
ip -4 route get 192.168.212.20 | grep -q 'dev eth0 src 192.168.212.10'
ip -4 route get 192.168.212.30 | grep -q 'dev eth0 src 192.168.212.10'
xfwm4 --compositor=off > "$R/ui/wm.log" 2>&1 & WM=$!
APP=''; CAP=''
cleanup(){ [[ -z $APP ]] || kill "$APP" 2>/dev/null || true; [[ -z $CAP ]] || kill -INT "$CAP" 2>/dev/null || true; kill "$WM" 2>/dev/null || true; }
trap cleanup EXIT
xsetroot -solid '#142437'
sleep 1
screen(){ xfce4-screenshooter -w -s "$R/capturas/$1.png"; }
step(){
 local id=$1 title=$2 cmd=$3
 printf '%s\n' "$cmd" > "$R/pasos/$id.comando.sh"
 cat > "$R/ui/step.sh" <<'STEP'
#!/usr/bin/env bash
set -Eeuo pipefail
printf '\033]0;SUSTENTACION\007'
sleep 2
clear
printf '%s\n\n' "$2"
printf 'COMANDO:\n'; cat "$R/pasos/$1.comando.sh"; printf '\nRESULTADO:\n'
set +e
bash -Eeuo pipefail "$R/pasos/$1.comando.sh" 2>&1 | tee "$R/pasos/$1.salida.txt"
code=${PIPESTATUS[0]}
printf '%s\n' "$code" > "$R/ui/$1.done"
printf '\nEstado del comando: %s\n' "$code"
sleep 300
STEP
 rm -f -- "$R/ui/$id.done"
 qterminal -e /bin/bash "$R/ui/step.sh" "$id" "$title" > "$R/ui/$id-terminal.log" 2>&1 & APP=$!
 local wid
 wid=$(timeout 20 xdotool search --sync --onlyvisible --name '^SUSTENTACION$' | head -1)
 xdotool windowmove "$wid" 10 10
 xdotool windowsize "$wid" 1380 940
 xdotool windowactivate "$wid"
 for i in $(seq 1 650); do [[ ! -f $R/ui/$id.done ]] || break; sleep 1; done
 [[ -f $R/ui/$id.done && $(cat "$R/ui/$id.done") == 0 ]] || { echo "Fallo paso $id"; cat "$R/pasos/$id.salida.txt"; exit 1; }
 sleep 1
 screen "$id"
 kill "$APP" 2>/dev/null || true; wait "$APP" 2>/dev/null || true; APP=''
 printf 'CAPTURA %s: %s\n' "$id" "$title"
}
step 01-estado 'RED: comprobar direccion, rutas y reenvio' 'ip -br address; ip route; sysctl net.ipv4.ip_forward net.ipv6.conf.all.forwarding'
step 02-descubrimiento 'RECONOCIMIENTO: descubrir los dos blancos' 'nmap -n -sn -PS22,502 192.168.212.20 192.168.212.30 -oA "$R/03-nmap/descubrimiento"'
step 03-nmap-victima 'NMAP: examinar todos los puertos TCP de la victima' 'nmap -n -sT -sV -sC --version-light --script-timeout 30s --host-timeout 600s -p- 192.168.212.20 -oA "$R/03-nmap/metasploitable" > "$R/03-nmap/salida-completa.txt"
awk '\''/^Nmap scan report/ || /^Host is up/ || /^PORT / || /^[0-9]+\/tcp/ || /^Nmap done/'\'' "$R/03-nmap/metasploitable.nmap"'
step 04-nmap-plc 'NMAP: comprobar SSH y Modbus TCP del PLC' 'nmap -n -sT -sV --version-light -p 22,502 192.168.212.30 -oA "$R/03-nmap/plc"'
step 05-inicio-captura 'TRAFICO: iniciar el registro antes de las consultas' 'nohup dumpcap -i eth0 -f '\''host 192.168.212.20 or host 192.168.212.30'\'' -a duration:90 -w "$R/04-trafico/comunicaciones.pcapng" > "$R/04-trafico/dumpcap.log" 2>&1 &
echo $! > "$R/04-trafico/captura.pid"
sleep 2
kill -0 "$(cat "$R/04-trafico/captura.pid")"
cat "$R/04-trafico/dumpcap.log"'
step 06-http 'HTTP: pedir la pagina de la victima' 'curl --noproxy '\''*'\'' --connect-timeout 5 --max-time 15 -f -sS --dump-header "$R/04-trafico/http-headers.txt" --output "$R/04-trafico/http-body.html" http://192.168.212.20/
cat "$R/04-trafico/http-headers.txt"'
step 07-modbus 'MODBUS: leer cuatro registros del PLC' 'for intento in 1 2 3; do python3 ~/lab-plc/scripts/kali/modbus_read.py --host 192.168.212.30 --port 502 --unit 1 --address 0 --count 4; done | tee "$R/04-trafico/modbus-lecturas.txt"'
sleep 90
step 08-tcp 'TCP: localizar SYN, SYN-ACK y ACK' 'tshark -r "$R/04-trafico/comunicaciones.pcapng" -Y '\''tcp.stream == 0'\'' -c 6 -T fields -E header=y -e frame.number -e ip.src -e ip.dst -e _ws.col.Info'
step 09-http-analisis 'HTTP: relacionar la peticion con su respuesta' 'tshark -r "$R/04-trafico/comunicaciones.pcapng" -Y http -T fields -E header=y -e frame.number -e ip.src -e ip.dst -e http.request.method -e http.request.uri -e http.response.code'
step 10-modbus-analisis 'MODBUS: localizar las consultas y respuestas' 'tshark -r "$R/04-trafico/comunicaciones.pcapng" -Y modbus -T fields -E header=y -e frame.number -e ip.src -e ip.dst -e modbus.func_code -e _ws.col.Info'
dumpcap -i eth0 -f 'host 192.168.212.20 and tcp port 23' -a duration:180 -w "$R/06-prueba/telnet.pcapng" > "$R/06-prueba/dumpcap.log" 2>&1 & CAP=$!
cat > "$R/ui/telnet.sh" <<'TELNET'
printf '\033]0;TELNET-PASO-A-PASO\007'
sleep 2
clear
printf 'PRUEBA CONTROLADA: terminal remota de la victima\n\n$ telnet 192.168.212.20 23\n'
TERM=xterm script -q -f -c 'telnet 192.168.212.20 23' "$R/06-prueba/telnet.txt"
printf '\nSesion terminada.\n'
sleep 300
TELNET
: > "$R/06-prueba/telnet.txt"
qterminal -e /bin/bash "$R/ui/telnet.sh" > "$R/ui/telnet-terminal.log" 2>&1 & APP=$!
wid=$(timeout 20 xdotool search --sync --onlyvisible --name '^TELNET-PASO-A-PASO$' | head -1)
xdotool windowmove "$wid" 10 10; xdotool windowsize "$wid" 1380 940; xdotool windowactivate "$wid"
wait_text(){
 local pattern=$1
 for attempt in $(seq 1 1200); do grep -q "$pattern" "$R/06-prueba/telnet.txt" 2>/dev/null && return; sleep 0.1; done
 echo "Telnet no mostro $pattern" >&2; return 1
}
wait_text 'metasploitable login:'; screen 11a-telnet-login
xdotool type --clearmodifiers --delay 0 'msfadmin'; xdotool key Return
wait_text 'Password:'; screen 11b-telnet-password
xdotool type --clearmodifiers --delay 0 'msfadmin'; xdotool key Return
sleep 2
xdotool type --clearmodifiers --delay 0 'clear; id'; xdotool key Return
wait_text 'uid=1000(msfadmin)'; sleep 1; screen 11c-telnet-identidad
xdotool type --clearmodifiers --delay 0 'uname -a'; xdotool key Return
sleep 1
xdotool type --clearmodifiers --delay 0 'exit'; xdotool key Return
wait_text 'Connection closed by foreign host'; sleep 1; screen 11d-telnet-cierre
kill "$APP" 2>/dev/null || true; wait "$APP" 2>/dev/null || true; APP=''
kill -INT "$CAP"; wait "$CAP"; CAP=''
step 12-telnet-trafico 'TELNET: reconstruir la informacion enviada por Kali' 'python3 ~/lab-plc/scripts/kali/Leer-Telnet-PCAP.py "$R/06-prueba/telnet.pcapng"'
step 13-hash-original 'INTEGRIDAD: conservar original y registrar SHA-256' 'cp "$R/04-trafico/comunicaciones.pcapng" "$R/07-integridad/original.evidencia"
chmod a-w "$R/07-integridad/original.evidencia"
sha256sum "$R/04-trafico/comunicaciones.pcapng" "$R/07-integridad/original.evidencia"'
step 14-copia-alterada 'INTEGRIDAD: modificar solo una segunda copia' 'cp "$R/07-integridad/original.evidencia" "$R/07-integridad/copia-alterada.evidencia"
chmod u+w "$R/07-integridad/copia-alterada.evidencia"
printf '\''\nALTERACION CONTROLADA DEL LABORATORIO\n'\'' >> "$R/07-integridad/copia-alterada.evidencia"
wc -c "$R/07-integridad/"*.evidencia
sha256sum "$R/07-integridad/"*.evidencia'
step 15-verificacion 'INTEGRIDAD: verificar el registro de cada archivo' 'cd "$R/07-integridad"
sha256sum original.evidencia copia-alterada.evidencia > SHA256SUMS.txt
sha256sum -c SHA256SUMS.txt
cmp -s original.evidencia copia-alterada.evidencia && exit 1
echo '\''Fuente conservada; copias diferentes; ambos hashes registrados.'\'''
shot_ws(){
 local pcap=$1 filter=$2 name=$3
 wireshark -r "$pcap" -Y "$filter" > "$R/ui/$name.log" 2>&1 & APP=$!
 local wid; wid=$(timeout 20 xdotool search --sync --onlyvisible --class wireshark | head -1)
 xdotool windowmove "$wid" 0 0; xdotool windowsize "$wid" 1400 1000; xdotool windowactivate "$wid"
 sleep 4; screen "$name"
 kill "$APP" 2>/dev/null || true; wait "$APP" 2>/dev/null || true; APP=''
}
shot_ws "$R/04-trafico/comunicaciones.pcapng" 'tcp.stream == 0' 16-wireshark-tcp
shot_ws "$R/04-trafico/comunicaciones.pcapng" http 17-wireshark-http
shot_ws "$R/04-trafico/comunicaciones.pcapng" modbus 18-wireshark-modbus
shot_ws "$R/06-prueba/telnet.pcapng" telnet 19-wireshark-telnet
printf 'Capturas reales de aplicaciones durante ejecucion nueva.\nUTC: %s\nCorrida: %s\n' "$(date -u --iso-8601=seconds)" "$R" > "$R/PROCEDENCIA.txt"
(cd "$R"; find . -type f -not -path "./ui/*" -not -name SHA256SUMS-TOTAL.txt -not -name captura.pid -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS-TOTAL.txt)
echo "CORRIDA TERMINADA: $R"
