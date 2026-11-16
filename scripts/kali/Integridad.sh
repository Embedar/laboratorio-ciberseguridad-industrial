#!/usr/bin/env bash
# Copia una evidencia, conserva el origen y modifica solo una segunda copia.
set -euo pipefail
if [[ $# != 1 || ! -f $1 ]]; then
  echo 'Uso: bash Integridad.sh /ruta/a/evidencia-real' >&2
  exit 2
fi
source_file=$(realpath -- "$1")
dest="$HOME/lab-plc/evidencias/04-integridad/$(date -u +%Y%m%dT%H%M%SZ)-$$"
mkdir -p -- "$dest"
cp -- "$source_file" "$dest/original.evidencia"
cp -- "$source_file" "$dest/copia-alterada.evidencia"
printf '\nALTERACION CONTROLADA DEL LABORATORIO\n' >> "$dest/copia-alterada.evidencia"
chmod a-w -- "$dest/original.evidencia"
(
  cd -- "$dest"
  sha256sum original.evidencia copia-alterada.evidencia > SHA256SUMS.txt
  sha256sum -c SHA256SUMS.txt > verificacion.txt
  original_hash=$(sha256sum original.evidencia | cut -d ' ' -f1)
  source_hash=$(sha256sum "$source_file" | cut -d ' ' -f1)
  changed_hash=$(sha256sum copia-alterada.evidencia | cut -d ' ' -f1)
  [[ $original_hash == "$source_hash" && $original_hash != "$changed_hash" ]]
  printf 'Fecha UTC: %s\nFuente conservada: %s\nCopia original coincide con fuente: SI\nCopia alterada tiene hash distinto: SI\n' "$(date -u --iso-8601=seconds)" "$source_file" > registro.txt
  cat SHA256SUMS.txt verificacion.txt registro.txt
)
printf 'Resultados: %s\n' "$dest"
