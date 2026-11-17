curl --noproxy '*' --connect-timeout 5 --max-time 15 -f -sS --dump-header "$R/04-trafico/http-headers.txt" --output "$R/04-trafico/http-body.html" http://192.168.212.20/
cat "$R/04-trafico/http-headers.txt"
