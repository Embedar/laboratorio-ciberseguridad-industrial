tshark -r "$R/04-trafico/comunicaciones.pcapng" -Y http -T fields -E header=y -e frame.number -e ip.src -e ip.dst -e http.request.method -e http.request.uri -e http.response.code
