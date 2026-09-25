#!/usr/bin/env python3
"""tools/button_text_scan.py — button labels that would wrap left-aligned.

A Text is left-aligned by default (TextAlign.start). Inside a button that
only shows once the label wraps onto a second line — a small phone, a large
text size — and then the lines hug the left edge. James's rule (2026-09-25):
wrapped button text is centred, every time.

Lists every Text that is the DIRECT `child:` / `label:` of an
ElevatedButton / TextButton / OutlinedButton (or their .icon forms) and has
no textAlign. Custom button widgets are not seen; keep their labels centred
by hand.

  python3 tools/button_text_scan.py          # list; exit 1 if any
  python3 tools/button_text_scan.py --fix    # add textAlign: TextAlign.center

Must print nothing (and exit 0) before a commit that touches buttons.
"""
import pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent / 'mobile-app' / 'lib'
BTN = re.compile(r'\b(ElevatedButton|TextButton|OutlinedButton)(\.icon)?\(')
TXT = re.compile(r'\s*(child|label)\s*:\s*(const\s+)?Text\(', re.S)

def skip_string(s,i):
    # s[i] is quote (maybe preceded by r). returns index after string
    raw = i>0 and s[i-1]=='r' and (i<2 or not (s[i-2].isalnum() or s[i-2]=='_'))
    q=s[i]
    triple = s[i:i+3]==q*3
    end = q*3 if triple else q
    j=i+(3 if triple else 1)
    while j<len(s):
        if not raw and s[j]=='\\': j+=2; continue
        if not raw and s[j]=='$' and j+1<len(s) and s[j+1]=='{':
            j=match(s,j+1,'{','}')+1; continue
        if s.startswith(end,j): return j+len(end)
        if not triple and s[j]=='\n': return j  # malformed, bail
        j+=1
    return j
def match(s,i,o,c):
    # s[i]==o ; return index of matching c
    d=0; j=i
    while j<len(s):
        ch=s[j]
        if ch in '"\'': j=skip_string(s,j); continue
        if s.startswith('//',j): j=s.find('\n',j); j=len(s) if j<0 else j; continue
        if s.startswith('/*',j): j=s.find('*/',j)+2; continue
        if ch in '([{': d+=1
        elif ch in ')]}':
            d-=1
            if d==0: return j
        j+=1
    return -1
def top_args(s,a,b):
    # split s[a:b] (inside parens) at depth-0 commas -> list of (start,end)
    parts=[]; d=0; j=a; st=a
    while j<b:
        ch=s[j]
        if ch in '"\'': j=skip_string(s,j); continue
        if s.startswith('//',j): j=s.find('\n',j); continue
        if s.startswith('/*',j): j=s.find('*/',j)+2; continue
        if ch in '([{': d+=1
        elif ch in ')]}': d-=1
        elif ch==',' and d==0: parts.append((st,j)); st=j+1
        j+=1
    parts.append((st,b)); return parts


def find(s):
    hits = []
    for m in BTN.finditer(s):
        ls = s.rfind('\n', 0, m.start()) + 1
        if s[ls:m.start()].lstrip().startswith('//'):
            continue
        op = m.end() - 1
        cp = match(s, op, '(', ')')
        if cp < 0:
            continue
        for (a, b) in top_args(s, op + 1, cp):
            tm = TXT.match(s, a)
            if not tm or tm.end() > b:
                continue
            top = tm.end() - 1
            tcp = match(s, top, '(', ')')
            if tcp < 0 or tcp > b:
                continue
            if not re.search(r'\btextAlign\s*:', s[top + 1:tcp]):
                hits.append((top, tcp))
    return hits


def fix(s, hits):
    for _, tcp in sorted(set(hits), key=lambda h: h[1], reverse=True):
        k = tcp - 1
        while s[k] in ' \t\n\r':
            k -= 1
        if s[k] == ',' and '\n' in s[k:tcp]:
            ls = s.rfind('\n', 0, k) + 1
            line = s[ls:k]
            indent = line[:len(line) - len(line.lstrip())]
            s = s[:k + 1] + '\n' + indent + 'textAlign: TextAlign.center,' + s[k + 1:]
        elif s[k] == ',':
            s = s[:k + 1] + ' textAlign: TextAlign.center' + s[k + 1:]
        else:
            s = s[:k + 1] + ', textAlign: TextAlign.center' + s[k + 1:]
    return s


def main():
    do_fix = '--fix' in sys.argv
    total = 0
    for p in sorted(ROOT.rglob('*.dart')):
        if p.name.endswith(('.g.dart', '.freezed.dart')):
            continue
        s = p.read_text()
        hits = find(s)
        if not hits:
            continue
        total += len(hits)
        if do_fix:
            p.write_text(fix(s, hits))
        else:
            for top, _ in hits:
                print(f'{p.relative_to(ROOT.parent)}:{s.count(chr(10), 0, top) + 1}')
    if do_fix:
        print(f'fixed {total}')
    sys.exit(1 if total and not do_fix else 0)


if __name__ == '__main__':
    main()
