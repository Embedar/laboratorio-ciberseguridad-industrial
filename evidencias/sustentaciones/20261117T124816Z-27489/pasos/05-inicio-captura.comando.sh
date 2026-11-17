nohup dumpcap -i eth0 -f 'host 192.168.212.20 or host 192.168.212.30' -a duration:90 -w "$R/04-trafico/comunicaciones.pcapng" > "$R/04-trafico/dumpcap.log" 2>&1 &
echo $! > "$R/04-trafico/captura.pid"
sleep 2
kill -0 "$(cat "$R/04-trafico/captura.pid")"
cat "$R/04-trafico/dumpcap.log"
