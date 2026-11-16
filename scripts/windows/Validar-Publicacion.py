"""Comprueba los bytes del índice Git; no lee archivos privados ignorados ni autentica."""
from pathlib import Path, PurePosixPath
import argparse
import re
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--staged',action='store_true',required=True)
parser.parse_args()

def git(*args):
    return subprocess.run(['git','-C',str(ROOT),*args],check=True,capture_output=True).stdout

paths=[x.decode('utf-8') for x in git('diff','--cached','--name-only','--diff-filter=ACMR','-z').split(b'\0') if x]
if not paths:
    print('No hay archivos nuevos/modificados en el índice; no hay publicación que validar.')
    raise SystemExit(1)

private=re.compile(rb'-----BEGIN (?:OPENSSH |RSA |EC |DSA )?PRIVATE KEY-----')
tokens=re.compile(rb'(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})')
personal_password=re.compile(rb'Lorenzox[0-9]+',re.I)
blocked_ext={'.vmx','.vmdk','.vmem','.nvram','.vmss','.vmsn','.iso','.ova','.ovf','.jar','.class','.pyc','.pfx','.p12','.pem','.key'}
allowed_top={'docs','scripts','evidencias'}
allowed_root={'README.md','ESTADO_ACTUAL.md','.gitignore','.gitattributes','config.example.json'}
errors=[]; total=0
for path in paths:
    p=PurePosixPath(path)
    if p.is_absolute() or '..' in p.parts: errors.append((path,'Ruta no admisible')); continue
    if (len(p.parts)==1 and path not in allowed_root) or (len(p.parts)>1 and p.parts[0] not in allowed_top):
        errors.append((path,'Fuera de la lista de material publicable'))
    if p.suffix.lower() in blocked_ext or any(part in {'config','descargas','vms','build','__pycache__','.venv'} for part in p.parts):
        errors.append((path,'Artefacto local, privado, de VM o de tercero'))
    data=git('show',':'+path); total+=len(data)
    if len(data)>10*1024*1024: errors.append((path,'Más de 10 MiB: revisar exclusión/entrega'))
    if private.search(data): errors.append((path,'Bloque de clave privada'))
    if tokens.search(data): errors.append((path,'Patrón de token GitHub'))
    if personal_password.search(data): errors.append((path,'Patrón de credencial personal prohibida'))

if errors:
    print('PUBLICACIÓN BLOQUEADA:')
    for path,reason in errors: print('- '+path+': '+reason)
    raise SystemExit(2)
print(f'Índice revisado: {len(paths)} archivos, {total:,} bytes; sin claves privadas, tokens ni artefactos bloqueados.')
print('Las credenciales sintéticas públicas de Metasploitable son deliberadas y se documentan en README.')
