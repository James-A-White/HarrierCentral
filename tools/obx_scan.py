#!/usr/bin/env python3
"""tools/obx_scan.py — find Obx/GetX builders whose first reactive read may be skipped.

Usage: python3 tools/obx_scan.py mobile-app/lib portal/lib

Background: GetX throws "[Get] the improper use of a GetX has been detected"
when an Obx builder finishes without reading any Rx. The shape that shipped
(build 1397, 2026-09-24) was `Obx(() => Text(hashName ?? c.kennel.value…))`
— with hashName set, the read never ran. Same fault: an early return before
the first read, a ternary / `&&` / `||` that skips it, a `Map<String, Rx>`
lookup on a missing key. This lists the sites where that could happen; read
each one — it is a heuristic, not a type checker.

Heuristic, not a type checker: it extracts each builder body and looks at the
text BEFORE the first `.value` (or Rx-collection call). If that prefix holds an
early `return`, a `??`, a ternary, `&&`/`||`, or a nested closure, the site is
listed for a human read. Bodies with no reactive read at all are listed too.
"""
import re, sys, pathlib

RX_COLL = re.compile(r'\.(length|isEmpty|isNotEmpty|first|last|any|where|map|contains|containsKey|keys|values|entries|forEach|indexWhere|firstWhere|toList|join|asMap)\b')

def body_after(src, i):
    """src[i] == '(' ; return balanced text inside."""
    depth = 0; j = i
    while j < len(src):
        ch = src[j]
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
            if depth == 0:
                return src[i + 1:j]
        elif ch in "'\"":
            q = ch; j += 1
            while j < len(src) and src[j] != q:
                if src[j] == '\\': j += 1
                j += 1
        j += 1
    return src[i + 1:]

def strip_comments(s):
    return re.sub(r'//[^\n]*', '', s)

CB_RE = re.compile(r'\(([^()]*)\)\s*(=>|\{)')
KW_RE = re.compile(r'\b(if|for|while|switch|catch)\s*$')

def remove_callbacks(body):
    """Cut out `(args) => expr` and `(args) { … }` closures in argument position."""
    out=[]; i=0; n=len(body); last=''   # last non-space char emitted, and its trailing word
    while i<n:
        ch=body[i]
        if ch=='(':
            m=CB_RE.match(body, i)
            prev=''.join(out).rstrip()[-12:] if out else ''
            callback_pos = prev.endswith((':', ',', '(', '=', '=>'))
            if m and callback_pos and not KW_RE.search(prev):
                j=m.end()
                if m.group(2)=='{':
                    depth=1
                    while j<n and depth:
                        depth += (body[j]=='{') - (body[j]=='}'); j+=1
                else:
                    depth=0
                    while j<n:
                        c=body[j]
                        if c in '([{': depth+=1
                        elif c in ')]}':
                            if depth==0: break
                            depth-=1
                        elif c==',' and depth==0: break
                        j+=1
                out.append('<CB>'); i=j; continue
        out.append(ch); i+=1
    return ''.join(out)

def helper_body(src, name):
    m=re.search(r'\bWidget\s+'+re.escape(name)+r'\s*\(', src)
    if not m: return None
    k=src.find('{', m.end())
    if k<0: return None
    depth=0; j=k
    while j<len(src):
        depth += (src[j]=='{') - (src[j]=='}')
        j+=1
        if depth==0: break
    return src[k+1:j-1]

def scan(path):
    src = strip_comments(pathlib.Path(path).read_text())
    out = []
    for m in re.finditer(r'\b(Obx|GetX)(<[^>(]*>)?\s*\(', src):
        start = m.end() - 1
        body = strip_comments(body_after(src, start))
        line = src[:m.start()].count('\n') + 1
        # GetX(builder: (c) { ... }) — take from 'builder:' on
        if m.group(1) == 'GetX':
            k = body.find('builder:')
            if k < 0: continue
            body = body[k + 8:]
        # drop the builder's own header "() =>" / "() {" / "(c) {"
        body = re.sub(r'^\s*\([^)]*\)\s*(=>|\{)', '', body, count=1)
        d = re.match(r'\s*(_\w+)\s*\(', body)
        if d and '.value' not in body:
            hb = helper_body(src, d.group(1))
            if hb is not None: body = strip_comments(hb)
        body = remove_callbacks(body)
        vals = [x.start() for x in re.finditer(r'\.value\b', body)]
        colls = [x.start() for x in RX_COLL.finditer(body)]
        first = min(vals + colls) if (vals or colls) else None
        reasons = []
        if first is None:
            reasons.append('NO reactive read at all')
        else:
            prefix = body[:first]
            if re.search(r'\breturn\b[^;]*;', prefix): reasons.append('early return before first read')
            stmt = prefix[max(prefix.rfind(';'), prefix.rfind('{')) + 1:]
            if '??' in stmt: reasons.append('?? before first read')
            if re.search(r'\?[^.?:]*$', stmt) and ':' not in stmt.split('?')[-1]: reasons.append('ternary before first read')
            if '&&' in stmt or '||' in stmt: reasons.append('&&/|| before first read')
            if not vals and colls: reasons.append('collection call only')
        if reasons:
            head = '\n'.join(body.strip().split('\n')[:3])
            out.append((path, line, reasons, head))
    return out

roots = sys.argv[1:]
hits = []
n = 0
for root in roots:
    for f in pathlib.Path(root).rglob('*.dart'):
        if '.freezed.' in f.name or '.g.' in f.name: continue
        src = f.read_text()
        n += len(re.findall(r'\b(Obx|GetX)(<[^>(]*>)?\s*\(', src))
        hits += scan(f)
print(f'{n} Obx/GetX sites scanned, {len(hits)} flagged\n')
for path, line, reasons, head in sorted(hits):
    print(f'{path}:{line}  [{"; ".join(reasons)}]')
    for h in head.split('\n'): print('      ' + h.strip()[:110])
