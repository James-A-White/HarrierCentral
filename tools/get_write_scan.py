#!/usr/bin/env python3
"""List GET handlers that can write — CLAUDE.md "A GET never acts".

    python3 tools/get_write_scan.py      # MUST print nothing

Mail security scanners (Safe Links, Mimecast, Proofpoint), link previews and
prefetchers fetch links before — or instead of — the person, so a link that
writes, sends or consumes a token on GET acts for nobody. The run email's
unsubscribe link did exactly that until 2026-10-14. Flags:

  API-GET-WRITE  an Azure Function in api/Endpoints whose HttpTrigger accepts
                 "get" and which executes a writing HC6 procedure (set / add /
                 insert / delete / record / redeem / send / update / create /
                 confirm / approve / import / mark / clear / join / process /
                 authorize …), unless the file checks HttpMethods.IsPost
                 before acting.
  WEB-GET-WRITE  a Next.js route handler `export async function GET` in
                 public-web/app/api that calls a write path (callAdminApi /
                 callAppApi, or fetch with method POST/PUT/DELETE).

Silence a deliberate, harmless case with a comment `get-ok: <why>` in the
file (e.g. a GET that only re-reads, or one whose write is a pure no-op on
repeat AND cannot be triggered by a scanner). TSA is excluded (defunct).
"""
import glob, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WRITE_SP = re.compile(
    r'\[?HC6\]?\.\[?(\w*(?:set|add|insert|delete|record|redeem|send|update|create|confirm|'
    r'approve|import|archive|mark|clear|join|process|authorize|save|submit|merge)\w*)',
    re.I)


def api_findings():
    out = []
    for f in sorted(glob.glob(os.path.join(ROOT, 'api', 'Endpoints', '*.cs'))):
        if os.path.basename(f).lower().startswith('tsa'):
            continue
        src = open(f, encoding='utf-8', errors='replace').read()
        if 'get-ok:' in src:
            continue
        if not re.search(r'HttpTrigger\([^)]*"get"', src, re.I):
            continue
        writes = sorted({m.group(1) for m in WRITE_SP.finditer(src)
                         if not m.group(1).lower().startswith(('get', 'publicweb_get'))})
        if writes and 'HttpMethods.IsPost' not in src:
            out.append(f'API-GET-WRITE  api/Endpoints/{os.path.basename(f)}: {", ".join(writes)}')
    return out


def web_findings():
    out = []
    for f in sorted(glob.glob(os.path.join(ROOT, 'public-web', 'app', 'api', '**', 'route.ts'), recursive=True)):
        src = open(f, encoding='utf-8', errors='replace').read()
        if 'get-ok:' in src:
            continue
        m = re.search(r'export\s+(?:async\s+)?function\s+GET\s*\(', src)
        if not m:
            continue
        # the GET handler's body: from its signature to the next exported handler
        nxt = re.search(r'\nexport\s+(?:async\s+)?function\s+\w+\s*\(', src[m.end():])
        body = src[m.end(): m.end() + nxt.start()] if nxt else src[m.end():]
        if re.search(r'\bcall(?:Admin|App)Api\s*\(|method\s*:\s*["\'](?:POST|PUT|DELETE|PATCH)["\']', body):
            out.append(f'WEB-GET-WRITE  {os.path.relpath(f, ROOT)}')
    return out


def main():
    found = api_findings() + web_findings()
    for line in found:
        print(line)
    return 1 if found else 0


if __name__ == '__main__':
    sys.exit(main())
