#!/usr/bin/env python3
"""Regenerate db/schema/tables/ from the LIVE database, one file per table.

    python3 tools/schema_dump.py           # rewrite the files that changed
    python3 tools/schema_dump.py --check   # exit 1 and list drift; writes nothing

Why: agents and people read db/schema/tables/ before writing an SP. Until
2026-10-13 those files were a one-off SSMS script from 2026-03-08; seven
months of run-once ALTERs later, 27 of 65 files lacked 293 live columns and
22 live tables had no file, and an SP review took column widths from them
and raised false alarms. These files are now GENERATED: never edit one by
hand. After ANY run-once script that changes a table (column, index,
constraint, trigger), run this and commit the result with the script.
A note about a column (deprecated, units, meaning) goes on the column in
the database as MS_Description (sp_addextendedproperty); it is printed
above the column here and so survives regeneration.

What a file holds (UTF-8, deterministic, no timestamp — an unchanged table
regenerates byte-identical):
  CREATE TABLE with every column: type, nullability, identity, computed
  definition, named DEFAULT; PRIMARY KEY / UNIQUE constraints; every index
  (unique, clustered, filtered, INCLUDE); FOREIGN KEYs; CHECK constraints;
  and each trigger's full definition (the sync UpdatedAt triggers matter:
  see claude.md "ALTER TABLE on synced tables").
It is REFERENCE, not a deploy script: the deploy never runs these files.

Scope: schemas HC, LOG, EXT, DomainValues. Not documented: the nightly
backup copies (HC_BACKUP*), DEV, UNUSED, the legacy schemas, and TSA
(defunct, claude.md 2026-10-13 — its old files are left untouched).
Also writes db/schema/tables/INDEX.md: one line per table.

Read-only against the database. Credentials from .env (HC_SQL_*).
"""
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'db', 'schema', 'tables')
SCHEMAS = ('HC', 'LOG', 'EXT', 'DomainValues')


def env():
    e = dict(os.environ)
    p = os.path.join(ROOT, '.env')
    if os.path.exists(p):
        for line in open(p, encoding='utf-8'):
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                k, v = line.split('=', 1)
                e.setdefault(k.strip(), v.strip().strip('"').strip("'"))
    return e


E = env()


def q_json(sql):
    """Run a FOR JSON query; sqlcmd splits long JSON over lines, so rejoin."""
    cmd = ['sqlcmd', '-S', E['HC_SQL_SERVER'], '-d', E['HC_SQL_DATABASE'],
           '-U', E['HC_SQL_USERNAME'], '-P', E['HC_SQL_PASSWORD'],
           '-h', '-1', '-y', '0', '-b', '-Q', 'SET NOCOUNT ON; ' + sql]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f'sqlcmd failed: {r.stderr or r.stdout}')
    txt = ''.join(line for line in r.stdout.splitlines())
    return json.loads(txt) if txt.strip() else []


SCH = ','.join(f"'{s}'" for s in SCHEMAS)

TABLES = q_json(f"""
SELECT t.object_id AS oid, s.name AS sch, t.name AS tbl
FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name IN ({SCH}) AND t.is_ms_shipped = 0
ORDER BY s.name, t.name FOR JSON PATH""")

COLS = q_json(f"""
SELECT c.object_id AS oid, c.column_id AS cid, c.name, ty.name AS typ,
       c.max_length AS len, c.precision AS prec, c.scale, c.is_nullable AS nul,
       c.is_identity AS ident, CAST(ic.seed_value AS BIGINT) AS seed,
       CAST(ic.increment_value AS BIGINT) AS incr,
       cc.definition AS computed, cc.is_persisted AS persisted,
       dc.name AS dname, dc.definition AS ddef
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.identity_columns ic ON ic.object_id = c.object_id AND ic.column_id = c.column_id
LEFT JOIN sys.computed_columns cc ON cc.object_id = c.object_id AND cc.column_id = c.column_id
LEFT JOIN sys.default_constraints dc ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
WHERE s.name IN ({SCH}) ORDER BY c.object_id, c.column_id FOR JSON PATH""")

IDX = q_json(f"""
SELECT i.object_id AS oid, i.index_id AS iid, i.name, i.type_desc AS kind,
       i.is_unique AS uniq, i.is_primary_key AS pk, i.is_unique_constraint AS uc,
       i.has_filter AS hasfilter, i.filter_definition AS filt,
       (SELECT c.name AS col, ic.is_descending_key AS dsc, ic.is_included_column AS inc,
               ic.key_ordinal AS ko, ic.index_column_id AS icid
        FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
        WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
        ORDER BY ic.key_ordinal, ic.index_column_id FOR JSON PATH) AS cols
FROM sys.indexes i JOIN sys.tables t ON t.object_id = i.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name IN ({SCH}) AND i.type > 0 AND i.is_hypothetical = 0
ORDER BY i.object_id, i.name FOR JSON PATH""")

FKS = q_json(f"""
SELECT fk.parent_object_id AS oid, fk.name, rs.name AS rsch, rt.name AS rtbl,
       fk.delete_referential_action_desc AS ondel, fk.is_disabled AS dis,
       (SELECT pc.name AS pcol, rc.name AS rcol FROM sys.foreign_key_columns fkc
        JOIN sys.columns pc ON pc.object_id = fkc.parent_object_id AND pc.column_id = fkc.parent_column_id
        JOIN sys.columns rc ON rc.object_id = fkc.referenced_object_id AND rc.column_id = fkc.referenced_column_id
        WHERE fkc.constraint_object_id = fk.object_id ORDER BY fkc.constraint_column_id FOR JSON PATH) AS cols
FROM sys.foreign_keys fk JOIN sys.tables t ON t.object_id = fk.parent_object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.tables rt ON rt.object_id = fk.referenced_object_id
JOIN sys.schemas rs ON rs.schema_id = rt.schema_id
WHERE s.name IN ({SCH}) ORDER BY fk.parent_object_id, fk.name FOR JSON PATH""")

CHKS = q_json(f"""
SELECT ck.parent_object_id AS oid, ck.name, ck.definition AS def, ck.is_disabled AS dis
FROM sys.check_constraints ck JOIN sys.tables t ON t.object_id = ck.parent_object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name IN ({SCH}) ORDER BY ck.parent_object_id, ck.name FOR JSON PATH""")

TRGS = q_json(f"""
SELECT tr.parent_id AS oid, tr.name, tr.is_disabled AS dis,
       OBJECT_DEFINITION(tr.object_id) AS def
FROM sys.triggers tr JOIN sys.tables t ON t.object_id = tr.parent_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name IN ({SCH}) ORDER BY tr.parent_id, tr.name FOR JSON PATH""")


DESCS = q_json(f"""
SELECT ep.major_id AS oid, ep.minor_id AS cid, CAST(ep.value AS NVARCHAR(4000)) AS txt
FROM sys.extended_properties ep JOIN sys.tables t ON t.object_id = ep.major_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE ep.class = 1 AND ep.name = 'MS_Description' AND s.name IN ({SCH})
ORDER BY ep.major_id, ep.minor_id FOR JSON PATH""")
DESC = {(d['oid'], d['cid']): d['txt'] for d in DESCS}


def by_oid(rows):
    d = {}
    for r in rows:
        d.setdefault(r['oid'], []).append(r)
    return d


C, I, F, K, T = by_oid(COLS), by_oid(IDX), by_oid(FKS), by_oid(CHKS), by_oid(TRGS)


def coltype(c):
    t = c['typ']
    if t in ('nvarchar', 'nchar'):
        return f"[{t}]({'max' if c['len'] == -1 else c['len'] // 2})"
    if t in ('varchar', 'char', 'varbinary', 'binary'):
        return f"[{t}]({'max' if c['len'] == -1 else c['len']})"
    if t in ('decimal', 'numeric'):
        return f"[{t}]({c['prec']}, {c['scale']})"
    if t in ('datetime2', 'datetimeoffset', 'time'):
        return f"[{t}]({c['scale']})"
    return f'[{t}]'


def col_line(c):
    if c.get('computed'):
        s = f"\t[{c['name']}] AS {c['computed']}"
        return s + (' PERSISTED' if c.get('persisted') else '')
    s = f"\t[{c['name']}] {coltype(c)}"
    if c.get('ident'):
        s += f" IDENTITY({c.get('seed', 1)},{c.get('incr', 1)})"
    s += ' NULL' if c.get('nul') else ' NOT NULL'
    if c.get('dname'):
        s += f" CONSTRAINT [{c['dname']}] DEFAULT {c['ddef']}"
    return s


def key_list(cols, included=False):
    out = []
    for x in json.loads(cols) if isinstance(cols, str) else (cols or []):
        if bool(x.get('inc')) != included:
            continue
        out.append(f"[{x['col']}]" + (' DESC' if x.get('dsc') else ''))
    return ', '.join(out)


def render(t):
    oid, sch, tbl = t['oid'], t['sch'], t['tbl']
    L = [f'-- {sch}.{tbl}' + (f"  -- {DESC[(oid, 0)]}" if (oid, 0) in DESC else ''),
         '-- GENERATED by tools/schema_dump.py from the live database. Do not edit by hand:',
         '-- run `python3 tools/schema_dump.py` after any change to this table and commit',
         '-- the result. Reference only; the deploy never runs this file.',
         '',
         f'CREATE TABLE [{sch}].[{tbl}] (']
    # A column's MS_Description (set with sp_addextendedproperty) is printed
    # above it: that is where a note like "DEPRECATED, never read" lives so
    # it survives regeneration.
    body = []
    for c in C.get(oid, []):
        line = col_line(c)
        d = DESC.get((oid, c['cid']))
        if d:
            line = '\n'.join('\t-- ' + x for x in d.splitlines()) + '\n' + line
        body.append(line)
    for i in I.get(oid, []):
        if i.get('pk') or i.get('uc'):
            kind = 'PRIMARY KEY' if i.get('pk') else 'UNIQUE'
            cl = ' CLUSTERED' if i['kind'] == 'CLUSTERED' else ' NONCLUSTERED'
            body.append(f"\tCONSTRAINT [{i['name']}] {kind}{cl} ({key_list(i.get('cols'))})")
    L.append(',\n'.join(body))
    L.append(');')
    L.append('GO')
    for i in I.get(oid, []):
        if i.get('pk') or i.get('uc'):
            continue
        u = 'UNIQUE ' if i.get('uniq') else ''
        kind = 'CLUSTERED' if i['kind'] == 'CLUSTERED' else 'NONCLUSTERED' if i['kind'] == 'NONCLUSTERED' else i['kind'].replace('_', ' ')
        s = f"CREATE {u}{kind} INDEX [{i['name']}] ON [{sch}].[{tbl}] ({key_list(i.get('cols'))})"
        inc = key_list(i.get('cols'), included=True)
        if inc:
            s += f' INCLUDE ({inc})'
        if i.get('hasfilter'):
            s += f" WHERE {i['filt']}"
        L.append(s + ';')
    for fk in F.get(oid, []):
        cols = fk.get('cols') or []
        pc = ', '.join(f"[{x['pcol']}]" for x in cols)
        rc = ', '.join(f"[{x['rcol']}]" for x in cols)
        s = (f"ALTER TABLE [{sch}].[{tbl}] ADD CONSTRAINT [{fk['name']}] FOREIGN KEY ({pc}) "
             f"REFERENCES [{fk['rsch']}].[{fk['rtbl']}] ({rc})")
        if fk.get('ondel') and fk['ondel'] != 'NO_ACTION':
            s += f" ON DELETE {fk['ondel'].replace('_', ' ')}"
        L.append(s + (';  -- DISABLED' if fk.get('dis') else ';'))
    for ck in K.get(oid, []):
        L.append(f"ALTER TABLE [{sch}].[{tbl}] ADD CONSTRAINT [{ck['name']}] CHECK {ck['def']};"
                 + ('  -- DISABLED' if ck.get('dis') else ''))
    if len(L) and L[-1] != 'GO':
        L.append('GO')
    for tr in T.get(oid, []):
        L.append('')
        L.append(f"-- Trigger [{sch}].[{tr['name']}]" + ('  (DISABLED)' if tr.get('dis') else ''))
        L.append((tr.get('def') or '-- (definition not readable)').replace('\r\n', '\n').rstrip())
        L.append('GO')
    return '\n'.join(L).rstrip() + '\n'


def index_md():
    L = ['# Table definitions', '',
         'GENERATED by `tools/schema_dump.py` from the live database — one file per',
         'table in this folder. Do not edit by hand; after any change to a table run',
         '`python3 tools/schema_dump.py` and commit the result with the change.',
         '`python3 tools/schema_dump.py --check` lists drift (exit 1).', '',
         f"Schemas: {', '.join(SCHEMAS)}. Not documented: backup copies, DEV, UNUSED,",
         'legacy schemas, and TSA (defunct; its old files are left as they were).', '',
         '| Table | Columns | Indexes | Triggers |', '|---|---|---|---|']
    for t in TABLES:
        o = t['oid']
        L.append(f"| [{t['sch']}.{t['tbl']}]({t['sch']}.{t['tbl']}.Table.sql) | {len(C.get(o, []))} "
                 f"| {len(I.get(o, []))} | {len(T.get(o, []))} |")
    return '\n'.join(L) + '\n'


def main(argv):
    check = '--check' in argv
    want = {f"{t['sch']}.{t['tbl']}.Table.sql": render(t) for t in TABLES}
    want['INDEX.md'] = index_md()
    drift = []
    for name, text in sorted(want.items()):
        p = os.path.join(OUT, name)
        cur = None
        if os.path.exists(p):
            raw = open(p, 'rb').read()
            try:
                cur = raw.decode('utf-8')
            except UnicodeDecodeError:
                cur = None
        if cur != text:
            drift.append(('NEW    ' if not os.path.exists(p) else 'CHANGED') + ' ' + name)
            if not check:
                with open(p, 'w', encoding='utf-8', newline='\n') as fh:
                    fh.write(text)
    in_scope = tuple(s + '.' for s in SCHEMAS)
    for name in sorted(os.listdir(OUT)):
        if name.endswith('.Table.sql') and name.startswith(in_scope) and name not in want:
            drift.append('GONE    ' + name + '  (table no longer exists)')
            if not check:
                os.remove(os.path.join(OUT, name))
    for d in drift:
        print(d)
    if check:
        return 1 if drift else 0
    print(f"{len(TABLES)} tables; {len(drift)} file(s) written or removed.")
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
