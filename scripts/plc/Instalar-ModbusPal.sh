#!/usr/bin/env bash
# Ejecutar dentro de PLC aislado, despues de instalar default-jre-headless.
# Uso: bash Instalar-ModbusPal.sh /ruta/ModbusPal.jar /ruta/scripts/plc
set -euo pipefail
if [[ $# != 2 || ! -f $1 || ! -f $2/ModbusPalHeadless.class ]]; then
  echo 'Uso: bash Instalar-ModbusPal.sh /ruta/ModbusPal.jar /ruta/scripts/plc' >&2
  exit 2
fi
[[ $(id -u lab) -gt 0 ]]
command -v java >/dev/null
command -v python3 >/dev/null
if ip route show default | grep -q . || ip -6 route show default | grep -q .; then
  echo 'BLOQUEADO: el PLC tiene ruta por defecto; aislar antes de iniciar ModbusPal' >&2
  exit 1
fi
ip -4 -brief address | grep -Fq '192.168.212.30/24' || { echo 'No esta configurada IP PLC .30/24' >&2; exit 1; }
expected=cbc6423b8a39ada050c790b86d0eecd08b88c2d37a73382cd20a68b382101aec
actual=$(sha256sum -- "$1" | cut -d ' ' -f1)
[[ $actual == "$expected" ]] || { echo 'JAR distinto de la version validada' >&2; exit 1; }
sudo install -d -m 755 /opt/lab-plc
sudo install -m 644 -- "$1" /opt/lab-plc/ModbusPal.jar
sudo install -m 644 -- "$2"/ModbusPalHeadless*.class /opt/lab-plc/
sudo install -m 644 -- "$2/modbuspal-lab.service" /etc/systemd/system/modbuspal-lab.service
sudo systemctl daemon-reload
sudo systemctl enable modbuspal-lab
sudo systemctl restart modbuspal-lab
sudo systemctl --no-pager status modbuspal-lab
# Verificar respuesta FC03 real; ss vacio no constituye readiness.
python3 - <<'PY'
import socket,struct,time

def receive(sock,length):
    result=b''
    while len(result)<length:
        data=sock.recv(length-len(result))
        if not data: raise ValueError('EOF Modbus')
        result+=data
    return result
last=None
for attempt in range(45):
    try:
        with socket.create_connection(('192.168.212.30',502),timeout=2) as sock:
            sock.settimeout(2)
            sock.sendall(struct.pack('>HHHBBHH',1234,0,6,1,3,0,4))
            tx,protocol,length,unit=struct.unpack('>HHHB',receive(sock,7))
            if (tx,protocol,length,unit)!=(1234,0,11,1): raise ValueError('MBAP inesperado')
            pdu=receive(sock,length-1)
            if pdu[:2]!=bytes([3,8]): raise ValueError('PDU no es respuesta FC03 de 4 registros')
            values=struct.unpack('>4H',pdu[2:])
            if values!=(250,1000,1,750): raise ValueError('Registros distintos de configuracion')
        print('READY FC03 real: 192.168.212.30:502 unit1 registers0..3 =',values)
        break
    except (OSError,ValueError,struct.error) as error:
        last=error
        time.sleep(1)
else:
    raise SystemExit('ModbusPal no respondio correctamente tras 45 intentos: '+str(last))
PY
ss -ltn 'sport = :502'
printf '%s\n' 'Comprobar desde Kali con modbus_read.py y capturar Modbus TCP en Wireshark.'
