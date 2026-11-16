"""Get an SSH host public key without authenticating; print only after fingerprint match.
Uses local Paramiko dependency to avoid Windows ssh-keyscan KEX incompatibilities.
"""
from pathlib import Path
import argparse,base64,hashlib,ipaddress,socket,sys
ROOT=Path(__file__).resolve().parents[2]

def fingerprint(key_bytes):
    return 'SHA256:'+base64.b64encode(hashlib.sha256(key_bytes).digest()).decode().rstrip('=')

def checked_line(host,key_type,key_bytes,expected):
    if fingerprint(key_bytes)!=expected.rstrip('='):
        raise ValueError('Huella distinta de consola: no se acepta ni autentica')
    return '%s %s %s'%(host,key_type,base64.b64encode(key_bytes).decode())

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--host',required=True)
    parser.add_argument('--expected',required=True,help='SHA256:... de consola/serial del invitado')
    args=parser.parse_args()
    try:
        host=str(ipaddress.IPv4Address(args.host))
    except ipaddress.AddressValueError:
        parser.error('Host debe ser IPv4 literal de VM local')
    if not args.expected.startswith('SHA256:'):
        parser.error('Se requiere huella SHA256 de consola')
    sys.path.insert(0,str(ROOT/'config/legacy-ssh'))
    try:
        import paramiko
    except ImportError:
        parser.error('Instalar: python -m pip install --target config/legacy-ssh paramiko==3.5.1')
    transport=None
    try:
        with socket.create_connection((host,22),timeout=10) as sock:
            transport=paramiko.Transport(sock)
            transport.start_client(timeout=15)
            # Se intercambia solo SSH/KEX; no se llama ningun metodo auth_*.
            key=transport.get_remote_server_key()
            line=checked_line(host,key.get_name(),key.asbytes(),args.expected)
            transport.close()
            transport=None
        print(line)
        return 0
    except (OSError,ValueError,paramiko.SSHException) as error:
        print('ERROR: '+str(error),file=sys.stderr)
        return 1
    finally:
        if transport is not None: transport.close()

if __name__=='__main__':
    sys.exit(main())
