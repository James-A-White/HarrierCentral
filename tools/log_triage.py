#!/usr/bin/env python3
"""
tools/log_triage.py — "what is NEW in the logs?", not "what is in the logs?"

Usage:  python3 tools/log_triage.py [--since YYYY-MM-DD] [--days N] [--all]

Reads HC.ErrorLog (SPs, API shim, web, portal) and HC.ClientErrorLog (the
app's uploaded session logs) through sqlcmd with the .env credentials, the
same as log_sweep.sh. Read-only.

Every error is reduced to a FINGERPRINT — where it came from, what it says
with the numbers/ids/urls taken out, and (for a Dart stack) the first frame
in our own code, without its line number. One bug firing forty times on
nine phones is one fingerprint.

Each fingerprint is looked up in tools/known_errors.tsv:

    noise        expected; counted, never shown (unless it SPIKES)
    open         a known bug not yet fixed; shown as one line
    fixed:X      fixed in build/version X (e.g. 1396, web 0.21.74,
                 portal 2.0.86, 3.1.1+1396) or on date X (2026-09-24, for
                 an SP deploy). Seen at or after X ⇒ REGRESSED.

What prints, in order: REGRESSED, NEW, SPIKES, OPEN, and a one-line NOISE
total. NEW entries end with a ready-to-paste known_errors.tsv line.

Exit code 0 = nothing new or regressed; 1 = something to look at. That is
what a scheduled run keys a phone notification off.

See the /hc-monitoring skill for how to read what it finds.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
BASELINE = REPO / "tools" / "known_errors.tsv"

# A burst of one "noise" fingerprint across this many devices inside one hour
# is not noise: it is the Function app, the DB, or a bad release.
SPIKE_DEVICES = 5
SPIKE_WINDOW = timedelta(hours=1)


# ─── data access ────────────────────────────────────────────────────────────

def load_env() -> dict[str, str]:
    env = dict(os.environ)
    p = REPO / ".env"
    if p.exists():
        for line in p.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                env.setdefault(k.strip(), v.strip().strip('"').strip("'"))
    for k in ("HC_SQL_SERVER", "HC_SQL_DATABASE", "HC_SQL_USERNAME", "HC_SQL_PASSWORD"):
        if not env.get(k):
            sys.exit(f"ERROR: {k} not set (see .env.example)")
    return env


def query_json(env: dict[str, str], sql: str) -> list[dict]:
    """Runs a FOR JSON query. sqlcmd splits JSON output into ~2 KB rows;
    newlines inside JSON strings are escaped, so joining the rows is exact."""
    out = subprocess.run(
        ["sqlcmd", "-S", env["HC_SQL_SERVER"], "-d", env["HC_SQL_DATABASE"],
         "-U", env["HC_SQL_USERNAME"], "-P", env["HC_SQL_PASSWORD"],
         "-C", "-y", "0", "-Q", f"SET NOCOUNT ON; {sql}"],
        capture_output=True, text=True, check=True,
    ).stdout
    text = "".join(line.rstrip("\r\n") for line in out.splitlines()).strip()
    return json.loads(text) if text else []


# ─── fingerprinting ─────────────────────────────────────────────────────────

GUID = re.compile(r"\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b")
URL = re.compile(r"https?://([^/\s,'\")]+)(/[^/\s,'\")?]*)?[^\s,'\")]*")
HEX = re.compile(r"\b0x[0-9a-fA-F]+\b")
NUM = re.compile(r"\b\d+(\.\d+)?\b")
PRIVATE_FIELD = re.compile(r"@\d+")          # Dart's '_controller@1189359576'
PARENS_NAME = re.compile(r"\(([A-Z][^()]{0,40})\)")  # 'removed user (Rusty Hole)'
FRAME = re.compile(r"^#\d+\s+(\S.*?)\s+\((package:[^:)]+|dart:[^:)]+)")


def norm(msg: str, keep_parens: bool = True) -> str:
    s = msg.strip()
    s = GUID.sub("<id>", s)
    s = URL.sub(lambda m: f"<{m.group(1)}{m.group(2) or ''}>", s)
    s = HEX.sub("<hex>", s)
    s = PRIVATE_FIELD.sub("", s)
    s = NUM.sub("N", s)
    if not keep_parens:
        s = PARENS_NAME.sub("(…)", s)
    s = re.sub(r"\s+", " ", s)
    return s[:140]


def first_frame(stack: list[str]) -> str:
    """The first frame in OUR code, else the first outside dart:/flutter —
    the library that threw (flutter_map, get, …). No line numbers: they move
    with every edit and would make a fixed-then-reappearing bug look new."""
    fallback, framework = "", ""
    for line in stack:
        m = FRAME.match(line.strip())
        if not m:
            continue
        func, where = m.group(1), m.group(2)
        func = re.sub(r"\.<anonymous closure>", "", func)
        if where.startswith("package:harrier_central/"):
            return f"{where.split('/')[-1]} {func}"
        if not fallback and not where.startswith(("dart:", "package:flutter/")):
            fallback = f"{where.split('/')[0]} {func}"
        if not framework and where.startswith("package:flutter/"):
            framework = f"flutter {func}"
    return fallback or framework


# Transport failures fetching images, map tiles and blobs. The phone's link,
# not our code: one fingerprint per failure kind and host family, so forty
# tile servers and six error spellings do not become forty new rows.
NET_KINDS = [
    ("host lookup", r"Failed host lookup"),
    ("refused", r"Connection refused"),
    ("reset", r"Connection reset"),
    ("closed", r"Connection closed|connection errored"),
    ("abort", r"connection abort"),
    ("timed out", r"timed out"),
]


def host_family(text: str) -> str:
    h = re.search(r"(?:address = |host lookup: '|uri ?= ?<?https?://)([\w.-]+)", text)
    host = h.group(1) if h else ""
    if re.match(r"mt\d\.google\.com", host):
        return "google-tiles"
    if "blob.core.windows.net" in host:
        return "blob"
    if "fbsbx.com" in host or "fbcdn.net" in host:
        return "facebook"
    return host or "?"


def fp_client_entry(tag: str, text: str, stack: list[str], rest: list[str]) -> str | None:
    first = text.splitlines()[0] if text else ""
    if tag == "HTTP":
        body = next((l for l in rest if l.startswith("Body:")), "")
        resp = next((l for l in rest if l.startswith("Response:")), "Response:")
        qt = re.search(r'"queryType"\s*:\s*"([^"]+)"', body)
        q = qt.group(1) if qt else "?"
        if "transport failure" in first:
            return "app HTTP transport"
        if first.startswith("599"):
            return "app HTTP 599"
        code = re.search(r"(?:Retry \d+ failed: )?(\d{3})", first)
        code = code.group(1) if code else norm(first)[:40]
        # An empty 500 died in the shim or on the link, whatever was asked;
        # a 400 (or a 500 with a body) is an SP answering, and which SP matters.
        if code == "500" and not resp[len("Response:"):].strip():
            return "app HTTP 500 empty"
        return f"app HTTP {code} {q}"
    if re.search(r"SocketException|ClientException|DioException \[connection|HttpException: Connection", first):
        kind = next((k for k, pat in NET_KINDS if re.search(pat, first, re.I)), "other")
        return f"app NET {kind} {host_family(first)}"
    if (m := re.search(r"Invalid statusCode: (\d+)|status code of (\d+)", first)):
        code = m.group(1) or m.group(2)
        path = URL.search(first)
        where = host_family(first)
        if where == "blob" and path and path.group(2):
            where += path.group(2)
        return f"app IMG {code} {where}"
    return f"app {tag} {norm(first)} @ {first_frame(stack)}".rstrip(" @")


@dataclass
class Hit:
    fp: str
    when: datetime
    version: str        # build for app rows, HcVersion for everything else
    who: str            # device id (app) or user/page (server)
    sample: str


ENTRY = re.compile(r"^\[(\d{4}-\d{2}-\d{2}T[\d:.]+)\] \[ERROR\]\[([A-Z_]+)\] ?(.*)$")


def parse_client(rows: list[dict]) -> list[Hit]:
    hits: list[Hit] = []
    for r in rows:
        log = r.get("ErrorLog") or ""
        build = r.get("build") or "?"
        dev = r.get("DeviceId") or "?"
        for m in re.finditer(r'"kind"\s*:\s*"(crash|hang|diskWriteException)"', log):
            hits.append(Hit(f"app METRICKIT {m.group(1)}", _dt(r["LoggedAt"]), build, dev,
                            log[max(0, m.start() - 200):m.end() + 300]))
        for chunk in re.split(r"\n===\n?", log):
            lines = chunk.strip("\n").splitlines()
            if not lines:
                continue
            m = ENTRY.match(lines[0])
            if not m:
                continue
            ts, tag, msg = m.groups()
            rest = lines[1:]
            stack = [l for l in rest if l.lstrip().startswith("#")]
            fp = fp_client_entry(tag, msg, stack, rest)
            if fp:
                sample = "\n".join([lines[0]] + [l for l in rest if "harrier_central" in l][:4])
                hits.append(Hit(fp, _dt(ts), build, dev, sample[:900]))
    return hits


def parse_server(rows: list[dict]) -> list[Hit]:
    hits: list[Hit] = []
    for r in rows:
        ver = (r.get("HcVersion") or "").strip()
        proc = (r.get("ProcName") or "?").replace("[HC6].", "").strip("[]")
        name = r.get("ErrorName") or ""
        desc = r.get("ErrorDescription") or ""
        if ver.startswith("web "):
            src = "web"
        elif ver.startswith("portal "):
            src = "portal"
        elif ver == "HC6-API":
            src = "api"
            # The shim's ErrorName is just 'HC6 … Error: <proc>'; the exception
            # message is the part that says what went wrong.
            first = re.sub(r"^[\w.]+Exception \(<hex>\): ", "", norm(desc.splitlines()[0] if desc else ""))
            name = f"{name} — {first}"
        elif ver.startswith("AzureFunctions"):
            src = "func"
        else:
            src = "sp"
        fp = f"{src} {proc} {norm(name, keep_parens=False)}"
        who = r.get("userId") or r.get("string_1") or "?"
        sample = f"{name}\n{desc[:600]}" + (f"\npage: {r['string_1']}" if r.get("string_1") else "")
        hits.append(Hit(fp, _dt(r["createdAt"]), ver or "?", str(who), sample))
    return hits


def _dt(s: str) -> datetime:
    s = s.strip().replace(" ", "T", 1)
    s = re.sub(r"(\.\d{6})\d*", r"\1", s)
    s = re.sub(r"T?([+-]\d{2}:\d{2})$", r"\1", s.replace(" +", "+").replace(" -", "-"))
    d = datetime.fromisoformat(s)
    return d if d.tzinfo else d.replace(tzinfo=timezone.utc)


# ─── baseline ───────────────────────────────────────────────────────────────

@dataclass
class Known:
    status: str
    note: str


def load_baseline() -> dict[str, Known]:
    known: dict[str, Known] = {}
    if not BASELINE.exists():
        return known
    for line in BASELINE.read_text().splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) < 2:
            continue
        known[parts[0].strip()] = Known(parts[1].strip(), parts[2].strip() if len(parts) > 2 else "")
    return known


def ver_tuple(v: str) -> tuple[int, ...]:
    return tuple(int(x) for x in re.findall(r"\d+", v))


def after_fix(hit: Hit, fixed: str) -> bool:
    """fixed:2026-09-24 compares the hit's time; fixed:<version> its version.
    Versions compare as integer tuples, so '1396' against an app build and
    'web 0.21.74' against a web HcVersion. A version that cannot be compared
    (an unattributed '?' build) is never called a regression."""
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", fixed):
        return hit.when >= datetime.fromisoformat(fixed).replace(tzinfo=timezone.utc)
    want, got = ver_tuple(fixed), ver_tuple(hit.version)
    if not want or not got or "?" in hit.version:
        return False
    # An app build (1396) vs an SP-row HcVersion (3.1.1+1396): compare builds.
    if len(want) == 1 and len(got) > 1:
        got = got[-1:]
    # A label with fewer parts than the fix version is not a version of the
    # same thing: 'HC6-API' is (6,), which would otherwise out-rank
    # 'web 0.21.74'. Use fixed:<date> for fingerprints without versions.
    elif len(got) < len(want):
        return False
    return got >= want


def spikes(hits: list[Hit]) -> list[str]:
    """Each hour-long window in which one fingerprint hit SPIKE_DEVICES or more
    distinct devices, as 'MM-DD HH:MM (N devices)'. Windows are greedy and do
    not overlap, so a long outage reads as a few lines, not hundreds."""
    ts = sorted((h.when, h.who) for h in hits)
    out, i = [], 0
    while i < len(ts):
        t0 = ts[i][0]
        window = [(t, w) for t, w in ts[i:] if t - t0 <= SPIKE_WINDOW]
        devs = {w for _, w in window}
        if len(devs) >= SPIKE_DEVICES:
            out.append(f"{t0:%m-%d %H:%M} ({len(devs)} devices, {len(window)} hits)")
            i += len(window)
        else:
            i += 1
    return out


# ─── report ─────────────────────────────────────────────────────────────────

def summarise(fp: str, hits: list[Hit]) -> str:
    vers = sorted({h.version for h in hits}, key=ver_tuple)
    devs = {h.who for h in hits}
    first, last = min(h.when for h in hits), max(h.when for h in hits)
    return (f"  {len(hits):>4}×  {len(devs)} who  "
            f"{first:%m-%d %H:%M}→{last:%m-%d %H:%M}  on {', '.join(vers[-4:])}\n"
            f"        {fp}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--since", help="UTC date to start from (default: --days ago)")
    ap.add_argument("--days", type=int, default=3)
    ap.add_argument("--all", action="store_true", help="also list every noise fingerprint")
    ap.add_argument("--brief", metavar="FILE",
                    help="also write a few-line summary here, for a phone notification")
    a = ap.parse_args()
    since = a.since or (datetime.now(timezone.utc) - timedelta(days=a.days)).strftime("%Y-%m-%d")

    env = load_env()
    server = query_json(env, f"""
        SELECT CONVERT(varchar(40), createdAt, 127) createdAt, HcVersion, ProcName, ErrorName,
               LEFT(ErrorDescription, 1500) ErrorDescription, userId, string_1
        FROM HC.ErrorLog WHERE createdAt >= '{since}' FOR JSON PATH""")
    client = query_json(env, f"""
        SELECT CONVERT(varchar(40), c.LoggedAt, 127) LoggedAt, c.DeviceId,
               ISNULL(c.BuildNumber, ISNULL(d.BuildNumber, '?') + '?') build, c.ErrorLog
        FROM HC.ClientErrorLog c LEFT JOIN HC.Device d ON d.id = c.DeviceId
        WHERE c.LoggedAt >= '{since}'
          AND (c.ErrorLog LIKE '%[[]ERROR]%' OR c.ErrorLog LIKE '%"kind":"crash"%'
               OR c.ErrorLog LIKE '%"kind":"hang"%' OR c.ErrorLog LIKE '%diskWriteException%')
        FOR JSON PATH""")

    hits = parse_server(server) + parse_client(client)
    by_fp: dict[str, list[Hit]] = defaultdict(list)
    for h in hits:
        by_fp[h.fp].append(h)

    known = load_baseline()
    new, regressed, open_, noise, spiking = [], [], [], [], []
    for fp, hs in by_fp.items():
        k = known.get(fp)
        if k is None:
            new.append(fp)
        elif k.status.startswith("fixed:"):
            late = [h for h in hs if after_fix(h, k.status[6:])]
            if late:
                regressed.append((fp, late))
        elif k.status == "open":
            open_.append(fp)
        else:
            noise.append(fp)
            if (sp := spikes(hs)):
                spiking.append((fp, sp))

    order = lambda fps: sorted(fps, key=lambda f: -len(by_fp[f]))
    print(f"Log triage since {since} UTC — {len(server)} server rows, {len(client)} client sessions "
          f"with errors, {len(by_fp)} fingerprints ({len(known)} in {BASELINE.name})\n")

    if regressed:
        print(f"== REGRESSED — fixed, but seen at/after the fix ({len(regressed)}) ==")
        for fp, late in sorted(regressed, key=lambda x: -len(x[1])):
            print(summarise(fp, late) + f"   [{known[fp].status}] {known[fp].note}")
            print("        " + late[-1].sample.replace("\n", "\n        ")[:700] + "\n")
    if new:
        print(f"== NEW — not in the baseline ({len(new)}) ==")
        for fp in order(new):
            hs = by_fp[fp]
            print(summarise(fp, hs))
            print("        " + hs[-1].sample.replace("\n", "\n        ")[:700])
            print(f"        ↳ {fp}\topen\t<note>\n")
    if spiking:
        print(f"== SPIKES — noise on ≥{SPIKE_DEVICES} devices within an hour ({len(spiking)}) ==")
        for fp, windows in sorted(spiking, key=lambda x: -len(x[1])):
            print(f"        {fp}: " + "; ".join(windows))
        print()
    if open_:
        print(f"== OPEN — known, not yet fixed ({len(open_)}) ==")
        for fp in order(open_):
            print(summarise(fp, by_fp[fp]) + f"   — {known[fp].note}")
        print()
    total_noise = sum(len(by_fp[f]) for f in noise)
    print(f"== NOISE — {total_noise} hits across {len(noise)} known-noise fingerprints ==")
    if a.all:
        for fp in order(noise):
            print(summarise(fp, by_fp[fp]))
    if not (new or regressed or spiking):
        print("\nNothing new, nothing regressed.")
    if a.brief:
        short = lambda fp: fp if len(fp) <= 90 else fp[:87] + "…"
        lines = [f"HC logs since {since}: {len(new)} new, {len(regressed)} regressed, "
                 f"{len(spiking)} spiking"]
        lines += [f"↩ {short(fp)} ({len(late)}×)" for fp, late in regressed[:3]]
        lines += [f"+ {short(fp)} ({len(by_fp[fp])}×, {len({h.who for h in by_fp[fp]})} who)"
                  for fp in order(new)[:4]]
        lines += [f"⚡ {short(fp)}: {w[0]}" for fp, w in spiking[:2]]
        Path(a.brief).write_text("\n".join(lines) + "\n")
    return 1 if (new or regressed or spiking) else 0


if __name__ == "__main__":
    # 0 = quiet, 1 = something to look at, 2 = the triage itself could not
    # run (no network, bad credentials). A scheduled run must tell 2 from 0,
    # or an outage of the checker reads as a healthy day.
    try:
        sys.exit(main())
    except Exception as e:  # noqa: BLE001 — any failure to run is exit 2
        print(f"log_triage failed: {type(e).__name__}: {e}", file=sys.stderr)
        sys.exit(2)
