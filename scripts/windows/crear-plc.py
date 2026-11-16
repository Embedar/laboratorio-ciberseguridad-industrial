"""Crea semilla NoCloud y VMX PLC. No arranca ni modifica VM existentes."""
import argparse, io, pathlib, subprocess, sys, uuid
p=argparse.ArgumentParser()
p.add_argument('--root',required=True)
a=p.parse_args(); root=pathlib.Path(a.root).resolve()
sys.path.insert(0,str(root/'config'/'python-deps'))
import pycdlib
vm=root/'vms'/'plc'; vm.mkdir(parents=True,exist_ok=True)
if (vm/'PLC.vmx').exists(): raise SystemExit('PLC.vmx ya existe; no se sobrescribe.')
keys=root/'config'/'ssh'; keys.mkdir(parents=True,exist_ok=True)
key=keys/'plc_ed25519'
if not key.exists(): subprocess.run(['ssh-keygen','-t','ed25519','-f',str(key),'-N','','-C','lab-plc'],check=True,stdout=subprocess.DEVNULL)
pub=(keys/'plc_ed25519.pub').read_text().strip()
user='''#cloud-config
hostname: plc-lab
manage_etc_hosts: true
users:
  - name: lab
    groups: [sudo]
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: true
    ssh_authorized_keys:
      - PUBLIC_KEY
ssh_pwauth: false
disable_root: true
package_update: true
packages:
  - openssh-server
  - open-vm-tools
  - default-jre-headless
runcmd:
  - [systemctl, enable, --now, ssh]
  - [systemctl, enable, --now, open-vm-tools]
  - [sh, -c, 'date -u > /var/tmp/plc-provisionado']
final_message: "PLC cloud-init terminado tras $UPTIME segundos"
'''.replace('PUBLIC_KEY',pub)
meta='instance-id: plc-'+str(uuid.uuid4())+'\nlocal-hostname: plc-lab\n'
network='''version: 2
ethernets:
  plc:
    match:
      macaddress: "00:50:56:22:00:30"
    set-name: ens33
    dhcp4: true
    dhcp6: false
'''
iso=pycdlib.PyCdlib(); iso.new(interchange_level=3,joliet=3,vol_ident='CIDATA')
for name,content in [('user-data',user),('meta-data',meta),('network-config',network)]:
    data=content.encode(); iso.add_fp(io.BytesIO(data),len(data),iso_path='/'+name.upper().replace('-','_')+';1',joliet_path='/'+name)
iso.write(str(vm/'seed.iso')); iso.close()
vmx=''' .encoding = "UTF-8"
config.version = "8"
virtualHW.version = "19"
displayName = "PLC-Lab-Ubuntu"
guestOS = "ubuntu-64"
firmware = "efi"
uefi.secureBoot.enabled = "FALSE"
memsize = "768"
numvcpus = "1"
scsi0.present = "TRUE"
scsi0.virtualDev = "lsilogic"
scsi0:0.present = "TRUE"
scsi0:0.fileName = "PLC.vmdk"
sata0.present = "TRUE"
sata0:0.present = "TRUE"
sata0:0.deviceType = "cdrom-image"
sata0:0.fileName = "seed.iso"
sata0:0.startConnected = "TRUE"
ethernet0.present = "TRUE"
ethernet0.connectionType = "nat"
ethernet0.virtualDev = "e1000"
ethernet0.addressType = "static"
ethernet0.address = "00:50:56:22:00:30"
ethernet0.startConnected = "TRUE"
serial0.present = "TRUE"
serial0.fileType = "file"
serial0.fileName = "serial-boot.log"
serial0.startConnected = "TRUE"
usb.present = "FALSE"
sound.present = "FALSE"
floppy0.present = "FALSE"
'''.lstrip()
(vm/'PLC.vmx').write_text(vmx,encoding='utf-8')
print('Creado PLC.vmx NAT solo para aprovisionar; NO ejecutar practica hasta hostonly.')
