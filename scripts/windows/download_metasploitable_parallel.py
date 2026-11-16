"""Download official Metasploitable ZIP in validated independent byte ranges."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, wait
import urllib.request
import time
import zipfile
import hashlib
import json
import os

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'descargas'
PARTS = DEST / 'metasploitable-partes'
URL = 'https://pilotfiber.dl.sourceforge.net/project/metasploitable/Metasploitable2/metasploitable-linux-2.0.0.zip'
TOTAL = 865084584
N = 8
BLOCK = (TOTAL + N - 1) // N
PARTS.mkdir(parents=True, exist_ok=True)
progress = [0] * N
started = time.monotonic()

def fetch(index):
    start = index * BLOCK
    end = min(TOTAL - 1, start + BLOCK - 1)
    expected = end - start + 1
    part = PARTS / ('part-%02d.bin' % index)
    offset = part.stat().st_size if part.exists() else 0
    if offset > expected:
        raise RuntimeError('Oversized existing part %d' % index)
    progress[index] = offset
    if offset == expected:
        return part
    for attempt in range(4):
        offset = part.stat().st_size if part.exists() else 0
        if offset == expected:
            return part
        first = start + offset
        req = urllib.request.Request(URL, headers={'Range': 'bytes=%d-%d' % (first, end), 'User-Agent': 'curl/8.13.0', 'Accept-Encoding': 'identity'})
        try:
            with urllib.request.urlopen(req, timeout=30) as response:
                desired = 'bytes %d-%d/%d' % (first, end, TOTAL)
                actual = response.headers.get('Content-Range')
                if response.status != 206 or actual != desired:
                    raise RuntimeError('Refused range: status=%s Content-Range=%r expected=%r' % (response.status, actual, desired))
                with part.open('ab') as handle:
                    while True:
                        chunk = response.read(256 * 1024)
                        if not chunk:
                            break
                        if handle.tell() + len(chunk) > expected:
                            raise RuntimeError('Response exceeds expected part size')
                        handle.write(chunk)
                        progress[index] = handle.tell()
            if part.stat().st_size != expected:
                raise RuntimeError('Truncated part %d' % index)
            return part
        except Exception as exc:
            print('part %d attempt %d: %s' % (index, attempt + 1, exc), flush=True)
            if attempt == 3:
                raise
            time.sleep(2)
    raise RuntimeError('Unreachable')

if __name__ == '__main__':
    with ThreadPoolExecutor(max_workers=N) as pool:
        futures = [pool.submit(fetch, i) for i in range(N)]
        pending = set(futures)
        while pending:
            _, pending = wait(pending, timeout=30)
            elapsed = max(1, time.monotonic() - started)
            size = sum(progress)
            print('PROGRESS %.1f%% %.1f MiB elapsed %.0fs %.2f MiB/s' % (size * 100 / TOTAL, size / 1048576, elapsed, size / 1048576 / elapsed), flush=True)
        ordered = [future.result() for future in futures]
    staging = DEST / 'metasploitable-linux-2.0.0.parallel-validated.zip'
    with staging.open('wb') as output:
        for part in ordered:
            with part.open('rb') as handle:
                while True:
                    block = handle.read(1024 * 1024)
                    if not block:
                        break
                    output.write(block)
    if staging.stat().st_size != TOTAL:
        raise RuntimeError('Wrong assembled size')
    with zipfile.ZipFile(staging) as archive:
        bad = archive.testzip()
        if bad is not None:
            raise RuntimeError('ZIP CRC failed: ' + bad)
        entries = archive.namelist()
    digest = hashlib.file_digest(staging.open('rb'), 'sha256').hexdigest()
    report = {'source': URL, 'bytes': TOTAL, 'sha256': digest, 'zip_crc_test': 'OK', 'entries': entries, 'validation_note': 'SHA-256 local; no published official SHA-256 was compared.'}
    (PARTS / 'verification.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    final = DEST / 'metasploitable-linux-2.0.0.zip'
    if final.exists():
        raise RuntimeError('Validated output preserved as parallel-validated; final already exists')
    os.rename(staging, final)
    print('COMPLETE', final, digest, flush=True)

