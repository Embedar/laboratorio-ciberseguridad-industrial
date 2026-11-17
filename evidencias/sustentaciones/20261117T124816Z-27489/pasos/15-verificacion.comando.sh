cd "$R/07-integridad"
sha256sum original.evidencia copia-alterada.evidencia > SHA256SUMS.txt
sha256sum -c SHA256SUMS.txt
cmp -s original.evidencia copia-alterada.evidencia && exit 1
echo 'Fuente conservada; copias diferentes; ambos hashes registrados.'
