# Estado del laboratorio

Actualización17/11/2026. Las tres VMs existentes se encendieron para generar las nuevas capturas. Se comprobó host-only y rutas de invitados; Kali tenía forwarding 1 al arrancar y se desactivó antes de los sondeos. Revisarlo de nuevo al reiniciar.

Corrida vigente:`20261117T124816Z-27489`. Dos blancos activos;30 puertos TCP abiertos en la víctima;22/502 examinados en el PLC; HTTP 200 y 3 lecturas FC03 [250,1000,1,750]. Telnet confirmó uid 1000 (msfadmin); el PCAP de la sesión conserva sus datos. La fuente HTTP/Modbus tiene5836bytes y la copia alterada5875.

22 capturas nuevas; informe ordenado en nueve apartados,19 páginas y25 imágenes (diagrama,22 capturas nuevas y2 capturas FTK originales señaladas). Guion docs/SUSTENTACION_PASO_A_PASO.md. Verificador nuevo95/95; original35/35. Las evidencias previas se conservan separadas.

Los discos,claves,configuración privada,dependencias y registros UI de diagnóstico no se publican. El repositorio privado continúa en https://github.com/Embedar/laboratorio-ciberseguridad-industrial . El proyecto del robot no se modificó.
