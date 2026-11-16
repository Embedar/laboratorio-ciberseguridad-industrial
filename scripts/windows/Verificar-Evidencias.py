"""Verifica las evidencias originales sin modificarlas; solo biblioteca estándar."""
from pathlib import Path
import hashlib, json, sys, datetime
ROOT=Path(__file__).resolve().parents[2]
def digest(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda:f.read(1024*1024),b''): h.update(block)
    return h.hexdigest()
sets=[ROOT/'evidencias/ejecuciones/20261112T163453Z-9047',ROOT/'evidencias/04-integridad/20261112T163840Z-10974']
results=[]
for folder in sets:
    for line in (folder/'SHA256SUMS.txt').read_text(encoding='utf-8-sig').splitlines():
        expected,name=line.split('  ',1)
        path=(folder/name).resolve()
        if not path.is_relative_to(folder.resolve()): raise SystemExit('Ruta de manifiesto fuera de su carpeta')
        results.append({'archivo':str(path.relative_to(ROOT)),'correcto':path.is_file() and digest(path)==expected})
for name in ['01-nmap.png','02-http.png','03-modbus.png','04-telnet.png','05-integridad.png','06-ftk-carpeta.jpg','07-ftk-inspeccion.jpg']:
    path=ROOT/'evidencias/capturas'/name
    results.append({'archivo':str(path.relative_to(ROOT)),'correcto':path.is_file() and ((path.suffix=='.png' and path.read_bytes()[:8]==b'\x89PNG\r\n\x1a\n') or (path.suffix=='.jpg' and path.read_bytes().startswith(b'\xff\xd8\xff') and path.read_bytes().endswith(b'\xff\xd9')))})
print(json.dumps({'fecha_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'correctos':sum(x['correcto'] for x in results),'total':len(results),'resultados':results},indent=2,ensure_ascii=False))
sys.exit(0 if all(x['correcto'] for x in results) else 1)



