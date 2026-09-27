#!/usr/bin/env python3
"""Id case scan for the mobile app — MUST print nothing (James, 2026-09-27).

Every id in the app is lowercase (lib/util/hc_id.dart). Two shapes put an
uppercase one back, and both have shipped:

  1. toUpperCase() on something named like an id. The chat notification tap
     upper-cased its EventId and every lookup missed ("lookup found 0").
  2. Reading a push's `message.data` directly. Payloads are built in SQL,
     which writes ids in UPPERCASE; read them through `message.payload`.

A line that must upper-case an id on purpose carries `// id-case-ok: <why>`
on the line itself or the line above.

    python3 tools/id_case_scan.py        # prints file:line for each finding
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent / 'mobile-app' / 'lib'
UPPER = re.compile(r"""([iI]d|ID)[\]'"]*\)?\??\.(toString\(\)\.)?toUpperCase\(\)""")
RAW_PAYLOAD = re.compile(r'\bmessage\.data\b')
OK = 'id-case-ok'

findings = []
for path in sorted(ROOT.rglob('*.dart')):
    if path.name.endswith(('.g.dart', '.freezed.dart')):
        continue
    lines = path.read_text(encoding='utf-8').split('\n')
    for i, line in enumerate(lines):
        code = line.split('//', 1)[0] if not line.lstrip().startswith('//') else ''
        if not code:
            continue
        waived = OK in line or (i > 0 and OK in lines[i - 1])
        if waived:
            continue
        rel = path.relative_to(ROOT.parent)
        if UPPER.search(code):
            findings.append(f'{rel}:{i + 1}: id upper-cased — use HcId / lowercase')
        if RAW_PAYLOAD.search(code):
            findings.append(f'{rel}:{i + 1}: raw push payload — use message.payload')

for f in findings:
    print(f)
sys.exit(1 if findings else 0)
