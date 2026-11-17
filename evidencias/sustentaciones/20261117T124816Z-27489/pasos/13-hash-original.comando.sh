cp "$R/04-trafico/comunicaciones.pcapng" "$R/07-integridad/original.evidencia"
chmod a-w "$R/07-integridad/original.evidencia"
sha256sum "$R/04-trafico/comunicaciones.pcapng" "$R/07-integridad/original.evidencia"
