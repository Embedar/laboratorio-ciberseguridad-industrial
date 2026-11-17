tshark -r "$R/04-trafico/comunicaciones.pcapng" -Y 'tcp.stream == 0' -c 6 -T fields -E header=y -e frame.number -e ip.src -e ip.dst -e _ws.col.Info
