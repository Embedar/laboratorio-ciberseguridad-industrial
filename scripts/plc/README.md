# PLC ligero con el motor real ModbusPal

ModbusPal 1.6b se ejecuta mediante `ModbusPalHeadless.java`, un adaptador propio sin escritorio. El motor y su API binaria se comprobaron contra el JAR descargado. El servicio systemd, la escucha TCP 502 y tres lecturas FC03 reales se comprobaron durante la corrida de 12 de noviembre de 2026; consultar el informe principal para sus evidencias. Una nueva instalacion debe volver a comprobarse.

## Descargar y compilar desde Windows

Desde la raiz del clon, despues de `Preparar-Entorno.ps1`, con JDK instalado:

```powershell
.\scripts\windows\Descargar-Dependencias.ps1 -CompilarWrapper
# Equivalente manual de compilacion:
javac --release 8 -cp .\descargas\ModbusPal.jar -d .\scripts\plc .\scripts\plc\ModbusPalHeadless.java
java -Xms32m -Xmx128m '-Djava.awt.headless=true' -cp '.\descargas\ModbusPal.jar;.\scripts\plc' ModbusPalHeadless --self-test
```

Las clases `.class` son generadas, no se necesitan publicadas. La descarga valida SHA-256 `cbc6423b8a39ada050c790b86d0eecd08b88c2d37a73382cd20a68b382101aec`. Es una referencia local del binario 1.6b conservado por el proyecto, no firma ni hash publicado por el editor. La version de API de la rama master es distinta y no debe sustituirse sin revisar el wrapper.

## Instalar y comprobar

La imagen PLC se crea con los scripts Windows. Durante aprovisionamiento limpio y antes de conectar victimas instala OpenSSH, open-vm-tools y Java headless. Despues de `Finalizar-PLC.ps1`, con la misma huella host fijada para `.30`:

```powershell
.\scripts\windows\Instalar-PLC.ps1
.\scripts\windows\SSH-PLC.ps1 'systemctl is-active modbuspal-lab; ss -ltn "sport = :502"'
.\scripts\windows\SSH-PLC.ps1 'sudo journalctl -u modbuspal-lab --no-pager -n 20'
```

El instalador comprueba IP `.30/24`, ausencia de rutas default, hash del JAR y las clases compiladas; activa el servicio y espera una respuesta FC03 real con los cuatro valores. No confundir un socket abierto o estado `active` con respuesta valida.

Alternativa dentro del PLC, con archivos transferidos:

```bash
bash /ruta/scripts/plc/Instalar-ModbusPal.sh /ruta/ModbusPal.jar /ruta/scripts/plc
sudo systemctl stop modbuspal-lab
```

## Parametros y limites

- Unit ID 1, holding registers de direccion PDU desde cero: `0=250, 1=1000, 2=1, 3=750`. Valores simulados sin unidades fisicas.
- Heap Java de 32 a 128 MB; memoria total del proceso mayor. JRE con java.desktop disponible, aunque no hay escritorio ni servidor X.
- Servicio usuario `lab`, capacidad `CAP_NET_BIND_SERVICE` para TCP 502; Java no corre como root.
- Motor original escucha todas las interfaces del invitado. Se exige un unico adaptador host-only VMnet1 y ninguna otra IP activa no local. El wrapper comprueba la IP `.30`; el instalador comprueba rutas default. Verificar tambien forwarding cero y ausencia de routing/ICS del host.
- Si el docente exige captura de la ventana original de ModbusPal, ejecutarla y documentarla por separado; el wrapper no es una captura de esa ventana.

## Fuentes

- [ModbusPal oficial](https://sourceforge.net/projects/modbuspal/files/modbuspal/RC%20version%201.6b/)
- [Ayuda upstream de ejecucion embebida sin GUI](https://github.com/zeelos/ModbusPal/blob/master/src/main/java/modbuspal/help/embed-nogui.html)
- [Codigo del enlace TCP](https://github.com/zeelos/ModbusPal/blob/master/src/main/java/modbuspal/link/ModbusTcpIpLink.java)
