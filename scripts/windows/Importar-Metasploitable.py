"""Importación reproducible: nunca arranca una víctima con NAT o puente."""
from pathlib import Path
import zipfile, re, json, hashlib
ROOT=Path(__file__).resolve().parents[2]
archive=ROOT/'descargas/metasploitable-linux-2.0.0.zip'
dest=ROOT/'vms/Victima-Metasploitable2'
(ROOT/'config').mkdir(parents=True,exist_ok=True)
(ROOT/'evidencias/00-inventario').mkdir(parents=True,exist_ok=True)
if dest.exists():
    raise SystemExit('La carpeta destino ya existe. No se sobrescriben VMs.')
with zipfile.ZipFile(archive) as z:
    for entry in z.infolist():
        p=Path(entry.filename)
        if p.is_absolute() or '..' in p.parts or ':' in entry.filename:
            raise SystemExit('Ruta ZIP insegura')
    bad=z.testzip()
    if bad: raise SystemExit(f'ZIP corrupto: {bad}')
    dest.mkdir(parents=True)
    z.extractall(dest)
vmxs=list(dest.rglob('*.vmx'))
if len(vmxs)!=1: raise SystemExit('Se esperaba un único VMX')
vmx=vmxs[0]
src=vmx.read_text(encoding='utf-8-sig')
(ROOT/'config/Metasploitable.original.vmx').write_text(src,encoding='utf-8')
# Se elimina cualquier adaptador de la distribución antes de definir uno aislado.
lines=[line for line in src.splitlines() if not re.match(r'\s*ethernet\d+\.',line,re.I)]
src='\n'.join(lines)+'\n'
def set_value(key,value):
    global src
    pattern=r'^\s*'+re.escape(key)+r'\s*=.*$'
    line=f'{key} = "{value}"'
    src=re.sub(pattern,line,src,flags=re.M) if re.search(pattern,src,re.M) else src+line+'\n'
for k,v in {'displayName':'LAB - Victima Metasploitable 2','memsize':'512','numvcpus':'1','ethernet0.present':'TRUE','ethernet0.connectionType':'hostonly','ethernet0.vnet':'VMnet1','ethernet0.virtualDev':'e1000','ethernet0.addressType':'generated','ethernet0.startConnected':'TRUE','isolation.tools.copy.disable':'TRUE','isolation.tools.paste.disable':'TRUE','isolation.tools.hgfs.disable':'TRUE','sharedFolder.maxNum':'0','floppy0.present':'FALSE','sound.present':'FALSE','usb.present':'FALSE','checkpoint.vmState':''}.items(): set_value(k,v)
# Evitar que un CD de la distribución requiera una ruta ajena.
for match in re.findall(r'^\s*((?:ide|sata)\d+:\d+)\.deviceType\s*=\s*"cdrom[^\"]*"',src,re.M): set_value(match+'.present','FALSE')
vmx.write_text(src,encoding='utf-8')
digest=hashlib.sha256()
with archive.open('rb') as stream:
    for block in iter(lambda:stream.read(8*1024*1024),b''): digest.update(block)
record={'zip':str(archive),'sha256_local':digest.hexdigest(),'vmx':str(vmx),'ram_mb':512,'cpu':1,'network':'hostonly VMnet1','estado':'importada; no arrancada por este script','nota_hash':'Hash de integridad local; no firma ni autenticación del editor.'}
(ROOT/'config/victima-importada.json').write_text(json.dumps(record,indent=2),encoding='utf-8')
print(json.dumps(record,indent=2))

