cp "$R/07-integridad/original.evidencia" "$R/07-integridad/copia-alterada.evidencia"
chmod u+w "$R/07-integridad/copia-alterada.evidencia"
printf '\nALTERACION CONTROLADA DEL LABORATORIO\n' >> "$R/07-integridad/copia-alterada.evidencia"
wc -c "$R/07-integridad/"*.evidencia
sha256sum "$R/07-integridad/"*.evidencia
