#!/usr/bin/env python3
"""Lee sin modificar un PCAP local y reconstruye los datos Telnet del cliente."""
import argparse
from pathlib import Path
import shutil
import subprocess


def quitar_control_telnet(data):
    out=bytearray(); i=0
    while i<len(data):
        if data[i]==255 and i+1<len(data):
            command=data[i+1]
            if command==250:
                end=data.find(b'\xff\xf0',i+2)
                if end<0: break
                i=end+2
            elif command in (251,252,253,254): i+=3
            elif command==255: out.append(255); i+=2
            else: i+=2
        else:
            if data[i]==13:
                out.append(10)
                if i+1<len(data) and data[i+1] in (0,10): i+=1
            elif data[i]==10 or 32<=data[i]<=126: out.append(data[i])
            i+=1
    return out.decode('ascii',errors='replace')


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('pcap',type=Path)
    args=p.parse_args()
    if not args.pcap.is_file(): p.error('No existe el PCAP')
    tool=shutil.which('tshark')
    if not tool: p.error('Falta TShark')
    cmd=[tool,'-r',str(args.pcap),'-Y','tcp.dstport == 23 && ip.src == 192.168.212.10 && tcp.len > 0','-T','fields','-e','tcp.stream','-e','tcp.seq_raw','-e','tcp.payload']
    rows=subprocess.check_output(cmd,text=True).splitlines()
    streams={}; seen=set()
    for line in rows:
        stream,seq,payload=line.split('\t')
        if (stream,seq,payload) in seen: continue
        seen.add((stream,seq,payload))
        streams.setdefault(stream,bytearray()).extend(bytes.fromhex(payload.replace(':','')))
    if not streams: raise SystemExit('No hay datos Telnet del cliente')
    for stream,data in streams.items():
        print('STREAM TCP:',stream)
        print('Datos de Kali .10 hacia la victima .20:23, reconstruidos como texto:')
        print(quitar_control_telnet(bytes(data)))
    print('Lectura del archivo conservado; no se abrio una conexion de red.')


if __name__=='__main__': main()
