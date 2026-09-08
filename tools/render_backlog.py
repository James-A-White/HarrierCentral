#!/usr/bin/env python3
"""Render docs/backlog.md into docs/backlog.html.

`docs/backlog.md` is the source of truth for the product backlog. This script
derives the published HTML snapshot from it, so the two cannot drift: edit the
markdown, run this, republish.

    python3 tools/render_backlog.py

The design (fonts, palette, layout, both themes) lives in
`tools/backlog_template.html` and is not generated — only the content is.
"""

import html
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MD = ROOT / "docs" / "backlog.md"
OUT = ROOT / "docs" / "backlog.html"
TEMPLATE = ROOT / "tools" / "backlog_template.html"

CHIP = {"Shipped": "c-ship", "Building": "c-build", "Next": "c-next", "Backlog": "c-back"}


def inline(text):
    """Markdown inline formatting → HTML. Escapes first, so content is safe."""
    out = html.escape(text, quote=False)
    out = re.sub(r"`([^`]+)`", r"<code>\1</code>", out)
    # Personas and roles are bolded in the markdown; they render as <em> because
    # the stylesheet gives .s-text em the role-name treatment.
    out = re.sub(r"\*\*(.+?)\*\*", r"<em>\1</em>", out)
    return out


def split_row(line):
    """Split a markdown table row, honouring `|` inside inline code spans."""
    cells, buf, in_code = [], "", False
    for ch in line.strip().strip("|"):
        if ch == "`":
            in_code = not in_code
        if ch == "|" and not in_code:
            cells.append(buf.strip())
            buf = ""
        else:
            buf += ch
    cells.append(buf.strip())
    return cells


def parse(md):
    """Parse the backlog markdown into personas + epics."""
    personas, epics = [], []
    epic = feature = None
    table_kind = None
    lines = md.split("\n")
    i = 0
    in_personas = False

    while i < len(lines):
        ln = lines[i]

        if ln.startswith("## Personas"):
            in_personas, epic = True, None
        elif m := re.match(r"^## (E\d+(?: · non-functional)?) — (.+)$", ln):
            in_personas = False
            epic = {"id": m.group(1), "title": m.group(2), "intent": "", "features": []}
            epics.append(epic)
            feature = None
        elif m := re.match(r"^### (E\d+\.[FG]\d+) · (.+)$", ln):
            feature = {"id": m.group(1), "name": m.group(2), "surfaces": [], "note": "", "rows": []}
            epic["features"].append(feature)
            table_kind = None
            # A surface line may follow immediately.
            if i + 1 < len(lines) and re.fullmatch(r"`[A-Za-z]+`(?: `[A-Za-z]+`)*", lines[i + 1].strip()):
                feature["surfaces"] = re.findall(r"`([A-Za-z]+)`", lines[i + 1])
                i += 1
        elif ln.startswith("> ") and feature is not None:
            feature["note"] = ln[2:].strip()
        elif ln.startswith("| ") and "---" not in ln:
            cells = split_row(ln)
            if in_personas:
                if cells[0] != "Persona":
                    personas.append(cells)
            elif feature is not None:
                if cells[0] == "ID":
                    table_kind = "req" if cells[2].startswith("Enforced") else "story"
                else:
                    feature["rows"].append((table_kind, cells))
        elif epic and not feature and ln.strip() and not ln.startswith(("---", "#", "|")):
            epic["intent"] = (epic["intent"] + " " + ln.strip()).strip()

        i += 1

    return personas, epics


def render(personas, epics):
    w = []
    a = w.append

    n_story = sum(len(f["rows"]) for e in epics for f in e["features"]
                  if not e["id"].endswith("non-functional"))
    n_req = sum(len(f["rows"]) for e in epics for f in e["features"]
                if e["id"].endswith("non-functional"))
    n_feat = sum(len(e["features"]) for e in epics)

    a('<div class="wrap">')
    a('<header class="mast">')
    a('  <div class="mast-rule"></div>')
    a('  <div class="eyebrow">Harrier Central · product backlog · rendered from docs/backlog.md</div>')
    a('  <h1>Harrier Central Product Backlog</h1>')
    a('  <p class="standfirst">Every epic, feature and user story across the five components — the '
      'Flutter mobile app, the Flutter admin portal, the Next.js public web, the Azure Functions shim '
      'and the SQL Server domain layer — plus the non-functional requirements that hold them together. '
      '<strong>Epics are organised by what a hasher is trying to do, not by which codebase serves it</strong>, '
      'because almost every feature here spans three surfaces at once.</p>')
    a('  <div class="meta-strip">')
    a(f'    <div><b>{len(epics)}</b> epics</div>')
    a(f'    <div><b>{n_feat}</b> features</div>')
    a(f'    <div><b>{n_story}</b> stories</div>')
    a(f'    <div><b>{n_req}</b> NFR requirements</div>')
    a(f'    <div><b>{len(personas)}</b> personas</div>')
    a('  </div>')
    a('  <div class="legend">')
    for label, cls, desc in [("Shipped", "c-ship", "in production"), ("Building", "c-build", "in flight now"),
                             ("Next", "c-next", "designed, not built"), ("Backlog", "c-back", "not yet designed")]:
        a(f'    <span class="legend-item"><span class="chip {cls}">{label}</span> {desc}</span>')
    a('  </div>')
    a('</header>')

    a('<section id="personas"><h2>Personas</h2>')
    a('<p class="sec-note">Six roles, each with a distinct mechanism behind it. The two that get confused '
      'most often are <em>mismanagement</em> and <em>kennel admin</em>: they are independent grantor '
      'bitfields on <code>HC.HasherKennelMap</code>, and a function is allowed if <em>either</em> grants it. '
      'Somebody can run Harrier Central for their kennel while holding no club office at all.</p>')
    a('<div class="personas">')
    for name, mech, desc in personas:
        a(f'  <div class="persona"><div class="persona-name">{inline(name).replace("<em>", "").replace("</em>", "")}'
          f'<span>{inline(mech).replace("<code>", "").replace("</code>", "")}</span></div>'
          f'<div class="persona-desc">{inline(desc)}</div></div>')
    a('</div></section>')

    a('<section id="index"><h2>Epics</h2>')
    n_prod = sum(1 for e in epics if not e["id"].endswith("non-functional"))
    a(f'<p class="sec-note">{n_prod} product epics and {len(epics) - n_prod} non-functional ones. '
      'IDs are stable — quote them when assigning work to an agent.</p>')
    a('<div class="index-grid">')
    for e in epics:
        eid = e["id"].split(" ")[0]
        rows = sum(len(f["rows"]) for f in e["features"])
        nfr = e["id"].endswith("non-functional")
        unit = f'{len(e["features"])} {"groups" if nfr else "features"} · {rows} {"requirements" if nfr else "stories"}'
        a(f'  <a class="idx" href="#{eid.lower()}"><span class="idx-id">{eid}</span>'
          f'<span class="idx-name">{inline(e["title"])}</span><span class="idx-count">{unit}</span></a>')
    a('</div></section>')

    for e in epics:
        eid = e["id"].split(" ")[0]
        a(f'<section class="epic" id="{eid.lower()}">')
        a('  <div class="epic-head">')
        a(f'    <div class="epic-id">{inline(e["id"])}</div>')
        a(f'    <h2 class="epic-title">{inline(e["title"])}</h2>')
        a(f'    <p class="epic-intent">{inline(e["intent"])}</p>')
        a('  </div>')
        for f in e["features"]:
            a('  <div class="feature">')
            a(f'    <div class="feature-head"><span class="feature-id">{f["id"]}</span>'
              f'<h3 class="feature-name">{inline(f["name"])}</h3>')
            if f["surfaces"]:
                a('      <span class="surfaces">'
                  + "".join(f'<span class="surf">{s}</span>' for s in f["surfaces"]) + '</span>')
            a('    </div>')
            if f["note"]:
                a(f'    <p class="feature-note">{inline(f["note"])}</p>')
            if f["rows"]:
                is_req = f["rows"][0][0] == "req"
                a('    <div class="reqs">' if is_req else '    <ul class="stories">')
                for kind, cells in f["rows"]:
                    rid = cells[0].strip("`")
                    body, third = cells[1], cells[2]
                    gap = ""
                    if m := re.search(r"\*\*⚠ Known gap:\*\*\s*(.+)$", body):
                        gap = m.group(1).strip()
                        body = body[: m.start()].strip()
                    if kind == "req":
                        a(f'      <div class="req"><span class="s-id">{rid}</span>'
                          f'<span class="req-what">{inline(body)}</span>'
                          f'<span class="req-how"><b>Enforced by</b> {inline(third)}</span></div>')
                    else:
                        status = third.strip("`")
                        row = (f'      <li class="story"><span class="s-id">{rid}</span>'
                               f'<span class="s-text">{inline(body)}</span>'
                               f'<span class="chip {CHIP.get(status, "c-back")}">{status}</span>')
                        if gap:
                            row += f'\n        <span class="gap">{inline(gap)}</span>'
                        a(row + '</li>')
                a('    </div>' if is_req else '    </ul>')
            a('  </div>')
        a('</section>')

    a('<footer>')
    a('  <p>Status reflects the working tree at <code>dev</code>. Epic and story IDs are stable — quote them '
      'when assigning work. Where a story is marked <em>Building</em> with a known gap, the gap names what is '
      'actually missing rather than what remains to polish.</p>')
    a('  <p>This page is generated from <code>docs/backlog.md</code> by <code>tools/render_backlog.py</code>. '
      'Edit the markdown, re-run the script, republish — never edit this file by hand.</p>')
    a('</footer>')
    a('</div>')
    return "\n".join(w)


def main():
    if not MD.exists():
        sys.exit(f"missing {MD}")
    personas, epics = parse(MD.read_text(encoding="utf-8"))
    if not epics:
        sys.exit("parsed no epics — has the markdown heading format changed?")
    OUT.write_text(TEMPLATE.read_text(encoding="utf-8") + render(personas, epics), encoding="utf-8")
    rows = sum(len(f["rows"]) for e in epics for f in e["features"])
    print(f"rendered {OUT.relative_to(ROOT)}: {len(epics)} epics, "
          f"{sum(len(e['features']) for e in epics)} features, {rows} rows, {len(personas)} personas")


if __name__ == "__main__":
    main()
