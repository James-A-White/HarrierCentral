#!/usr/bin/env python3
"""sp_versions.py — what is actually running in the database, and from where.

Reads the deploy stamp that tools/deploy_hc6.sh puts on every HC6 object:

    -- HC-DEPLOY build=N at=<utc> commit=<head>[+dirty] changed=<sha|uncommitted> sha256=<12> file=<path>

and compares it with the repo. Read-only; uses the .env SQL credentials.

    python3 tools/sp_versions.py                 # the report
    python3 tools/sp_versions.py hcapp_addDownDown   # one object's stamp and state
    python3 tools/sp_versions.py --all           # every object's stamp

Sections, most serious first:
  EDITED OUTSIDE A DEPLOY   modified in the DB after its stamp: someone ALTERed
                            it by hand, and production differs from the repo
  NOT IN THE LAST DEPLOY    stamped with an older build: that file failed, or
                            the deploy stopped before reaching it, or the file
                            left the repo while the object stayed live
  DEPLOYED UNCOMMITTED      the file differed from HEAD when it was deployed,
                            so production runs code that is in no commit
  UNSTAMPED                 an HC6 object no stamped deploy has touched
  NOT IN THE DATABASE       in the repo, never deployed
  PENDING                   changed in the repo since it was deployed — normal
                            between releases; this is what the next deploy ships

Exit 1 when any of the first four is non-empty (once a stamped deploy exists),
0 otherwise. PENDING and NOT IN THE DATABASE are information, not faults.
"""

from __future__ import annotations

import hashlib
import re
import sys
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from log_triage import load_env, query_json  # noqa: E402

REPO = Path(__file__).resolve().parent.parent

# The folders deploy_hc6.sh reads (its globs are non-recursive, so archive/
# subfolders are not deployed and are not scanned here either).
SOURCE_DIRS = [
    REPO / "db" / "hc6" / "portal",
    REPO / "db" / "hc6" / "public-web",
    REPO / "db" / "hc6" / "app",
    REPO / "db" / "schema" / "functions",
]

CREATE = re.compile(
    r"^[ \t]*create[ \t]+or[ \t]+alter[ \t]+(?:procedure|proc|function|view|trigger)[ \t]+"
    r"\[?(\w+)\]?\.\[?(\w+)\]?",
    re.IGNORECASE | re.MULTILINE,
)
STAMP = re.compile(r"-- HC-DEPLOY (.*)")

# A deploy runs for a few minutes; a modify_date later than this after the
# stamp's own time was not that deploy.
OUTSIDE_DEPLOY_SLACK = timedelta(minutes=30)


@dataclass
class Live:
    name: str
    kind: str
    modified: datetime
    stamp: dict[str, str] | None


def parse_stamp(line: str | None) -> dict[str, str] | None:
    if not line:
        return None
    m = STAMP.search(line)
    if not m:
        return None
    return dict(kv.split("=", 1) for kv in m.group(1).split() if "=" in kv)


def load_live() -> dict[str, Live]:
    rows = query_json(load_env(), r"""
        SELECT o.name, o.type_desc AS kind,
               CONVERT(varchar(33), o.modify_date, 126) AS modified,
               CASE WHEN CHARINDEX('-- HC-DEPLOY ', m.definition) > 0
                    THEN LEFT(SUBSTRING(m.definition, CHARINDEX('-- HC-DEPLOY ', m.definition), 600),
                              CHARINDEX(CHAR(10), SUBSTRING(m.definition, CHARINDEX('-- HC-DEPLOY ', m.definition), 600) + CHAR(10)) - 1)
               END AS stamp
        FROM sys.objects o
        JOIN sys.sql_modules m ON m.object_id = o.object_id
        WHERE SCHEMA_NAME(o.schema_id) = 'HC6'
        FOR JSON PATH""")
    live = {}
    for r in rows:
        # Azure SQL runs in UTC, so modify_date is UTC.
        mod = datetime.fromisoformat(r["modified"]).replace(tzinfo=timezone.utc)
        live[r["name"].lower()] = Live(r["name"], r["kind"], mod,
                                       parse_stamp((r.get("stamp") or "").strip()))
    return live


def load_repo() -> dict[str, Path]:
    """HC6 object name (lower case) → the file that creates it."""
    repo = {}
    for d in SOURCE_DIRS:
        for f in sorted(d.glob("*.sql")):
            for schema, name in CREATE.findall(f.read_text(errors="replace")):
                if schema.upper() == "HC6":
                    repo[name.lower()] = f
    return repo


def sha12(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()[:12]


def stamp_time(s: dict[str, str]) -> datetime | None:
    try:
        return datetime.strptime(s["at"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
    except (KeyError, ValueError):
        return None


def describe(name: str, live: Live | None, file: Path | None) -> str:
    out = [name]
    if live is None:
        out.append("  not in the database")
    else:
        out.append(f"  {live.kind.lower()}, modified {live.modified:%Y-%m-%d %H:%M} UTC")
        if live.stamp:
            s = live.stamp
            out.append(f"  build {s.get('build')} at {s.get('at')} from commit {s.get('commit')}")
            out.append(f"  last changed in {s.get('changed')}; file {s.get('file')}")
        else:
            out.append("  no deploy stamp")
    if file is not None:
        rel = file.relative_to(REPO)
        if not (live and live.stamp):
            out.append(f"  repo {rel}: no stamp to compare it with")
        elif live.stamp.get("sha256") == sha12(file):
            out.append(f"  repo {rel}: same as deployed")
        else:
            out.append(f"  repo {rel}: changed since it was deployed")
    else:
        out.append("  no file in the repo creates it")
    return "\n".join(out)


def main(argv: list[str]) -> int:
    live = load_live()
    repo = load_repo()

    names = [a for a in argv if not a.startswith("--")]
    if names:
        for n in names:
            key = n.split(".")[-1].strip("[]").lower()
            print(describe(n, live.get(key), repo.get(key)))
        return 0

    stamped = {k: v for k, v in live.items() if v.stamp}
    builds = [int(v.stamp["build"]) for v in stamped.values() if v.stamp.get("build", "").isdigit()]
    latest = max(builds) if builds else None

    if "--all" in argv:
        for k in sorted(live):
            s = live[k].stamp
            print(f"{live[k].name:55} " + (f"build {s.get('build'):>4}  changed {s.get('changed')}" if s else "(no stamp)"))
        return 0

    if latest is None:
        print(f"No stamped deploy yet: {len(live)} HC6 objects, none stamped.")
        print("The next ./tools/deploy_hc6.sh stamps every object it deploys as build 1.")
        missing = sorted(set(repo) - set(live))
        if missing:
            print(f"\nNOT IN THE DATABASE ({len(missing)}): in the repo, never deployed")
            for k in missing:
                print(f"  {repo[k].relative_to(REPO)}")
        return 0

    head = [v.stamp for v in stamped.values() if v.stamp.get("build") == str(latest)]
    print(f"Build {latest}: deployed {head[0].get('at')} from commit {head[0].get('commit')} "
          f"— {len(head)} of {len(live)} HC6 objects carry it")

    outside, older, uncommitted, unstamped, pending = [], [], [], [], []
    for k, v in sorted(live.items()):
        if not v.stamp:
            unstamped.append(k)
            continue
        t = stamp_time(v.stamp)
        if t and v.modified > t + OUTSIDE_DEPLOY_SLACK:
            outside.append(k)
        if v.stamp.get("build") != str(latest):
            older.append(k)
        if v.stamp.get("changed") == "uncommitted":
            uncommitted.append(k)
        if k in repo and v.stamp.get("sha256") != sha12(repo[k]):
            pending.append(k)
    missing = sorted(set(repo) - set(live))

    def section(title: str, keys: list[str], line) -> None:
        if not keys:
            return
        print(f"\n{title} ({len(keys)})")
        for k in keys:
            print("  " + line(k))

    section("EDITED OUTSIDE A DEPLOY — production differs from the repo", outside,
            lambda k: f"{live[k].name}: modified {live[k].modified:%Y-%m-%d %H:%M}, stamped {live[k].stamp.get('at')}")
    section(f"NOT IN THE LAST DEPLOY — still on an older build than {latest}", older,
            lambda k: f"{live[k].name}: build {live[k].stamp.get('build')}"
                      + ("" if k in repo else " — no longer in the repo"))
    section("DEPLOYED UNCOMMITTED — production runs code that is in no commit", uncommitted,
            lambda k: f"{live[k].name} (build {live[k].stamp.get('build')})")
    section("UNSTAMPED — no stamped deploy has touched these", unstamped,
            lambda k: f"{live[k].name}" + ("" if k in repo else " — not in the repo"))
    section("NOT IN THE DATABASE — in the repo, never deployed", missing,
            lambda k: str(repo[k].relative_to(REPO)))
    section("PENDING — changed in the repo since deployed; the next deploy ships these", pending,
            lambda k: f"{live[k].name}: deployed {live[k].stamp.get('changed')}, "
                      f"repo {repo[k].relative_to(REPO)}")

    faults = outside or older or uncommitted or unstamped
    if not faults:
        print("\nEvery HC6 object is on build %d, deployed by the script, from committed code." % latest)
    return 1 if faults else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
