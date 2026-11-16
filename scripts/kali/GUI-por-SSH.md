# Revisión gráfica por SSH en Kali

Elegir una corrida real propia y cerrada. No se automatiza autenticación del escritorio.

```bash
RUN="$HOME/lab-plc/evidencias/ejecuciones/ID_REAL"
test -s "$RUN/02-trafico/comunicaciones.pcapng"
dbus-run-session -- xvfb-run -a -s '-screen 0 1280x800x24 -nolisten tcp' \
  bash "$HOME/lab-plc/scripts/kali/Capturar-Evidencias-Xvfb.sh" "$RUN"
```

Qterminal muestra resúmenes de los archivos originales; Wireshark abre el PCAP. El script descubre las primeras tramas HTTP/Modbus de esa captura. Revisar encuadre/legibilidad de todas las imágenes; una imagen no sustituye al archivo original.

En una sesión gráfica ya iniciada, también puede abrirse Wireshark con el DISPLAY/XAUTHORITY reales del usuario. No usar xhost + ni desactivar controles. Si el escritorio está bloqueado, desbloquearlo manualmente o usar la sesión temporal Xvfb.

Filtros: http, modbus, tcp.port == 502 y telnet. Mostrar datos origen/destino y explicar los campos observados. Usar solo credenciales públicas sintéticas de laboratorio en las pruebas capturadas.
