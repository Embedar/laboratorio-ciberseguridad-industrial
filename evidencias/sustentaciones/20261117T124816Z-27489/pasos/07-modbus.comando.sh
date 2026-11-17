for intento in 1 2 3; do python3 ~/lab-plc/scripts/kali/modbus_read.py --host 192.168.212.30 --port 502 --unit 1 --address 0 --count 4; done | tee "$R/04-trafico/modbus-lecturas.txt"
