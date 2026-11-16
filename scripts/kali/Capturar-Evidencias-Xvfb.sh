#!/usr/bin/env bash
# Uso: xvfb-run -a -s '-screen 0 1280x800x24' bash Capturar-Evidencias-Xvfb.sh RUN_DIR [OUTPUT_DIR]
# Usa logs/PCAP reales de la corrida indicada; no depende de mostrar-*.sh externos.
set -Eeuo pipefail
[[ $# -ge 1 && $# -le 2 ]] || { echo 'Uso: Capturar-Evidencias-Xvfb.sh RUN_DIR [OUTPUT_DIR]' >&2; exit 2; }
run=$(realpath -- "$1")
out=${2:-"$HOME/lab-plc/evidencias/capturas/$(basename -- "$run")"}
mkdir -p -- "$out"
out=$(realpath -- "$out")
pcap="$run/02-trafico/comunicaciones.pcapng"
for required in "$pcap" "$run/01-nmap/metasploitable.nmap" "$run/03-vulnerabilidad/telnet.txt" "$run/04-integridad/resultado.txt"; do
  [[ -s $required ]] || { echo "Falta evidencia real: $required" >&2; exit 1; }
done
for tool in xfwm4 qterminal xdotool xsetroot xfce4-screenshooter wireshark tshark; do command -v "$tool" >/dev/null || { echo "Falta $tool; bootstrap --capturas" >&2; exit 1; }; done
[[ -n ${DISPLAY:-} ]] || { echo 'No hay DISPLAY: usar xvfb-run o sesion grafica propia' >&2; exit 1; }
wm=''; app=''
views=$(mktemp -d)
cleanup() {
  if [[ -n $app ]]; then kill "$app" 2>/dev/null || true; wait "$app" 2>/dev/null || true; fi
  if [[ -n $wm ]]; then kill "$wm" 2>/dev/null || true; wait "$wm" 2>/dev/null || true; fi
  rm -f -- "$views/view.sh"
  rmdir -- "$views" 2>/dev/null || true
}
trap cleanup EXIT
cat > "$views/view.sh" <<'VIEW'
#!/usr/bin/env bash
set -eu
printf '\033]0;%s\007' "$2"
sleep 2
printf '\033cEVIDENCIA ORIGINAL: %s\n\n' "$1"
case "$2" in
  'LAB - Nmap real') awk '/^Nmap scan report/ || /^Host is up/ || /^PORT / || /^[0-9]+\/tcp/ || /^Nmap done/' "$1" ;;
  'LAB - Prueba controlada') head -4 "$1"; grep -F 'metasploitable login:' "$1" || true; sed -n '/^msfadmin@metasploitable:~[$] id/,$p' "$1" ;;
  *) cat -- "$1" ;;
esac
printf '\nVista de evidencia guardada, sin volver a ejecutar la prueba.\n'
sleep 60
VIEW
xfwm4 --compositor=off > "$out/xvfb-wm.log" 2>&1 &
wm=$!
sleep 1
xsetroot -solid '#17273e'
shot_terminal() {
  local input=$1 title=$2 filename=$3
  qterminal -e /bin/bash "$views/view.sh" "$input" "$title" > "$out/$filename.log" 2>&1 &
  app=$!
  local wid
  wid=$(timeout 20 xdotool search --sync --onlyvisible --name "^$title$" | head -1)
  xdotool windowmove "$wid" 10 30
  xdotool windowsize "$wid" 1250 740
  xdotool windowactivate "$wid"
  sleep 3
  xfce4-screenshooter -f -s "$out/$filename.png"
  kill "$app" 2>/dev/null || true
  wait "$app" 2>/dev/null || true
  app=''
}
shot_terminal "$run/01-nmap/metasploitable.nmap" 'LAB - Nmap real' 01-nmap
shot_terminal "$run/03-vulnerabilidad/telnet.txt" 'LAB - Prueba controlada' 04-telnet
shot_terminal "$run/04-integridad/resultado.txt" 'LAB - Integridad SHA256' 05-integridad
shot_wireshark() {
  local filter=$1 filename=$2 frame
  frame=$(tshark -r "$pcap" -Y "$filter" -T fields -e frame.number 2> "$out/$filename-tshark.log" | sed -n '1p')
  [[ $frame =~ ^[0-9]+$ ]] || { echo "No hay paquete real para filtro $filter" >&2; exit 1; }
  wireshark -r "$pcap" -Y "$filter" -g "$frame" > "$out/$filename.log" 2>&1 &
  app=$!
  local wid
  wid=$(timeout 20 xdotool search --sync --onlyvisible --class wireshark | head -1)
  xdotool windowmove "$wid" 0 0
  xdotool windowsize "$wid" 1280 800
  xdotool windowactivate "$wid"
  sleep 3
  xfce4-screenshooter -f -s "$out/$filename.png"
  kill "$app" 2>/dev/null || true
  wait "$app" 2>/dev/null || true
  app=''
  printf '%s filtro=%s trama=%s\n' "$filename" "$filter" "$frame" >> "$out/tramas.txt"
}
shot_wireshark http 02-http
shot_wireshark modbus 03-modbus
printf 'Capturas de aplicaciones reales. UTC %s\nCorrida fuente: %s\n' "$(date -u --iso-8601=seconds)" "$run" > "$out/SESION_GRAFICA.txt"
echo 'Revisar visualmente las cinco imagenes: el script no garantiza encuadre ni legibilidad.'
