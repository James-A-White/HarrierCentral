#!/usr/bin/env python3
"""List HC6 procedures whose errors can leave no trace in HC.ErrorLog.

    python3 tools/catch_log_scan.py        # MUST print nothing once clean

Flags, per procedure (db/hc6 app, portal, public-web; TSA is excluded):
  NO-TRY     an API-callable SP (hcapp_ / hcportal_ / publicWeb_) whose body
             has no BEGIN TRY at all (CLAUDE.md: TRY/CATCH on EVERY SP).
             Helpers are not flagged: they run inside their caller's TRY, and
             since 2026-10-13 every API shim writes a THROWN error to
             HC.ErrorLog, so an error escaping a helper still leaves a row.
  CATCH-NOLOG a BEGIN CATCH ... END CATCH that leaves no HC.ErrorLog row:
             it neither INSERTs HC.ErrorLog, calls nonApi_log*, re-throws
             (the shim logs the exception), nor returns the Success = 0
             envelope with ERROR_MESSAGE() (the shim logs the envelope).
  LOG-BEFORE-ROLLBACK an ErrorLog INSERT that precedes the ROLLBACK in the
             same CATCH (the rollback erases it)
Comments are ignored. A line `-- catch-log-ok: <why>` inside a CATCH
silences it (for a CATCH whose caller logs, e.g. a helper that re-throws).
"""
import glob, os, re, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIRS = ['db/hc6/app', 'db/hc6/portal', 'db/hc6/public-web']

def strip(sql):
    sql = re.sub(r'/\*.*?\*/', ' ', sql, flags=re.S)
    return re.sub(r'--(?!\s*catch-log-ok)[^\n]*', ' ', sql)

def main():
    out = []
    for d in DIRS:
        for f in sorted(glob.glob(os.path.join(ROOT, d, '*.sql'))):
            raw = open(f, encoding='utf-8', errors='replace').read()
            m = re.search(r'CREATE\s+OR\s+ALTER\s+(PROCEDURE|PROC)\s+\[?HC6\]?\.\[?(\w+)', raw, re.I)
            if not m:
                continue
            name = m.group(2)
            sql = strip(raw)
            if name.startswith(('hcapp_', 'hcportal_', 'publicWeb_')) and not re.search(r'\bBEGIN\s+TRY\b', sql, re.I):
                out.append(f'NO-TRY        {name}')
            for c in re.finditer(r'\bBEGIN\s+CATCH\b(.*?)\bEND\s+CATCH\b', sql, re.I | re.S):
                body = c.group(1)
                if 'catch-log-ok' in body:
                    continue
                logs = re.search(r'INSERT\s+(INTO\s+)?HC\.ErrorLog|nonApi_log\w*', body, re.I)
                shim_logs = (re.search(r'\bTHROW\b|\bRAISERROR\b', body, re.I)
                             or (re.search(r'\b0\s+AS\s+\[?Success\]?', body, re.I)
                                 and re.search(r'ERROR_MESSAGE\(\)', body, re.I)))
                if not logs and shim_logs:
                    continue
                line = raw.count('\n', 0, raw.find('BEGIN CATCH', c.start()-50 if c.start() > 50 else 0)) + 1
                if not logs:
                    out.append(f'CATCH-NOLOG   {name}')
                else:
                    rb = re.search(r'ROLLBACK', body, re.I)
                    if rb and rb.start() > logs.start():
                        out.append(f'LOG-BEFORE-ROLLBACK {name}')
    for o in out:
        print(o)
    return 1 if out else 0

if __name__ == '__main__':
    sys.exit(main())
