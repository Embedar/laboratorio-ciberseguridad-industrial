nmap -n -sT -sV -sC --version-light --script-timeout 30s --host-timeout 600s -p- 192.168.212.20 -oA "$R/03-nmap/metasploitable" > "$R/03-nmap/salida-completa.txt"
awk '/^Nmap scan report/ || /^Host is up/ || /^PORT / || /^[0-9]+\/tcp/ || /^Nmap done/' "$R/03-nmap/metasploitable.nmap"
