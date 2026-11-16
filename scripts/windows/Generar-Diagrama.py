from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
root=Path(__file__).resolve().parents[2]
im=Image.new('RGB',(1500,850),'#f3f6fb'); d=ImageDraw.Draw(im)
font_path=r'C:\Windows\Fonts\segoeui.ttf'; bold_path=r'C:\Windows\Fonts\segoeuib.ttf'
def font(n,bold=False): return ImageFont.truetype(bold_path if bold else font_path,n)
def text(x,y,t,size=24,color='#24344b',bold=False): d.text((x,y),t,font=font(size,bold),fill=color)
def box(rect,color,title,lines):
    x0,y0,x1,y1=rect
    d.rounded_rectangle(rect,radius=22,fill='white',outline='#d7dfec',width=2)
    d.rounded_rectangle((x0,y0,x1,y0+68),radius=22,fill=color)
    d.rectangle((x0,y0+42,x1,y0+68),fill=color)
    text(x0+24,y0+16,title,27,'white',True)
    for i,line in enumerate(lines): text(x0+24,y0+92+i*37,line,23)
text(60,35,'Laboratorio industrial simulado',42,bold=True)
text(60,93,'Arquitectura implementada y comprobada · 12 de noviembre de 2026',25,'#5b6c84')
box((490,145,1010,320),'#344865','Windows anfitrión',['VMnet1: 192.168.212.1','Administración local mediante SSH'])
d.line((750,320,750,350),fill='#516a91',width=6)
d.rounded_rectangle((180,350,1320,425),radius=17,fill='#dce8fc',outline='#8eaddb',width=2)
text(322,366,'VMnet1 host-only · 192.168.212.0/24 · sin gateway',28,'#243e64',True)
for x in (285,750,1215): d.line((x,425,x,465),fill='#516a91',width=6)
box((65,465,505,715),'#ab6b10','Kali · auditor',['192.168.212.10 / eth0','4096 MB · 2 CPU','Nmap + Wireshark + cliente Modbus','SSH con clave dedicada'])
box((530,465,970,715),'#ab3d46','Metasploitable 2 · víctima',['192.168.212.20 / eth0','512 MB · 1 CPU','HTTP, FTP, Telnet y otros servicios','Blanco autorizado de prueba'])
box((995,465,1435,715),'#087f81','Ubuntu + ModbusPal · PLC',['192.168.212.30 / ens33','768 MB · 1 CPU','Modbus TCP 502 · unit ID 1','Java sin escritorio · heap 128 MB'])
text(64,755,'Cada VM: un único adaptador host-only. Sin NAT ni puente durante las pruebas.',25,bold=True)
text(64,795,'Registros simulados 0–3: [250, 1000, 1, 750]. No son mediciones de un PLC físico.',23,'#5b6c84')
im.save(root/'docs/arquitectura.png')
print(root/'docs/arquitectura.png')

