#!/usr/bin/env bash
# Ejecutar unicamente en Kali aislada: bash Ejecutar-practica.sh [INTERFAZ]
set -Eeuo pipefail
iface=${1:-eth0}
[[ $# -le 1 && $iface =~ ^[a-zA-Z0-9_.:-]+$ && $iface != lo ]] || { echo 'Uso: bash Ejecutar-practica.sh [INTERFAZ]' >&2; exit 2; }
root="$HOME/lab-plc"
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
run_dir="$root/evidencias/ejecuciones/$(date -u +%Y%m%dT%H%M%SZ)-$$"
mkdir -p -- "$run_dir"/{00-preflight,01-nmap,02-trafico,03-vulnerabilidad,04-integridad}
exec > >(tee -a "$run_dir/ejecucion.log") 2>&1
capture_pid=''
cleanup() {
  code=$?
  trap - EXIT
  if [[ -n $capture_pid ]] && kill -0 "$capture_pid" 2>/dev/null; then
    kill -INT "$capture_pid" 2>/dev/null || true
    wait "$capture_pid" 2>/dev/null || true
  fi
  if [[ $code -eq 0 ]]; then
    printf 'EJECUCION TERMINADA: revisar evidencias y capturas GUI; no equivale a informe aprobado.\n'
    echo 'Terminado sin errores de comandos' > "$run_dir/ESTADO.txt"
  else
    printf 'FALLO EXPLICITO (codigo %s). No afirmar pasos posteriores como ejecutados.\n' "$code"
    printf 'Fallo codigo %s. Consultar ejecucion.log y archivos parciales.\n' "$code" > "$run_dir/ESTADO.txt"
  fi
  printf 'Directorio de esta ejecucion: %s\n' "$run_dir"
  exit "$code"
}
trap cleanup EXIT
run() { { printf '\nUTC %s COMANDO:' "$(date -u --iso-8601=seconds)"; printf ' %q' "$@"; printf '\n'; } >&2; "$@"; }
fail() { printf 'PREFLIGHT BLOQUEADO: %s\n' "$*" >&2; exit 1; }
printf 'Inicio UTC: %s\nInterfaz: %s\nObjetivos fijos: 192.168.212.20 y 192.168.212.30\n' "$(date -u --iso-8601=seconds)" "$iface"
for tool in ip sysctl nmap dumpcap tshark curl python3 sha256sum timeout telnet; do
  command -v "$tool" >/dev/null || fail "Falta herramienta $tool; instalar en fase de aprovisionamiento"
done
python3 -c 'import pexpect' || fail 'Falta python3-pexpect'
[[ -f $script_dir/modbus_read.py && -f $script_dir/Prueba-Telnet.py && -f $script_dir/Integridad.sh ]] || fail 'Faltan scripts auxiliares'
[[ -d /sys/class/net/$iface ]] || fail 'Interfaz inexistente'
ip -brief address | tee "$run_dir/00-preflight/direcciones.txt"
ip -4 route show table all | tee "$run_dir/00-preflight/rutas-ipv4.txt"
ip -6 route show table all | tee "$run_dir/00-preflight/rutas-ipv6.txt"
if ip -4 route show table all | grep -Eq '^default |^unicast default '; then fail 'Existe ruta IPv4 por defecto'; fi
if ip -6 route show table all | grep -Eq '^default |^unicast default '; then fail 'Existe ruta IPv6 por defecto'; fi
[[ $(sysctl -n net.ipv4.ip_forward) == 0 ]] || fail 'Reenvio IPv4 habilitado'
[[ $(sysctl -n net.ipv6.conf.all.forwarding) == 0 ]] || fail 'Reenvio IPv6 habilitado'
# Considerar operstate UP; documentar bridges DOWN sin modificar Docker del usuario.
ip -j address show > "$run_dir/00-preflight/interfaces.json"
python3 - "$iface" "$run_dir/00-preflight/interfaces.json" <<'PY' || fail 'Interfaz activa adicional o IP de Kali incorrecta'
import json, sys
with open(sys.argv[2]) as source:
    interfaces = json.load(source)
active = []
for interface in interfaces:
    name = interface["ifname"]
    state = interface.get("operstate", "UNKNOWN")
    if name == "lo":
        continue
    addresses = [a for a in interface.get("addr_info", []) if a.get("family") == "inet" and a.get("scope") == "global"]
    if state == "UP":
        active.extend((name, a["local"], a["prefixlen"]) for a in addresses)
    elif addresses:
        print("Interfaz no operativa conservada, sin cambios: %s state=%s IPv4=%s" % (name, state, addresses))
        if state != "DOWN":
            raise SystemExit("BLOQUEADO: interfaz con IPv4 y estado ambiguo; revisar aislamiento")
expected = [(sys.argv[1], "192.168.212.10", 24)]
if active != expected:
    raise SystemExit("BLOQUEADO: IPv4 activas %r; esperado %r" % (active, expected))
print("Unica IPv4 global en interfaz operativamente UP: %r" % (active,))
PY
[[ -z $(ip -o -6 address show scope global) ]] || fail 'IPv6 global presente; revisar aislamiento'
for target in 192.168.212.20 192.168.212.30; do
  route=$(ip -4 route get "$target")
  [[ " $route " == *" dev $iface "* && " $route " == *' src 192.168.212.10 '* && " $route " != *' via '* ]] || fail "Ruta no directa al laboratorio: $target"
done
dumpcap -D > "$run_dir/00-preflight/interfaces-captura.txt" 2>&1 || fail 'Dumpcap no tiene permisos; no ejecutar auditoria'
grep -Fq "$iface" "$run_dir/00-preflight/interfaces-captura.txt" || fail 'Interfaz no visible para captura'
printf '%s\n' 'PREFLIGHT LOCAL OK. VMX host-only y ausencia de ICS/puente deben estar verificados previamente en Windows.'
printf '%s\n' 'PREFLIGHT LOCAL OK' > "$run_dir/00-preflight/resultado.txt"
run timeout 120 nmap -n -sn -PS22,502 192.168.212.20 192.168.212.30 -oA "$run_dir/01-nmap/descubrimiento"
run timeout 900 nmap -n -sT -sV -sC --version-light --script-timeout 30s --host-timeout 600s -p- 192.168.212.20 -oA "$run_dir/01-nmap/metasploitable"
run timeout 180 nmap -n -sT -sV -sC --version-light --script-timeout 30s -p 22,502 192.168.212.30 -oA "$run_dir/01-nmap/plc"
pcap="$run_dir/02-trafico/comunicaciones.pcapng"
printf '\nUTC %s COMANDO: dumpcap -i %q -f %q -a duration:90 -w %q\n' "$(date -u --iso-8601=seconds)" "$iface" 'host 192.168.212.20 or host 192.168.212.30' "$pcap"
dumpcap -i "$iface" -f 'host 192.168.212.20 or host 192.168.212.30' -a duration:90 -w "$pcap" > "$run_dir/02-trafico/dumpcap.log" 2>&1 &
capture_pid=$!
for attempt in {1..10}; do
  kill -0 "$capture_pid" 2>/dev/null || { cat "$run_dir/02-trafico/dumpcap.log"; fail 'Dumpcap termino antes de generar trafico'; }
  [[ -s $pcap ]] && break
  sleep 0.5
done
[[ -s $pcap ]] || fail 'No se creo la captura'
run curl --noproxy '*' --connect-timeout 5 --max-time 15 -f -v --dump-header "$run_dir/02-trafico/http-headers.txt" --output "$run_dir/02-trafico/http-body.html" http://192.168.212.20/ 2> "$run_dir/02-trafico/http-curl.log"
for attempt in 1 2 3; do
  run python3 "$script_dir/modbus_read.py" --host 192.168.212.30 --port 502 --unit 1 --address 0 --count 4 | tee -a "$run_dir/02-trafico/modbus-lecturas.txt"
  sleep 1
done
run python3 "$script_dir/Prueba-Telnet.py" --host 192.168.212.20 --timeout 15 | tee "$run_dir/03-vulnerabilidad/telnet.txt"
# FTP anonimo es una comprobacion adicional: si no esta permitido, conservar el fallo.
printf '\nUTC %s COMANDO: curl --noproxy * --max-time 15 --user anonymous:lab@example.invalid ftp://192.168.212.20/\n' "$(date -u --iso-8601=seconds)"
if curl --noproxy '*' --connect-timeout 5 --max-time 15 --user 'anonymous:lab@example.invalid' -v ftp://192.168.212.20/ > "$run_dir/03-vulnerabilidad/ftp-anonimo.txt" 2>&1; then
  echo 'FTP anonimo: comando completado; revisar si lista archivos o solo directorio vacio.'
else
  echo 'FTP anonimo: no confirmado; consultar evidencia del fallo.'
fi
wait "$capture_pid"
capture_pid=''
[[ -s $pcap ]] || { echo 'ERROR: captura vacia' >&2; exit 1; }
run tshark -r "$pcap" -q -z io,phs | tee "$run_dir/02-trafico/jerarquia-protocolos.txt"
run tshark -r "$pcap" -Y 'http or modbus or telnet' -T fields -E header=y -E separator=, -E quote=d -e frame.number -e frame.time_relative -e ip.src -e ip.dst -e tcp.srcport -e tcp.dstport -e _ws.col.Protocol -e http.request.method -e http.request.uri -e http.response.code -e modbus.func_code | tee "$run_dir/02-trafico/paquetes.csv"
run bash "$script_dir/Integridad.sh" "$pcap" | tee "$run_dir/04-integridad/resultado.txt"
(
  cd -- "$run_dir"
  find . -type f ! -name SHA256SUMS.txt ! -name ejecucion.log ! -name ESTADO.txt -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS.txt
  sha256sum -c SHA256SUMS.txt
)
printf 'Abrir PCAP en Wireshark y capturar filtros http, modbus, tcp.port == 502 y telnet.\n'
