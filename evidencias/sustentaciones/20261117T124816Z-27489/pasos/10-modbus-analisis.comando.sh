tshark -r "$R/04-trafico/comunicaciones.pcapng" -Y modbus -T fields -E header=y -e frame.number -e ip.src -e ip.dst -e modbus.func_code -e _ws.col.Info
