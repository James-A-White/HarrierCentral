#!/usr/bin/env python3
"""Promote each run's best PackTrack to its official trail (E5.F6.S6).

James, 2026-10-03: "For every run that has a pack track can you select the
best quality pack track, it might be the one with the most points, to promote
to being the official pack track for that run."

Only runs that have ENDED and have NO official trail yet. Nothing is
overwritten; every promoted lane carries source "auto" so the lot can be
found (and removed) again.

What "best" means here:
  * a runner's PLAIN GPS fixes (marks, trail-type tags, photo pins ignored),
    inside any admin trim (AST/AEN) and before their first On Inn (OIN);
  * fixes worse than +-30 m dropped, and any fix implying > 6 m/s from the
    last kept one (a car, a GPS jump);
  * the longest unbroken stretch: a gap of > 10 min or a jump of > 300 m
    splits the track, so the drive home or a forgotten Stop is cut off;
  * plausible: >= 30 fixes, 1-30 km, 15 min - 5 h, and starting within 1 km
    of the run's start (where the run has one);
  * then the MOST FIXES wins (James's suggestion), per declared trail type
    (TRL::n, Normal when undeclared) — a walker's track never becomes the
    Normal trail.

The lane is written exactly as hcapp_setOfficialTrail writes one: points
[lat, lon, t] (t = ms after the first point), thinned to one per 5 m, in
HC.Event.OfficialTrailGzip (COMPRESSed lanes JSON) + OfficialTrailInfo. A
trail-only UPDATE is not stamped by the Event trigger, so no phone re-syncs.

Usage:
  python3 tools/promote_best_tracks.py              # dry run: report only
  python3 tools/promote_best_tracks.py --write-sql OUT.sql   # also emit the SQL
Then run OUT.sql with sqlcmd (James's call). Tracks are cached under
--cache (default: a temp dir) so a re-run does not refetch.
"""
from __future__ import annotations

import argparse
import gzip
import json
import math
import os
import re
import subprocess
import sys
import tempfile
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
API = "https://harriercentralpublicapi.azurewebsites.net/api/GetPositions"

MAX_ACC_M = 30.0
MAX_SPEED_MS = 6.0
SPLIT_GAP_MS = 10 * 60 * 1000
SPLIT_JUMP_M = 300.0
MIN_FIXES = 30
MIN_M, MAX_M = 1000.0, 30000.0
MIN_MS, MAX_MS = 15 * 60 * 1000, 5 * 3600 * 1000
NEAR_START_M = 1000.0
THIN_M = 5.0


def env() -> dict[str, str]:
    out = dict(os.environ)
    for line in (ROOT / ".env").read_text().splitlines():
        m = re.match(r"\s*([A-Z_][A-Z0-9_]*)\s*=\s*(.*)\s*$", line)
        if m and m.group(1) not in out:
            out[m.group(1)] = m.group(2).strip().strip('"').strip("'")
    return out


def sql_rows(e: dict[str, str], query: str) -> list[list[str]]:
    r = subprocess.run(
        ["sqlcmd", "-S", e["HC_SQL_SERVER"], "-d", e["HC_SQL_DATABASE"],
         "-U", e["HC_SQL_USERNAME"], "-h", "-1", "-W", "-s", "\t", "-y", "0",
         "-Q", "SET NOCOUNT ON; " + query],
        capture_output=True, text=True, env={**e, "SQLCMDPASSWORD": e["HC_SQL_PASSWORD"]},
        check=True)
    return [ln.split("\t") for ln in r.stdout.splitlines() if ln.strip()]


def api_key() -> str:
    s = (ROOT / "mobile-app/lib/util/constants.dart").read_text()
    return re.search(r"GET_POSITIONS_API_KEY\s*=\s*'([^']+)'", s).group(1)


def fetch(event_id: str, key: str, cache: Path) -> dict:
    f = cache / f"{event_id}.json"
    if f.exists():
        return json.loads(f.read_text())
    req = urllib.request.Request(
        API, method="POST",
        data=json.dumps({"eventId": event_id, "AfterTimestamp": "0" * 19, "users": []}).encode(),
        headers={"X-Api-Key": key, "content-type": "application/json",
                 "accept-encoding": "identity"})
    last = None
    for _ in range(4):
        try:
            with urllib.request.urlopen(req, timeout=90) as r:
                body = r.read()
            if body[:2] == b"\x1f\x8b":  # the API gzips whatever it is asked
                body = gzip.decompress(body)
            d = json.loads(body)
            f.write_text(json.dumps(d))
            return d
        except Exception as ex:  # flaky network: retry
            last = ex
    raise RuntimeError(f"GetPositions {event_id}: {last}")


def hav(a_lat, a_lon, b_lat, b_lon) -> float:
    r = 6371000.0
    p1, p2 = math.radians(a_lat), math.radians(b_lat)
    dp, dl = p2 - p1, math.radians(b_lon - a_lon)
    h = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(min(1.0, math.sqrt(h)))


def lane_of(ps: list[dict]) -> int:
    lane = 3
    for p in ps:
        t = (p.get("type") or "").strip()
        if t.startswith("TRL::"):
            v = t[5:].split("::")[0].split("~")[0].strip()
            if v.isdigit():
                lane = int(v)
    return lane


def best_stretch(ps: list[dict]) -> list[dict]:
    """The runner's longest clean, unbroken stretch of plain fixes."""
    ps = sorted(ps, key=lambda p: p["timestampMs"])
    keys = [((p.get("type") or "").split("::")[0]) for p in ps]
    # Admin trim: keep between the last AST and the first AEN after it.
    if "AST" in keys:
        i = len(keys) - 1 - keys[::-1].index("AST")
        ps, keys = ps[i:], keys[i:]
    if "AEN" in keys:
        i = keys.index("AEN")
        ps, keys = ps[:i], keys[:i]
    if "OIN" in keys:
        i = keys.index("OIN")
        ps, keys = ps[:i], keys[:i]
    plain = [p for p, k in zip(ps, keys) if k == "" and p.get("lat") is not None]
    kept: list[dict] = []
    for p in plain:
        if (p.get("acc") or 0) > MAX_ACC_M:
            continue
        if kept:
            q = kept[-1]
            dt = (p["timestampMs"] - q["timestampMs"]) / 1000.0
            if dt <= 0:
                continue
            d = hav(q["lat"], q["lng"], p["lat"], p["lng"])
            if d / dt > MAX_SPEED_MS and d > 25:
                continue
        kept.append(p)
    segs: list[list[dict]] = []
    for p in kept:
        if segs:
            q = segs[-1][-1]
            if (p["timestampMs"] - q["timestampMs"] > SPLIT_GAP_MS
                    or hav(q["lat"], q["lng"], p["lat"], p["lng"]) > SPLIT_JUMP_M):
                segs.append([p])
                continue
            segs[-1].append(p)
        else:
            segs.append([p])
    return max(segs, key=len) if segs else []


def length_m(seg: list[dict]) -> float:
    return sum(hav(a["lat"], a["lng"], b["lat"], b["lng"]) for a, b in zip(seg, seg[1:]))


def lane_points(seg: list[dict]) -> list[list[float]]:
    t0 = seg[0]["timestampMs"]
    out, last = [], None
    for i, p in enumerate(seg):
        if last is not None and i < len(seg) - 1 and hav(last["lat"], last["lng"], p["lat"], p["lng"]) < THIN_M:
            continue
        out.append([round(p["lat"], 5), round(p["lng"], 5), int(p["timestampMs"] - t0)])
        last = p
    return out


def judge(user: dict, start: tuple[float, float] | None) -> dict:
    seg = best_stretch(user["positions"])
    m = length_m(seg) if len(seg) > 1 else 0.0
    ms = seg[-1]["timestampMs"] - seg[0]["timestampMs"] if len(seg) > 1 else 0
    near = None
    if start and seg:
        head = seg[: max(1, len(seg) // 10)]
        near = min(hav(start[0], start[1], p["lat"], p["lng"]) for p in head)
    why = None
    if len(seg) < MIN_FIXES:
        why = "too few fixes"
    elif not (MIN_M <= m <= MAX_M):
        why = "implausible length"
    elif not (MIN_MS <= ms <= MAX_MS):
        why = "implausible duration"
    elif near is not None and near > NEAR_START_M:
        why = "not from the start"
    return {"id": user["id"], "lane": lane_of(user["positions"]), "seg": seg,
            "fixes": len(seg), "m": m, "ms": ms, "near": near, "why": why}


def sql_str(s: str) -> str:
    return "N'" + s.replace("'", "''") + "'"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--write-sql", metavar="OUT.sql")
    ap.add_argument("--cache", default=str(Path(tempfile.gettempdir()) / "hc_track_cache"))
    ap.add_argument("--limit", type=int, default=0)
    a = ap.parse_args()
    cache = Path(a.cache)
    cache.mkdir(parents=True, exist_ok=True)
    e = env()
    key = api_key()

    runs = sql_rows(e, """
        SELECT LOWER(CAST(ev.id AS NVARCHAR(40))), k.KennelShortName, ev.EventNumber,
               COALESCE(CAST(ev.SyncLatitude AS NVARCHAR(40)), ''), COALESCE(CAST(ev.SyncLongitude AS NVARCHAR(40)), '')
        FROM HC.Event ev JOIN HC.Kennel k ON k.id = ev.KennelId
        WHERE ev.OfficialTrailGzip IS NULL AND ev.deleted = 0 AND ISNULL(ev.removed, 0) = 0
          AND DATEADD(HOUR, 4, ev.EventStartDatetimeGmt) <= SYSDATETIMEOFFSET()
          AND EXISTS (SELECT 1 FROM HC.HasherEventMap h WHERE h.EventId = ev.id AND h.TrackPointCount > 0)
        ORDER BY ev.EventStartDatetimeGmt DESC""")
    if a.limit:
        runs = runs[: a.limit]
    names = {r[0]: r[1] for r in sql_rows(e, """
        SELECT LOWER(CAST(h.id AS NVARCHAR(40))), COALESCE(NULLIF(h.HashName, ''), h.FirstName, '')
        FROM HC.Hasher h WHERE EXISTS (SELECT 1 FROM HC.HasherEventMap m WHERE m.UserId = h.id AND m.TrackPointCount > 0)""")}

    stmts, chosen, reasons, failed = [], [], {}, []
    for n, (eid, kennel, num, lat, lon) in enumerate(runs, 1):
        try:
            d = fetch(eid, key, cache)
        except Exception as ex:
            failed.append((eid, str(ex)))
            continue
        start = None
        try:
            la, lo = float(lat), float(lon)
            if abs(la) <= 90 and abs(lo) <= 180 and not (la == 0 and lo == 0) and not (la == -2 and lo == -2):
                start = (la, lo)
        except ValueError:
            pass
        verdicts = [judge(u, start) for u in d.get("users", []) if u.get("positions")]
        for v in verdicts:
            if v["why"]:
                reasons[v["why"]] = reasons.get(v["why"], 0) + 1
        best: dict[int, dict] = {}
        for v in verdicts:
            if v["why"] is None and (v["lane"] not in best or (v["fixes"], v["m"]) > (best[v["lane"]]["fixes"], best[v["lane"]]["m"])):
                best[v["lane"]] = v
        if not best:
            continue
        lanes, infos = [], []
        now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        for lane, v in sorted(best.items()):
            pts = lane_points(v["seg"])
            lanes.append({"type": lane, "points": pts})
            infos.append({"type": lane, "distanceM": round(v["m"]), "points": len(pts), "source": "auto",
                          "sourceRef": names.get(v["id"], ""), "setAt": now})
            chosen.append((kennel, num, lane, names.get(v["id"], "?"), v["fixes"], v["m"], v["ms"],
                           len([x for x in verdicts if x["lane"] == lane])))
        trail = json.dumps({"lanes": lanes}, separators=(",", ":"))
        info = json.dumps({"lanes": infos}, separators=(",", ":"))
        stmts.append(
            f"UPDATE HC.Event SET OfficialTrailGzip = COMPRESS({sql_str(trail)}), OfficialTrailInfo = {sql_str(info)} "
            f"WHERE id = '{eid}' AND OfficialTrailGzip IS NULL;\n"
            f"IF @@ROWCOUNT = 1 INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES "
            f"('officialTrail', 'auto: best PackTrack promoted', '{eid}', "
            f"{sql_str('lanes=' + ','.join(str(l['type']) for l in lanes) + ' by=' + '|'.join(i['sourceRef'] for i in infos))}, SYSDATETIMEOFFSET());\n")
        if n % 50 == 0:
            print(f"  {n}/{len(runs)} runs read", file=sys.stderr)

    print(f"Runs with a PackTrack and no official trail: {len(runs)}")
    print(f"Runs that get an official trail:            {len(stmts)}  ({len(chosen)} lanes)")
    print(f"Runs left without one:                       {len(runs) - len(stmts) - len(failed)}")
    if failed:
        print(f"Could not be read: {len(failed)}  e.g. {failed[0]}")
    print("Runner tracks turned down:", ", ".join(f"{k} {v}" for k, v in sorted(reasons.items(), key=lambda x: -x[1])))
    km = sorted(c[5] / 1000 for c in chosen)
    if km:
        print(f"Chosen trail length: median {km[len(km)//2]:.1f} km, range {km[0]:.1f}-{km[-1]:.1f} km")
    lanes_n = {}
    for c in chosen:
        lanes_n[c[2]] = lanes_n.get(c[2], 0) + 1
    print("Lanes:", lanes_n)
    print("\nSample (kennel #run lane runner fixes km min of-candidates):")
    for c in chosen[:15]:
        print(f"  {c[0]:<10} #{c[1]:<5} lane {c[2]}  {c[3][:22]:<22} {c[4]:>5}  {c[5]/1000:5.1f}  {c[6]/60000:4.0f}  of {c[7]}")

    if a.write_sql:
        with open(a.write_sql, "w") as f:
            f.write("-- Run-once: promote each run's best PackTrack to its official trail (E5.F6.S6).\n"
                    "-- Generated by tools/promote_best_tracks.py. Only rows with no official trail are touched.\n"
                    "SET NOCOUNT ON;\nSET XACT_ABORT ON;\nBEGIN TRANSACTION;\n")
            f.writelines(stmts)
            f.write("COMMIT TRANSACTION;\n"
                    "SELECT COUNT(*) AS autoTrails FROM HC.Event WHERE OfficialTrailInfo LIKE '%\"source\":\"auto\"%';\n")
        print(f"\nSQL written: {a.write_sql} ({os.path.getsize(a.write_sql) // 1024} KB)")
    return 0


if __name__ == "__main__":
    if os.environ.get("HC_TRACE_HANG"):
        import faulthandler
        faulthandler.dump_traceback_later(int(os.environ["HC_TRACE_HANG"]), exit=True)
    sys.exit(main())
