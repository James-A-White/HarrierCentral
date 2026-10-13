#!/usr/bin/env python3
"""Compare every HC6 / TSA stored procedure with its contract JSON.

    python3 tools/contract_check.py            # whole repo; exit 1 if anything is off
    python3 tools/contract_check.py hcapp_x    # one object (name or substring)
    python3 tools/contract_check.py --json     # machine-readable report

What it checks, deterministically, from the SQL text alone:
  * every CREATE OR ALTER PROCEDURE has a contract file (functions and views
    are listed as "no contract required" unless one exists);
  * the contract parses as JSON and names the same object;
  * the parameter list matches: same names, same order, same SQL types;
    a parameter with no SQL default that the contract marks nullable is
    flagged (clients may omit it → unlogged 500, see CLAUDE.md);
  * contracts whose SP file no longer exists (orphans).

Rowsets are not derived from SQL here — read the SP. The checker says WHICH
contracts to open, not whether their rowsets are right.
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SP_DIRS = {
    'HC6': ['db/hc6/app', 'db/hc6/portal', 'db/hc6/public-web', 'db/hc6/internal'],
    'TSA': ['db/hc6/tsa'],
}
CONTRACT_DIR = {'HC6': 'db/contracts/hc6', 'TSA': 'db/contracts/tsa'}

CREATE_RE = re.compile(
    r'CREATE\s+OR\s+ALTER\s+(PROCEDURE|PROC|FUNCTION|VIEW)\s+'
    r'\[?(?P<schema>[A-Za-z0-9_]+)\]?\s*\.\s*\[?(?P<name>[A-Za-z0-9_]+)\]?',
    re.IGNORECASE)


def strip_comments(sql: str) -> str:
    sql = re.sub(r'/\*.*?\*/', ' ', sql, flags=re.S)
    sql = re.sub(r'--[^\n]*', ' ', sql)
    return sql


def split_top_level(text: str, sep=','):
    parts, depth, cur = [], 0, []
    for ch in text:
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
        if ch == sep and depth == 0:
            parts.append(''.join(cur))
            cur = []
        else:
            cur.append(ch)
    if ''.join(cur).strip():
        parts.append(''.join(cur))
    return parts


def norm_type(t: str) -> str:
    t = re.sub(r'\s+', ' ', t.strip().upper())
    t = re.sub(r'\s*\(\s*', '(', t)
    t = re.sub(r'\s*\)\s*', ')', t)
    t = re.sub(r'\s*,\s*', ',', t)
    t = t.replace('[', '').replace(']', '')
    return t


PARAM_RE = re.compile(
    r'^\s*@(?P<name>[A-Za-z0-9_]+)\s+(?:AS\s+)?(?P<rest>.+?)\s*$', re.S | re.I)


def parse_params(header: str):
    """header = text between the object name and the AS keyword."""
    header = header.strip()
    if header.startswith('('):            # CREATE PROC x ( @a int ) AS
        header = header[1:]
        if header.rstrip().endswith(')'):
            header = header.rstrip()[:-1]
    params = []
    for chunk in split_top_level(header):
        m = PARAM_RE.match(chunk)
        if not m:
            continue
        rest = m.group('rest')
        flags = {'output': False, 'readonly': False}
        for kw in ('OUTPUT', 'OUT', 'READONLY'):
            r = re.compile(r'\b' + kw + r'\b\s*$', re.I)
            while r.search(rest):
                rest = r.sub('', rest).rstrip()
                flags['output' if kw != 'READONLY' else 'readonly'] = True
        default = None
        eq = split_top_level(rest, '=')
        if len(eq) > 1:
            rest, default = eq[0], '='.join(eq[1:]).strip()
        params.append({'name': m.group('name'), 'type': norm_type(rest),
                       'default': default, **flags})
    return params


def parse_sql(path: str):
    raw = open(path, encoding='utf-8', errors='replace').read()
    sql = strip_comments(raw)
    m = CREATE_RE.search(sql)
    if not m:
        return None
    kind = m.group(1).upper()
    kind = 'PROCEDURE' if kind == 'PROC' else kind
    info = {'kind': kind, 'schema': m.group('schema'), 'name': m.group('name'),
            'file': os.path.relpath(path, ROOT), 'params': []}
    if kind == 'PROCEDURE':
        after = sql[m.end():]
        asm = re.search(r'(?<![A-Za-z0-9_@])AS(?![A-Za-z0-9_])', after)
        # the first standalone AS that is not inside parentheses
        depth, idx = 0, None
        for mm in re.finditer(r'[()]|(?<![A-Za-z0-9_@.])AS(?![A-Za-z0-9_])', after):
            tok = mm.group(0)
            if tok == '(':
                depth += 1
            elif tok == ')':
                depth -= 1
            elif depth == 0:
                idx = mm.start()
                break
        header = after[:idx] if idx is not None else (after[:asm.start()] if asm else '')
        header = re.sub(r'\bWITH\s+(EXECUTE\s+AS\s+\w+|RECOMPILE|ENCRYPTION)[^\n]*', '', header, flags=re.I)
        info['params'] = parse_params(header)
    return info


def load_contract(path: str):
    try:
        with open(path, encoding='utf-8') as fh:
            return json.load(fh), None
    except Exception as exc:  # noqa: BLE001
        return None, f'{type(exc).__name__}: {exc}'


def check_one(sp, contract_path):
    issues = []
    if not os.path.exists(contract_path):
        return ['MISSING contract'] if sp['kind'] == 'PROCEDURE' else []
    c, err = load_contract(contract_path)
    if err:
        return [f'INVALID JSON: {err}']
    if c.get('name') != sp['name']:
        issues.append(f"name mismatch: contract says {c.get('name')!r}")
    cps = c.get('parameters') or []
    sps = sp['params']
    cnames = [p.get('name', '').lstrip('@') for p in cps]
    snames = [p['name'] for p in sps]
    for n in snames:
        if n not in cnames:
            issues.append(f'param @{n} in SP, not in contract')
    for n in cnames:
        if n not in snames:
            issues.append(f'param @{n} in contract, not in SP')
    common = [n for n in snames if n in cnames]
    if common and [n for n in snames if n in cnames] != [n for n in cnames if n in snames]:
        issues.append('param order differs')
    for n in common:
        sp_p = next(p for p in sps if p['name'] == n)
        c_p = next(p for p in cps if p.get('name', '').lstrip('@') == n)
        if norm_type(str(c_p.get('type', ''))) != sp_p['type']:
            issues.append(f"@{n} type: SP {sp_p['type']} vs contract {c_p.get('type')}")
        if sp_p['default'] is None and c_p.get('nullable') is True and not sp_p['output']:
            issues.append(f'@{n} has no SQL default but contract says nullable (omitting it = unlogged 500)')
    if not isinstance(c.get('rowsets'), list):
        issues.append('no rowsets array')
    if sp['kind'] == 'PROCEDURE' and not c.get('description'):
        issues.append('no description')
    return issues


def main(argv):
    want_json = '--json' in argv
    filt = [a for a in argv if not a.startswith('--')]
    objects, orphans = [], []
    seen_contracts = set()
    for schema, dirs in SP_DIRS.items():
        for d in dirs:
            full = os.path.join(ROOT, d)
            if not os.path.isdir(full):
                continue
            for fn in sorted(os.listdir(full)):
                if not fn.lower().endswith('.sql'):
                    continue
                sp = parse_sql(os.path.join(full, fn))
                if not sp:
                    continue
                cpath = os.path.join(ROOT, CONTRACT_DIR[schema], sp['name'] + '.json')
                seen_contracts.add(os.path.abspath(cpath))
                sp['contract'] = os.path.relpath(cpath, ROOT)
                sp['has_contract'] = os.path.exists(cpath)
                sp['issues'] = check_one(sp, cpath)
                objects.append(sp)
    for schema, cdir in CONTRACT_DIR.items():
        full = os.path.join(ROOT, cdir)
        if not os.path.isdir(full):
            continue
        for fn in sorted(os.listdir(full)):
            if fn.endswith('.json') and not fn.startswith('_'):
                p = os.path.abspath(os.path.join(full, fn))
                if p not in seen_contracts:
                    orphans.append(os.path.relpath(p, ROOT))
    if filt:
        objects = [o for o in objects if any(f.lower() in o['name'].lower() for f in filt)]
        orphans = [o for o in orphans if any(f.lower() in o.lower() for f in filt)]

    bad = [o for o in objects if o['issues']]
    if want_json:
        print(json.dumps({'objects': objects, 'orphans': orphans}, indent=1))
    else:
        procs = [o for o in objects if o['kind'] == 'PROCEDURE']
        print(f"{len(objects)} objects ({len(procs)} procedures); "
              f"{sum(1 for o in procs if o['has_contract'])} procedures have a contract; "
              f"{len(bad)} with issues; {len(orphans)} orphan contracts")
        for o in bad:
            print(f"\n{o['schema']}.{o['name']}  [{o['file']}]")
            for i in o['issues']:
                print(f"   - {i}")
        fn_without = [o for o in objects if o['kind'] != 'PROCEDURE' and not o['has_contract']]
        if fn_without and not filt:
            print(f"\n{len(fn_without)} functions/views without a contract (none required): "
                  + ', '.join(o['name'] for o in fn_without))
        if orphans:
            print('\nOrphan contracts (no SP file):')
            for o in orphans:
                print(f'   - {o}')
    return 1 if (bad or orphans) else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
