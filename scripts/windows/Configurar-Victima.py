"""Bootstrap de la víctima importada, exclusivamente por VMnet1 local.
Se valida la relación IP DHCP/MAC del VMX antes de autenticar. Credencial pública
intencional de Metasploitable 2: msfadmin:msfadmin, documentada por Rapid7.
"""
from pathlib import Path
import sys, json, re, ipaddress, socket, time, subprocess, io, shlex, hashlib, base64
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'config/legacy-ssh'))
import paramiko
import argparse
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--ip',required=True)
parser.add_argument('--expected-host-fingerprint',help='SHA256:... o MD5:aa:bb:... de consola; obligatoria si clave host no fijada')
args=parser.parse_args()
ip=ipaddress.ip_address(args.ip)
if ip not in ipaddress.ip_network('192.168.212.128/25') or str(ip).endswith('.255'):
    raise SystemExit('Se admite únicamente DHCP de VMnet1 .128-.254')
record=json.loads((ROOT/'config/victima-importada.json').read_text(encoding='utf-8-sig'))
vmx=Path(record['vmx'])
text=vmx.read_text(encoding='utf-8-sig')
if not re.search(r'ethernet0.connectionType\s*=\s*"hostonly"',text,re.I): raise SystemExit('Víctima no hostonly')
if not re.search(r'ethernet0.vnet\s*=\s*"VMnet1"',text,re.I): raise SystemExit('Red incorrecta')
mac_match=re.search(r'ethernet0.generatedAddress\s*=\s*"([^"]+)"',text,re.I)
if not mac_match: raise SystemExit('No hay MAC generada en VMX, arrancar aislada primero')
mac=mac_match.group(1).lower()
config=json.loads((ROOT/'config/local.json').read_text(encoding='utf-8-sig'))
leases=Path(config['DhcpLeasesPath']).read_text(errors='replace')
blocks=re.findall(r'lease\s+([\d.]+)\s*\{([^}]+)\}',leases,re.S)
if not any(address==str(ip) and mac in body.lower() for address,body in blocks):
    raise SystemExit('La IP DHCP no coincide con la MAC de la víctima importada')
print('Identidad local verificada: IP',ip,'MAC',mac,'VMX',vmx)
sshdir=ROOT/'config/ssh'; sshdir.mkdir(exist_ok=True)
key=sshdir/'victima_ed25519'
# OpenSSH antiguo Ubuntu 8.04 no admite Ed25519: clave RSA exclusiva del laboratorio.
key=sshdir/'victima_rsa'
if not key.exists(): subprocess.run(['ssh-keygen','-t','rsa','-b','3072','-N','','-C','lab-victima-local','-f',str(key)],check=True)
pub=key.with_suffix('.pub').read_text().strip()
client=paramiko.SSHClient()
known=sshdir/'victima_known_hosts'
if known.exists(): client.load_host_keys(str(known))
# La politica se invoca antes de autenticarse: MAC/lease no sustituyen huella SSH.
def fingerprint(key):
    return 'SHA256:'+base64.b64encode(hashlib.sha256(key.asbytes()).digest()).decode().rstrip('=')
def matches_expected(key,expected):
    if expected.startswith('SHA256:'):
        return fingerprint(key).rstrip('=')==expected.rstrip('=')
    value=expected[4:] if expected.upper().startswith('MD5:') else expected
    actual=':'.join('%02x'%b for b in hashlib.md5(key.asbytes(),usedforsecurity=False).digest())
    return value.lower()==actual
trusted=[]
if known.exists():
    for address in (str(ip),'192.168.212.20'):
        trusted.extend(client.get_host_keys().get(address,{}).values())
expected=args.expected_host_fingerprint
if not trusted and not expected:
    raise SystemExit('Primer uso: --expected-host-fingerprint SHA256:... o MD5:... de consola es obligatorio')
if expected and not re.fullmatch(r'(SHA256:[A-Za-z0-9+/]+={0,2}|(?:MD5:)?(?:[0-9a-fA-F]{2}:){15}[0-9a-fA-F]{2})',expected):
    raise SystemExit('Formato de huella SHA256/MD5 invalido')
if expected and trusted and not any(matches_expected(k,expected) for k in trusted):
    raise SystemExit('Huella indicada no coincide con clave ya fijada; investigar antes de autenticar')
class VerifiedHostKeyPolicy(paramiko.MissingHostKeyPolicy):
    def missing_host_key(self,ssh_client,hostname,key):
        actual=fingerprint(key)
        if expected:
            valid=matches_expected(key,expected)
        else:
            valid=any(key.get_name()==k.get_name() and key.asbytes()==k.asbytes() for k in trusted)
        if not valid:
            raise paramiko.SSHException('Huella no coincide con consola/clave fijada; no se autentica')
        ssh_client.get_host_keys().add(hostname,key.get_name(),key)
client.set_missing_host_key_policy(VerifiedHostKeyPolicy())
client.connect(str(ip),username='msfadmin',password='msfadmin',look_for_keys=False,allow_agent=False,timeout=15,banner_timeout=15,auth_timeout=15)
serverkey=client.get_transport().get_remote_server_key()
client.get_host_keys().add('192.168.212.20',serverkey.get_name(),serverkey)
client.save_host_keys(str(known))
print('Clave de host fijada:',serverkey.get_name(),serverkey.get_base64())
commands='''set -eu
mkdir -p /home/msfadmin/.ssh
chmod 700 /home/msfadmin/.ssh
touch /home/msfadmin/.ssh/authorized_keys
KEY='''+"'"+pub+"'"+'''
grep -qxF "$KEY" /home/msfadmin/.ssh/authorized_keys || printf '%s\\n' "$KEY" >> /home/msfadmin/.ssh/authorized_keys
chmod 600 /home/msfadmin/.ssh/authorized_keys
id
uname -a
ifconfig eth0
route -n
'''
stdin,stdout,stderr=client.exec_command(commands,timeout=30)
out=stdout.read().decode(errors='replace'); err=stderr.read().decode(errors='replace')
if stdout.channel.recv_exit_status()!=0: raise SystemExit(out+err)
print(out)
root_script='''set -eu
cp -p /etc/network/interfaces /etc/network/interfaces.antes-lab
cat > /etc/network/interfaces <<'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 192.168.212.20
    netmask 255.255.255.0
EOF
pkill -x dhclient 2>/dev/null || true
/sbin/sysctl -w net.ipv4.ip_forward=0
printf '\\n# Laboratorio aislado\\nnet.ipv4.ip_forward=0\\n' >> /etc/sysctl.conf
# Aplicar con unos segundos de margen para cerrar SSH ordenadamente.
nohup /bin/sh -c 'sleep 3; /sbin/ifconfig eth0 192.168.212.20 netmask 255.255.255.0 up; /sbin/route del default 2>/dev/null || true' >/tmp/red-lab.log 2>&1 </dev/null &
'''
# Sudo recibe password estándar del laboratorio por stdin; no credenciales personales.
stdin,stdout,stderr=client.exec_command('sudo -k; sudo -S -p "" /bin/sh -c '+shlex.quote(root_script),timeout=30)
stdin.write('msfadmin\n'); stdin.channel.shutdown_write()
print(stdout.read().decode(errors='replace')); print(stderr.read().decode(errors='replace'))
if stdout.channel.recv_exit_status()!=0: raise SystemExit('Falló configuración privilegiada')
client.close()
for _ in range(20):
    try:
        client=paramiko.SSHClient(); client.load_host_keys(str(known)); client.set_missing_host_key_policy(paramiko.RejectPolicy())
        client.connect('192.168.212.20',username='msfadmin',pkey=paramiko.RSAKey.from_private_key_file(str(key)),disabled_algorithms={'pubkeys':['rsa-sha2-256','rsa-sha2-512']},look_for_keys=False,allow_agent=False,timeout=5)
        break
    except (OSError,paramiko.SSHException): time.sleep(2)
else: raise SystemExit('IP fija/SSH clave no verificados')
_,stdout,stderr=client.exec_command('date -u; id; ifconfig eth0; route -n; /sbin/sysctl net.ipv4.ip_forward')
result=stdout.read().decode(errors='replace')+stderr.read().decode(errors='replace')
print('VERIFICACIÓN IP FIJA Y CLAVE:\n'+result)
(ROOT/'evidencias/00-inventario').mkdir(parents=True,exist_ok=True)
(ROOT/'evidencias/00-inventario/victima-ssh-verificada.txt').write_text(result,encoding='utf-8')
client.close()




