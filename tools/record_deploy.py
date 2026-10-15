#!/usr/bin/env python3
"""Record a production deploy in LOG.DeployLog (never pruned), so an error's
time maps to the builds that were live then (tools/log_triage.py) — and,
when James asks, a major AI task (an audit, a sweep, a large refactor), so
the same timeline shows what was examined or changed and when.

Detail says what was done; Outcome is written AFTER the fact (--outcome <id>):
what the task found and what came of it, or what became of a deploy.

    python3 tools/record_deploy.py web 0.21.77
    python3 tools/record_deploy.py api 1.0.61+111
    python3 tools/record_deploy.py portal 2.0.87+778
    python3 tools/record_deploy.py app-ios 3.1.10+1480 --audience private
    python3 tools/record_deploy.py app-android 3.1.10+1480 --audience beta --detail "Play internal"
    python3 tools/record_deploy.py ai-task "SP security audit" --detail "All 289 HC6 SPs checked for …; 7 fixed, 3 to James"
    python3 tools/record_deploy.py --outcome 812 "3 gaps fixed in SP 73; 2 left for James (E14…)"
    python3 tools/record_deploy.py --list            # the last 20 rows (with ids)
    python3 tools/record_deploy.py --list ai-task    # AI tasks only

SP deploys record themselves (tools/deploy_hc6.sh). The dance-baby skill runs
this after each other deploy. The commit is HEAD; the time is now (or --at).
Uses the SQL credentials in .env, like the other tools.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
COMPONENTS = ("sp", "api", "web", "portal", "app-ios", "app-android", "ai-task")
AUDIENCES = ("production", "private", "beta", "store")


def env() -> dict[str, str]:
    e: dict[str, str] = {}
    for line in (ROOT / ".env").read_text().splitlines():
        m = re.match(r"\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$", line)
        if m:
            e[m.group(1)] = m.group(2).strip().strip('"').strip("'")
    return e


def sql(q: str) -> str:
    e = env()
    r = subprocess.run(
        ["sqlcmd", "-S", e["HC_SQL_SERVER"], "-d", e["HC_SQL_DATABASE"], "-U", e["HC_SQL_USERNAME"],
         "-P", e["HC_SQL_PASSWORD"], "-b", "-W", "-s", "|", "-Q", "SET NOCOUNT ON; " + q],
        capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f"sqlcmd failed: {r.stdout.strip()} {r.stderr.strip()}")
    return r.stdout


def lit(s: str | None) -> str:
    return "NULL" if s is None else "N'" + s.replace("'", "''") + "'"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("component", nargs="?", choices=COMPONENTS)
    ap.add_argument("version", nargs="?", help="the version; for ai-task, a short title (≤ 40 characters)")
    ap.add_argument("--audience", choices=AUDIENCES, default=None,
                    help="default production; none for ai-task")
    ap.add_argument("--detail", default=None)
    ap.add_argument("--at", default=None, help="UTC time if not now, e.g. 2026-10-15T08:56:28Z")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--outcome", nargs=2, metavar=("ID", "TEXT"),
                    help="write (or replace) the outcome of row ID, after the fact")
    a = ap.parse_args()

    if a.list:
        where = f"WHERE Component = {lit(a.component)} " if a.component else ""
        print(sql("SELECT TOP 20 id, CONVERT(varchar(19), DeployedAt, 120) AS DeployedAtUtc, Component, Version, "
                  "GitCommit, Audience, LEFT(Detail, 70) AS Detail, LEFT(Outcome, 70) AS Outcome "
                  f"FROM LOG.DeployLog {where}ORDER BY DeployedAt DESC"))
        return 0
    if a.outcome:
        row_id, text = a.outcome
        if not row_id.isdigit():
            ap.error("--outcome takes the row id from --list")
        if not 1 <= len(text.strip()) <= 2000:
            ap.error("an outcome is 1-2000 characters")
        n = sql(f"UPDATE LOG.DeployLog SET Outcome = {lit(text.strip())}, OutcomeAt = SYSDATETIMEOFFSET() "
                f"WHERE id = {int(row_id)}; SELECT @@ROWCOUNT;").split()
        if not n or n[-1] != "1":
            sys.exit(f"no row with id {row_id}")
        print(f"outcome written for row {row_id}")
        return 0
    if not (a.component and a.version):
        ap.error("component and version are required (or --list)")
    if a.component == "ai-task":
        if not 1 <= len(a.version.strip()) <= 40:
            ap.error("an ai-task title is 1-40 characters")
        if not a.detail:
            ap.error("an ai-task needs --detail: a short description of what was done")
        if a.audience:
            ap.error("an ai-task has no audience")
    else:
        if not re.fullmatch(r"[0-9A-Za-z.+-]{1,40}", a.version):
            ap.error(f"version {a.version!r} does not look like a version")
        a.audience = a.audience or "production"
    if a.at and not re.fullmatch(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2})?Z", a.at):
        ap.error("--at must be UTC like 2026-10-15T08:56:28Z")
    if a.detail and len(a.detail) > 400:
        ap.error("--detail is at most 400 characters")

    commit = subprocess.run(["git", "-C", str(ROOT), "rev-parse", "--short=8", "HEAD"],
                            capture_output=True, text=True).stdout.strip() or None
    at = f"'{a.at}'" if a.at else "SYSDATETIMEOFFSET()"
    sql("INSERT LOG.DeployLog (DeployedAt, Component, Version, GitCommit, Audience, Detail) VALUES "
        f"({at}, {lit(a.component)}, {lit(a.version)}, {lit(commit)}, {lit(a.audience)}, {lit(a.detail)})")
    new_id = sql("SELECT MAX(id) FROM LOG.DeployLog;").split()[-1]
    print(f"recorded row {new_id}: {a.component} {a.version} ({a.audience or 'no audience'}) at {a.at or 'now'}, commit {commit}"
          + (" — add its outcome later: --outcome " + new_id + ' "…"' if a.component == "ai-task" else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
