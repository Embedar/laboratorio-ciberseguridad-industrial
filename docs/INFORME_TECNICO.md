# Informe técnico: auditoría de una infraestructura industrial simulada
Demostración del 17/11/2026. Corrida `20261117T124816Z-27489`. El informe sigue los nueve apartados de la guía; la [secuencia de sustentación](SUSTENTACION_PASO_A_PASO.md) presenta una orden por paso. Los registros completos se conservan bajo `evidencias/sustentaciones/20261117T124816Z-27489/`. La corrida original del 12/11 se mantiene separada.

## 1. Diagrama de la infraestructura virtual implementada
![Arquitectura](arquitectura.png)

Kali .10 audita a Metasploitable .20 y al PLC .30 en 192.168.212.0/24. Se reutilizó Kali, se importó la víctima y se aprovisionó Ubuntu con el motor real ModbusPal 1.6b. Cada VM tiene un adaptador host-only. Antes de sondear se comprobaron rutas locales, ausencia de gateway y reenvío 0. Kali activó forwarding al reiniciar; se desactivó con sysctl antes de las pruebas.

![Direcciones, rutas y valores de reenvío comprobados antes de comenzar.](latex/imagenes/sustentacion/01-estado.png)

Direcciones, rutas y valores de reenvío comprobados antes de comenzar.

## 2. Tabla de dispositivos, direcciones IP, puertos y servicios identificados
| Dispositivo | IP | Puerto TCP | Servicio / versión |
|---|---|---|---|
| Windows |192.168.212.1|No sondeados|Anfitrión de la red virtual|
| Kali |192.168.212.10|22 verificado por SSH|Auditor; no fue blanco de Nmap|
|metasploitable|192.168.212.20|21|ftp vsftpd 2.3.4|
|metasploitable|192.168.212.20|22|ssh OpenSSH 4.7p1 Debian 8ubuntu1|
|metasploitable|192.168.212.20|23|telnet Linux telnetd|
|metasploitable|192.168.212.20|25|smtp Postfix smtpd|
|metasploitable|192.168.212.20|53|domain ISC BIND 9.4.2|
|metasploitable|192.168.212.20|80|http Apache httpd 2.2.8|
|metasploitable|192.168.212.20|111|rpcbind|
|metasploitable|192.168.212.20|139|netbios-ssn Samba smbd 3.X - 4.X|
|metasploitable|192.168.212.20|445|netbios-ssn Samba smbd 3.0.20-Debian|
|metasploitable|192.168.212.20|512|exec netkit-rsh rexecd|
|metasploitable|192.168.212.20|513|login|
|metasploitable|192.168.212.20|514|shell Netkit rshd|
|metasploitable|192.168.212.20|1099|java-rmi GNU Classpath grmiregistry|
|metasploitable|192.168.212.20|1524|bindshell Metasploitable root shell|
|metasploitable|192.168.212.20|2049|rpcbind|
|metasploitable|192.168.212.20|2121|ftp ProFTPD 1.3.1|
|metasploitable|192.168.212.20|3306|mysql MySQL 5.0.51a-3ubuntu5|
|metasploitable|192.168.212.20|3632|distccd distccd v1|
|metasploitable|192.168.212.20|5432|postgresql PostgreSQL DB 8.3.0 - 8.3.7|
|metasploitable|192.168.212.20|5900|vnc VNC|
|metasploitable|192.168.212.20|6000|X11|
|metasploitable|192.168.212.20|6667|irc UnrealIRCd|
|metasploitable|192.168.212.20|6697|irc UnrealIRCd|
|metasploitable|192.168.212.20|8009|ajp13 Apache Jserv|
|metasploitable|192.168.212.20|8180|unknown|
|metasploitable|192.168.212.20|8787|drb Ruby DRb RMI|
|metasploitable|192.168.212.20|41128|unknown|
|metasploitable|192.168.212.20|44426|unknown|
|metasploitable|192.168.212.20|45634|unknown|
|metasploitable|192.168.212.20|54652|unknown|
|plc|192.168.212.30|22|ssh OpenSSH 9.6p1 Ubuntu 3ubuntu13.20|
|plc|192.168.212.30|502|mbap|

La víctima se exploró en todos los puertos TCP; el PLC solo en 22/502. No se examinó UDP. Las etiquetas inciertas de Nmap se mantienen.

## 3. Evidencias del reconocimiento realizado con Nmap

![El descubrimiento confirmó los dos blancos activos.](latex/imagenes/sustentacion/02-descubrimiento.png)

El descubrimiento confirmó los dos blancos activos.

![El sondeo completo de la víctima conservó30 puertos abiertos; la imagen reúne las filas de servicios.](latex/imagenes/sustentacion/03-nmap-victima.png)

El sondeo completo de la víctima conservó30 puertos abiertos; la imagen reúne las filas de servicios.

![El sondeo del PLC encontró22/502 abiertos. La lectura FC03 complementa su identificación.](latex/imagenes/sustentacion/04-nmap-plc.png)

El sondeo del PLC encontró22/502 abiertos. La lectura FC03 complementa su identificación.
`-sT` abre conexiones TCP; `-sV` detecta servicios/versiones; `-sC` ejecuta scripts predeterminados; `-p-` examina todos los puertos TCP y `-oA` registra varios formatos. Un puerto abierto permite contactar el servicio; no prueba por sí solo una vulnerabilidad.

## 4. Capturas y análisis del tráfico en Wireshark
PCAP es un archivo de tráfico; aquí el formato es PCAPNG. Dumpcap captura, Wireshark interpreta gráficamente y TShark consulta desde terminal. Cada fila numerada es una trama de esa captura. Se inició el registro antes de curl y de las lecturas Modbus, y se esperó el cierre antes del análisis.

![Dumpcap registra eth0 durante 90 segundos.](latex/imagenes/sustentacion/05-inicio-captura.png)

Dumpcap registra eth0 durante 90 segundos.

![curl solicita la página y conserva los encabezados HTTP 200.](latex/imagenes/sustentacion/06-http.png)

curl solicita la página y conserva los encabezados HTTP 200.

![Tres lecturas FC03 de unidad 1/dirección 0/cantidad 4 devuelven [250,1000,1,750].](latex/imagenes/sustentacion/07-modbus.png)

Tres lecturas FC03 de unidad 1/dirección 0/cantidad 4 devuelven [250,1000,1,750].

![La terminal localiza SYN, SYN-ACK y ACK.](latex/imagenes/sustentacion/08-tcp.png)

La terminal localiza SYN, SYN-ACK y ACK.

![Wireshark muestra esa conversación TCP.](latex/imagenes/sustentacion/16-wireshark-tcp.png)

Wireshark muestra esa conversación TCP.

![La consulta HTTP extrae solicitud y respuesta.](latex/imagenes/sustentacion/09-http-analisis.png)

La consulta HTTP extrae solicitud y respuesta.

![El filtro HTTP relaciona GET / y200 OK con sus IP.](latex/imagenes/sustentacion/17-wireshark-http.png)

El filtro HTTP relaciona GET / y200 OK con sus IP.

![La terminal localiza peticiones y respuestas Modbus.](latex/imagenes/sustentacion/10-modbus-analisis.png)

La terminal localiza peticiones y respuestas Modbus.

![El filtro Modbus muestra las tres parejas de mensajes.](latex/imagenes/sustentacion/18-wireshark-modbus.png)

El filtro Modbus muestra las tres parejas de mensajes.
Las tramas HTTP de esta corrida son4, 6; las Modbus,14, 16, 24, 26, 34, 36. Sus números cambian al repetir. Los enteros son simulados, sin unidades físicas. No se ensayó escritura.

## 5. Identificación de riesgos de seguridad
Se observaron credenciales predeterminadas aceptadas, Telnet sin cifrado, HTTP legible y lectura Modbus sin autenticación. El riesgo depende del alcance de un cliente u observador; no se afirma escucha de terceros ni un impacto en un PLC físico. Rapid7 documenta la credencial del entorno; MITRE publica el catálogo CWE:1392 clasifica credenciales predeterminadas y319 la transmisión sensible en claro. CVE identifica vulnerabilidades concretas; aquí no se demostró explotación de una CVE.

## 6. Evidencia de una prueba controlada de vulnerabilidad

![Telnet conecta a.20:23 y muestra la petición de usuario.](latex/imagenes/sustentacion/11a-telnet-login.png)

Telnet conecta a.20:23 y muestra la petición de usuario.

![Después del usuario msfadmin, el servidor pide la contraseña.](latex/imagenes/sustentacion/11b-telnet-password.png)

Después del usuario msfadmin, el servidor pide la contraseña.

![La credencial pública es aceptada y la consulta id devuelve uid=1000(msfadmin).](latex/imagenes/sustentacion/11c-telnet-identidad.png)

La credencial pública es aceptada y la consulta id devuelve uid=1000(msfadmin).

![uname -a consulta el sistema y exit cierra la sesión.](latex/imagenes/sustentacion/11d-telnet-cierre.png)

uname -a consulta el sistema y exit cierra la sesión.

![La lectura offline reconstruye usuario, contraseña y órdenes desde el PCAP.](latex/imagenes/sustentacion/12-telnet-trafico.png)

La lectura offline reconstruye usuario, contraseña y órdenes desde el PCAP.

![Wireshark muestra la captura específica de esa sesión Telnet.](latex/imagenes/sustentacion/19-wireshark-telnet.png)

Wireshark muestra la captura específica de esa sesión Telnet.
La transcripción confirma acceso; el PCAP de 06-prueba permite inspeccionar los bytes transmitidos. Que la contraseña no tenga eco en la terminal no cifra el canal. Se consultó identidad/sistema, sin solicitar modificación de archivos ni elevación a root. Telnet usa TCP; el puerto23 dirige la conexión hacia el servicio remoto.

## 7. Cálculo y verificación de hashes SHA-256

![Se conserva la fuente y se calcula el SHA-256 de su copia original.](latex/imagenes/sustentacion/13-hash-original.png)

Se conserva la fuente y se calcula el SHA-256 de su copia original.

![Solo una segunda copia recibe 39 bytes; su tamaño y hash cambian.](latex/imagenes/sustentacion/14-copia-alterada.png)

Solo una segunda copia recibe 39 bytes; su tamaño y hash cambian.

![Cada archivo coincide con su propio registro de hashes y las dos copias son diferentes.](latex/imagenes/sustentacion/15-verificacion.png)

Cada archivo coincide con su propio registro de hashes y las dos copias son diferentes.

| Archivo | Tamaño | SHA-256 |
|---|---|---|
| Fuente/original |5836|`07e25cbcf2ff5ed1130c93ce8af38aab6e87d0db7c7f6b4684631410694b13f3`|
| Copia alterada |5875|`23713f15a41b2f1181aff11d0126841952193ddd3cd42021a5c039601dd8b12d`|

La inspección FTK original del 12/11 se conserva como complemento, con su PCAP de20.940 bytes; no se atribuyen esos datos a esta nueva corrida. El hash posterior de aquel archivo se calculó con Get-FileHash.

## 8. Recomendaciones para mejorar la seguridad de la infraestructura industrial
Cambiar credenciales predeterminadas; retirar Telnet y administrar por SSH; utilizar canales protegidos cuando la información lo requiera; segmentar y limitar clientes Modbus; reducir servicios innecesarios. Verificar después rechazo de credenciales antiguas, cierre de TCP23, canal protegido y bloqueo de clientes no autorizados. Son recomendaciones: no se retiraron las condiciones didácticas antes de las capturas.

## 9. Conclusiones del trabajo
Se reconocieron dos blancos, se analizaron comunicaciones y se comprobó acceso con una credencial pública. La evidencia de red permitió interpretar lo transmitido y los hashes detectaron una alteración conservando la fuente. La nueva secuencia puede repetirse con el guion, guardando cada demostración por separado.
