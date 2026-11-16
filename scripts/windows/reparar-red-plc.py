import pathlib,sys,io,uuid,json,subprocess
if len(sys.argv)!=2: raise SystemExit('Uso: python reparar-red-plc.py RAIZ; requiere PLC apagado')
root=pathlib.Path(sys.argv[1]).resolve()
config=json.loads((root/'config/local.json').read_text(encoding='utf-8-sig'))
vmx=(root/'vms/plc/PLC.vmx').resolve()
if not vmx.is_file(): raise SystemExit('No existe PLC.vmx')
state=subprocess.run([str(pathlib.Path(config['VMwareDir'])/'vmrun.exe'),'list'],capture_output=True,text=True)
if state.returncode: raise SystemExit('No se puede verificar apagado; no se modifica semilla')
if str(vmx).casefold() in {line.strip().casefold() for line in state.stdout.splitlines()}:
    raise SystemExit('PLC encendido: apagar limpiamente y repetir; no se modifica semilla')
sys.path.insert(0,str(root/'config/python-deps'));import pycdlib
net='''network:
  version: 2
  ethernets:
    plc:
      match:
        macaddress: "00:50:56:22:00:30"
      set-name: ens33
      dhcp4: false
      dhcp6: false
      addresses: [192.168.212.30/24]
      link-local: []
'''
user='''#cloud-config
ssh_deletekeys: false
write_files:
  - path: /etc/netplan/50-cloud-init.yaml
    permissions: '0600'
    content: |
'''+''.join('      '+line+'\n' for line in net.splitlines())+'''runcmd:
  - [netplan, apply]
  - [systemctl, restart, open-vm-tools]
  - [systemctl, restart, ssh]
'''
iso=pycdlib.PyCdlib();iso.new(interchange_level=3,joliet=3,vol_ident='CIDATA')
for name,txt in [('user-data',user),('meta-data','instance-id: plc-repair-'+str(uuid.uuid4())+'\nlocal-hostname: plc-lab\n')]:
 b=txt.encode();iso.add_fp(io.BytesIO(b),len(b),iso_path='/'+name.upper().replace('-','_')+';1',joliet_path='/'+name)
iso.write(str(root/'vms/plc/seed.iso'));iso.close()
