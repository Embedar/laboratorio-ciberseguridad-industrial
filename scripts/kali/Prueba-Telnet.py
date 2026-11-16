#!/usr/bin/env python3
"""Controlled default-credential test, restricted to the isolated Metasploitable VM."""
import argparse
import datetime
import io
import re
import shutil
import sys

HOST = "192.168.212.20"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default=HOST, choices=[HOST])
    parser.add_argument("--timeout", type=int, default=15)
    args = parser.parse_args()
    if not 1 <= args.timeout <= 60:
        parser.error("Timeout debe estar entre 1 y 60 segundos")
    try:
        import pexpect
    except ImportError:
        print("ERROR: instalar python3-pexpect durante aprovisionamiento", file=sys.stderr)
        return 2
    telnet_bin = shutil.which("telnet")
    if not telnet_bin:
        print("ERROR: instalar telnet durante aprovisionamiento", file=sys.stderr)
        return 2
    print("UTC: " + datetime.datetime.now(datetime.timezone.utc).isoformat())
    print("Alcance fijo: %s:23; credencial publica de laboratorio msfadmin:msfadmin" % HOST)
    print("Prueba: iniciar sesion y consultar id/uname; no modifica archivos")
    transcript = io.StringIO()
    child = None
    result = 1
    try:
        child = pexpect.spawn(telnet_bin, [HOST, "23"], encoding="utf-8", codec_errors="replace", timeout=args.timeout)
        child.logfile_read = transcript
        child.expect(r"(?i)login:\s*")
        child.sendline("msfadmin")
        child.expect(r"(?i)password:\s*")
        child.sendline("msfadmin")
        child.expect(r"(?m)^.*msfadmin[^\r\n]*[$#]\s*")
        child.sendline("id")
        child.expect(r"uid=\d+[^\r\n]*")
        child.expect(r"(?m)^.*msfadmin[^\r\n]*[$#]\s*")
        child.sendline("uname -a")
        child.expect(r"Linux[^\r\n]*")
        child.expect(r"(?m)^.*msfadmin[^\r\n]*[$#]\s*")
        child.sendline("exit")
        child.expect(pexpect.EOF)
        print("RESULTADO: acceso con credencial por defecto y consultas confirmados")
        result = 0
    except (pexpect.TIMEOUT, pexpect.EOF, OSError) as error:
        print("RESULTADO: prueba NO confirmada (%s)" % type(error).__name__, file=sys.stderr)
    finally:
        if child is not None:
            child.close(force=True)
        clean = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", transcript.getvalue())
        clean = clean.replace("\r\n", "\n").replace("\r", "\n")
        print("--- TRANSCRIPCION RECIBIDA ---")
        print(clean)
    return result


if __name__ == "__main__":
    sys.exit(main())
