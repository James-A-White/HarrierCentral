#!/usr/bin/env python3
"""List HC6 write procedures that are not provably safe to arrive twice.

    python3 tools/idempotency_scan.py                  # MUST print nothing
    python3 tools/idempotency_scan.py --all            # include grandfathered
    python3 tools/idempotency_scan.py --update-baseline  # rewrite the baseline

CLAUDE.md "Idempotent writes" (James, 2026-10-14): every call that writes must
be safe to arrive twice — a double tap, a "try again" after a lost reply, the
app transport's six automatic retries. This scan makes the rule mechanical for
the database side. Flags, per procedure (db/hc6 app, portal, public-web; TSA
excluded):

  NO-DECLARATION  a procedure that writes (INSERT / UPDATE / MERGE / DELETE on
                  an HC., EXT. or DomainValues. table, or EXEC of an hcapp_ /
                  nonApi_ procedure) whose header has no line
                      -- Idempotency: <pattern> — <why>
                  with <pattern> one of: client-id, set-state,
                  compare-and-set, send-id, locked-upsert, log-only,
                  read-only, exempt. Writing the line is the point: the author
                  has to decide which row of the CLAUDE.md table applies.
  BAD-PATTERN     an Idempotency line whose pattern is not one of those.
  UNLOCKED-CHECK  an IF [NOT] EXISTS (SELECT … FROM <HC table> …) with no
                  UPDLOCK in the subquery, followed within the procedure by an
                  INSERT into the same table — two concurrent callers can both
                  pass the check (the classic check-then-insert race). Use
                  WITH (UPDLOCK, HOLDLOCK), MERGE … WITH (HOLDLOCK) or
                  sp_getapplock. Silence one deliberately with
                  `-- idem-ok: <why>` on the IF line.

Writes to HC.ErrorLog and LOG.* are logs and are not counted as writes.

Existing procedures written before the rule are grandfathered in
tools/idempotency_baseline.txt (one `RULE name` per line). The baseline only
shrinks: when you touch a grandfathered procedure, give it its Idempotency
line (and fix its lock) and run --update-baseline; never add to it by hand.
"""
import glob, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIRS = ['db/hc6/app', 'db/hc6/portal', 'db/hc6/public-web']
BASELINE = os.path.join(ROOT, 'tools', 'idempotency_baseline.txt')
PATTERNS = {'client-id', 'set-state', 'compare-and-set', 'send-id',
            'locked-upsert', 'log-only', 'read-only', 'exempt'}

WRITE = re.compile(
    r'\b(?:INSERT\s+(?:INTO\s+)?(?:\[?(?:HC|EXT|DomainValues)\]?\.)(?!\[?ErrorLog\b)'
    r'|UPDATE\s+(?:\[?(?:HC|EXT|DomainValues)\]?\.)'
    r'|UPDATE\s+\w+\s+SET\b'
    r'|MERGE\s+(?:INTO\s+)?(?:\[?(?:HC|EXT)\]?\.)'
    r'|DELETE\s+(?:FROM\s+)?(?:\[?(?:HC|EXT)\]?\.)'
    r'|DELETE\s+\w+\s+FROM\s+(?:\[?(?:HC|EXT)\]?\.)'
    r'|EXEC(?:UTE)?\s+(?:@\w+\s*=\s*)?\[?HC6\]?\.\[?(?:hcapp_|nonApi_))',
    re.I)
DECL = re.compile(r'--\s*Idempotency:\s*([\w-]+)', re.I)
CHECK = re.compile(
    r'IF\s*\(?\s*(?:NOT\s+)?EXISTS\s*\(\s*SELECT\b(?P<sub>.*?)\bFROM\s+'
    r'\[?(?P<schema>HC|EXT)\]?\.\[?(?P<table>\w+)\]?(?P<rest>[^;]*?)\)',
    re.I | re.S)


def strip_comments(sql):
    sql = re.sub(r'/\*.*?\*/', ' ', sql, flags=re.S)
    return re.sub(r'--(?!\s*idem-ok)[^\n]*', ' ', sql)


def findings():
    out = []
    for d in DIRS:
        for f in sorted(glob.glob(os.path.join(ROOT, d, '*.sql'))):
            raw = open(f, encoding='utf-8', errors='replace').read()
            m = re.search(r'CREATE\s+OR\s+ALTER\s+(?:PROCEDURE|PROC)\s+\[?HC6\]?\.\[?(\w+)', raw, re.I)
            if not m:
                continue
            name = m.group(1)
            sql = strip_comments(raw)
            if not WRITE.search(sql):
                continue
            decl = DECL.search(raw)
            if not decl:
                out.append(('NO-DECLARATION', name))
            elif decl.group(1).lower() not in PATTERNS:
                out.append(('BAD-PATTERN', name))
            for c in CHECK.finditer(sql):
                window = sql[c.start():c.end() + 400]
                if re.search(r'idem-ok', window[:200], re.I):
                    continue
                if re.search(r'UPDLOCK|HOLDLOCK|SERIALIZABLE', c.group(0), re.I):
                    continue
                table = c.group('table')
                after = sql[c.end():]
                if re.search(r'INSERT\s+(?:INTO\s+)?\[?' + c.group('schema') + r'\]?\.\[?' + table + r'\b', after, re.I):
                    if re.search(r'sp_getapplock', sql[:c.start()], re.I):
                        continue
                    out.append(('UNLOCKED-CHECK', f'{name} ({c.group("schema")}.{table})'))
    return sorted(set(out))


def main():
    found = findings()
    if '--update-baseline' in sys.argv:
        with open(BASELINE, 'w') as fh:
            fh.write('# Grandfathered by tools/idempotency_scan.py — only ever shrinks.\n'
                     '# Touching one of these? Give it its Idempotency line, fix its lock,\n'
                     '# then: python3 tools/idempotency_scan.py --update-baseline\n')
            for rule, name in found:
                fh.write(f'{rule} {name}\n')
        print(f'baseline: {len(found)} grandfathered findings written')
        return 0
    base = set()
    if os.path.exists(BASELINE) and '--all' not in sys.argv:
        for line in open(BASELINE):
            line = line.strip()
            if line and not line.startswith('#'):
                rule, _, name = line.partition(' ')
                base.add((rule, name))
    new = [(r, n) for r, n in found if (r, n) not in base]
    for rule, name in new:
        print(f'{rule:15} {name}')
    return 1 if new else 0


if __name__ == '__main__':
    sys.exit(main())
