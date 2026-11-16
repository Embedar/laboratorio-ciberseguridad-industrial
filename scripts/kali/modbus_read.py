#!/usr/bin/env python3
"""Read-only Modbus TCP FC03 client for the isolated PLC lab (stdlib only)."""
import argparse
import json
import secrets
import socket
import struct
import sys
from datetime import datetime, timezone

ALLOWED_HOST = "192.168.212.30"


def recv_exact(sock, length):
    data = bytearray()
    while len(data) < length:
        chunk = sock.recv(length - len(data))
        if not chunk:
            raise ConnectionError("Conexion cerrada antes de recibir la respuesta completa")
        data.extend(chunk)
    return bytes(data)


def read_registers(host, port, unit, address, count, timeout=5.0):
    transaction = secrets.randbelow(65536)
    request = struct.pack(">HHHBBHH", transaction, 0, 6, unit, 3, address, count)
    with socket.create_connection((host, port), timeout=timeout) as sock:
        sock.settimeout(timeout)
        sock.sendall(request)
        header = recv_exact(sock, 7)
        tx, protocol, length, response_unit = struct.unpack(">HHHB", header)
        if tx != transaction or protocol != 0 or response_unit != unit:
            raise ValueError("MBAP invalido: transaction/protocol/unit no coinciden")
        if not 2 <= length <= 254:
            raise ValueError("Longitud MBAP fuera de limites")
        pdu = recv_exact(sock, length - 1)
    if pdu[0] == 0x83:
        if len(pdu) != 2:
            raise ValueError("Respuesta de excepcion mal formada")
        raise RuntimeError("Excepcion Modbus FC03: codigo %d" % pdu[1])
    if pdu[0] != 3 or len(pdu) < 2:
        raise ValueError("Funcion de respuesta inesperada")
    if pdu[1] != count * 2 or len(pdu) != count * 2 + 2:
        raise ValueError("Cantidad de bytes/registros no coincide con lo solicitado")
    return list(struct.unpack(">" + "H" * count, pdu[2:]))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default=ALLOWED_HOST, choices=[ALLOWED_HOST])
    parser.add_argument("--port", type=int, default=502)
    parser.add_argument("--unit", type=int, default=1)
    parser.add_argument("--address", type=int, default=0)
    parser.add_argument("--count", type=int, default=4)
    args = parser.parse_args()
    if not 1 <= args.port <= 65535 or not 0 <= args.unit <= 247:
        parser.error("Puerto o unit fuera de limites")
    if not 1 <= args.count <= 125 or not 0 <= args.address <= 65535:
        parser.error("Direccion o cantidad fuera de limites")
    if args.address + args.count > 65536:
        parser.error("El rango supera la direccion Modbus maxima")
    try:
        values = read_registers(args.host, args.port, args.unit, args.address, args.count)
    except (OSError, ValueError, RuntimeError) as error:
        print("ERROR: %s" % error, file=sys.stderr)
        return 1
    print(json.dumps({"timestamp_utc": datetime.now(timezone.utc).isoformat(),
                      "host": args.host, "port": args.port, "unit": args.unit,
                      "function": 3, "address_zero_based": args.address,
                      "registers": values}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
