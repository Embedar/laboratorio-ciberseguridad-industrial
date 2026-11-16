# PLC ModbusPal: montaje e incidencia resuelta

El procedimiento reproducible vigente está en el [README raíz, paso5](../README.md#5-crear-y-configurar-el-plc-simulado). Esta nota conserva las decisiones del montaje real del12/11/2026 y las correcciones documentales del16/11/2026.

## Montaje realizado

Se creó Ubuntu24.04 desde VMDK oficial, se contrastó SHA256SUMS y se generó semilla NoCloud. La VM limpia usó NAT temporal para SSH, VMware Tools y Java. Se apagó limpiamente y quedó con un solo adaptador host-only VMnet1, .30/24, sin gateway ni forwarding. Recursos:768MB/1CPU, disco sparse; Java heap32–128MB.

Se instaló ModbusPal1.6b real con un adaptador Java propio sin GUI. El servicio modbuspal-lab usa el usuario lab y capacidad para abrirTCP502. Se confirmaron desde Kali tres lecturasFC03, unit1, direcciónPDU0, cantidad4, valores constantes250/1000/1/750. No son mediciones físicas.

## Incidencia resuelta

El netplan definitivo inicial perdió el match por MAC y el nombre del NIC cambió al reiniciar. Se recuperó la nueva VM con NoCloud y se conservó matchMAC/set-name ens33. El finalizador publicado ya mantiene esa configuración. La reparación excepcional exige verificar que la VM esté apagada antes de sustituir una semilla; no se ejecuta para el uso cotidiano.

## Correcciones para un clon nuevo

- Configuración local en config/local.json, no rutas personales publicadas.
- Huella SSH comparada con consola/serial antes de autenticar; la misma identidad se fija también para .30.
- Finalizar-PLC espera cloud-init y apagado completo antes de modificar VMX; exige luego SSH en la IP aislada.
- Instalar-PLC espera una respuestaFC03 correcta, además del servicio/socket.
- La fuente Java se compila localmente desde el JDK; no se redistribuye el JAR de terceros.

Estas correcciones de fuentes se comprobaron por sintaxis/fixtures y compilación Java; no se volvió a crear ni aprovisionar una VM completa el16/11/2026. La evidencia funcional corresponde al montaje del12/11/2026.

Fuentes: [Ubuntu cloud images](https://cloud-images.ubuntu.com/releases/noble/release/), [NoCloud](https://docs.cloud-init.io/en/latest/reference/datasources/nocloud.html), [ModbusPal](https://sourceforge.net/projects/modbuspal/).
