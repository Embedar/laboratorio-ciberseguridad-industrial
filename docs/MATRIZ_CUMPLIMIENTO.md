# Matriz de comprobación de la práctica
Revisión del 17/11/2026. Corrida nueva`20261117T124816Z-27489`, separada de la original. El PDF sigue los nueve títulos de la sección 7 de la guía académica.

| Apartado | Página(s) del PDF | Evidencia |
|---|---|---|
|1. Diagrama de la infraestructura virtual implementada|1–2|Diagrama y01-estado|
|2. Tabla de dispositivos, direcciones IP, puertos y servicios identificados|3|Tabla y XML de03-nmap|
|3. Evidencias del reconocimiento realizado con Nmap|4–5|02-descubrimiento,03-nmap-victima,04-nmap-plc|
|4. Capturas y análisis del tráfico en Wireshark|6–10|05–10 y16–18; PCAP de04-trafico|
|5. Identificación de riesgos de seguridad|11|Cuatro condiciones con impacto|
|6. Evidencia de una prueba controlada de vulnerabilidad|12–14|11a–11d,12 y19; transcripción y PCAP de 06-prueba|
|7. Cálculo y verificación de hashes SHA-256|15–17|13–15 y07-integridad; inspección FTK previa separada|
|8. Recomendaciones para mejorar la seguridad de la infraestructura industrial|18|Medida y comprobación posterior por condición|
|9. Conclusiones del trabajo|19|Resultados y límites|

## Actividades de la guía

| Actividad | Requisitos cubiertos | Evidencia |
|---|---|---|
|6.1:5subítems|Equipos activos,IP,puertos,servicios y riesgos|Apartados2,3y5; Nmap y tabla completa|
|6.2:6subítems|Inicio de captura,TCP,HTTP,Modbus,origen/destino y riesgos|Apartado4; terminal y Wireshark sobre el mismo PCAP|
|6.3:5subítems|Servicios,investigación,impacto,prueba y mitigación|Apartados3,5,6y8; credencial aceptada y datos legibles|
|6.4:6subítems|Evidencia previa,SHA-256,registro,copia modificada,recálculo y comparación|Apartado7; fuente conservada y copias diferentes|

## Criterios de evaluación

| Criterio | Peso original | Apartados |
|---|---|---|
|Reconocimiento|20%|2–3|
|Comunicaciones|20%|4|
|Vulnerabilidades|25%|5–6 y8|
|Integridad|15%|7|
|Informe y recomendaciones|20%|1–9, especialmente8–9|

Los porcentajes son ponderaciones de la guía, no calificaciones autoasignadas. La prueba se limita a las VMs autorizadas en red host-only. No se atribuyen escritura Modbus, acceso root ni una CVE explotada.

## Verificación

`python scripts/windows/Verificar-Sustentacion.py` comprueba el manifiesto de la nueva corrida, formato de22 capturas y relación fuente/original/copia alterada:95/95 comprobaciones. `Verificar-Evidencias.py` mantiene35/35de la corrida original. Los conteos incluyen comprobaciones de imágenes y relación de copias; no son todos hashes.
