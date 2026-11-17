"""Verifica el manifiesto y las capturas de la demostracion sin modificar evidencias."""
import hashlib
import json
from pathlib import Path
import sys

root=Path(__file__).resolve().parents[2]
meta=json.loads((root/'docs/DATOS_SUSTENTACION.json').read_text(encoding='utf-8-sig'))
folder=root/'evidencias/sustentaciones'/meta['corrida']
results=[]
for line in (folder/'SHA256SUMS-TOTAL.txt').read_text(encoding='utf-8-sig').splitlines():
    expected,name=line.split('  ',1)
    path=(folder/name).resolve()
    if not path.is_relative_to(folder.resolve()): raise SystemExit('Manifiesto fuera de su carpeta')
    actual=hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else ''
    results.append({'archivo':name,'correcto':actual==expected})
for name in meta['capturas']:
    path=folder/'capturas'/name
    results.append({'archivo':'capturas/'+name,'correcto':path.is_file() and path.read_bytes().startswith(b'\x89PNG\r\n\x1a\n')})
original=folder/'07-integridad/original.evidencia'
altered=folder/'07-integridad/copia-alterada.evidencia'
source=folder/'04-trafico/comunicaciones.pcapng'
digest=lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
results.append({'archivo':'fuente=original y original!=alterada','correcto':digest(source)==digest(original)==meta['sha256_original'] and digest(altered)==meta['sha256_alterada'] and digest(original)!=digest(altered)})
print(json.dumps({'corrida':meta['corrida'],'correctos':sum(x['correcto'] for x in results),'total':len(results),'capturas':len(meta['capturas']),'resultados':results},ensure_ascii=False,indent=2))
sys.exit(0 if all(x['correcto'] for x in results) else 1)
