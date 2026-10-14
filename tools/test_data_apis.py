#!/usr/bin/env python3
"""Smoke tests for the kennels' Data APIs (E20.F1) — the three links on the
portal kennel editor's Developer tab.

    python3 tools/test_data_apis.py          # all three, verbose
    python3 -m unittest tools/test_data_apis.py

These call PRODUCTION over HTTP: PublicApi opens its own SQL connection, so
there is nothing to unit-test without a live database. They are read-only
(each call is one SELECT plus the HC5 procedure's own GeneralLog row).

Each test runs against both addresses a kennel may hold:
  - the live API:   https://harriercentralpublicapi.azurewebsites.net/api/PublicApi
  - the old host:   https://hcwebapi.azurewebsites.net/PublicApi, which must
                    302 to the live API (api/legacy-hcwebapi/, E20.F1.S2).

The kennel is chosen from the database: one with an API key, visible future
runs and attendance in the last year, so every endpoint has something to
return. Set HC_DATA_API_KENNEL=<public kennel id> to pin one. Its API key is
read from HC.Kennel.ExtApiKey with the SQL credentials in .env and is never
printed: every URL in a message is shown with ApiKey=<key>.

A wrong key does NOT give an HTTP error: the procedure answers 200 with an
{errorId, errorTitle …} row, so every test checks the body, not only the status.
"""
import json
import os
import re
import subprocess
import sys
import unittest
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIVE = "https://harriercentralpublicapi.azurewebsites.net/api/PublicApi"
LEGACY = "https://hcwebapi.azurewebsites.net/PublicApi"

# The query strings the portal's Developer tab builds
# (portal/lib/admin_pages/kennel_page_new/pages/kennel_developer_page/layout.dart).
FUTURE_LIST = dict(queryType="getEvents", numberOfRecords="1000", pastOrFuture="future",
                   sortOrder="ASC", fullDetails="0", weeksToDisplay="104")
NEXT_RUN = dict(queryType="getEvents", numberOfRecords="1", pastOrFuture="future",
                sortOrder="ASC", fullDetails="1", weeksToDisplay="104")
RUN_COUNTS = dict(queryType="getLeaderboard", numberOfRecords="10")


def _env():
    e = dict(os.environ)
    p = ROOT / ".env"
    if p.exists():
        for line in p.read_text().splitlines():
            m = re.match(r"\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$", line)
            if m and m.group(1) not in e:
                e[m.group(1)] = m.group(2).strip().strip('"').strip("'")
    return e


def _sql(e, q):
    r = subprocess.run(["sqlcmd", "-S", e["HC_SQL_SERVER"], "-d", e["HC_SQL_DATABASE"],
                        "-U", e["HC_SQL_USERNAME"], "-P", e["HC_SQL_PASSWORD"],
                        "-W", "-h", "-1", "-s", "|", "-Q", "SET NOCOUNT ON; " + q],
                       capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError("sqlcmd failed (are the SQL credentials in .env?)")
    return [l.strip() for l in r.stdout.splitlines() if l.strip()]


def _pick_kennel():
    """(short name, public id, api key) — the key is never printed."""
    e = _env()
    pinned = e.get("HC_DATA_API_KENNEL", "").strip().lower()
    if pinned and not re.fullmatch(r"[0-9a-f-]{36}", pinned):
        raise RuntimeError("HC_DATA_API_KENNEL must be a public kennel id")
    where = (f"k.PublicKennelId = '{pinned}'" if pinned else
             """EXISTS (SELECT 1 FROM HC.Event f WHERE f.KennelId = k.id AND f.deleted = 0
                          AND f.IsVisible = 1 AND f.EventStartDateTimeGmt > SYSDATETIMEOFFSET())""")
    rows = _sql(e, f"""
        SELECT TOP 1 k.KennelShortName + '|' + LOWER(CAST(k.PublicKennelId AS NVARCHAR(40))) + '|' + k.ExtApiKey
        FROM HC.Kennel k
        OUTER APPLY (SELECT COUNT(*) n FROM HC.Event e JOIN HC.HasherEventMap m ON m.EventId = e.id
                     WHERE e.KennelId = k.id AND m.AttendenceState >= 20
                       AND e.EventStartDateTimeGmt > DATEADD(year, -1, SYSDATETIMEOFFSET())) a
        WHERE k.deleted = 0 AND LEN(k.ExtApiKey) > 20 AND {where}
        ORDER BY a.n DESC""")
    if not rows:
        raise RuntimeError("no kennel with an API key and future runs found")
    short, pub, key = rows[0].split("|", 2)
    return short, pub, key


def _redact(url):
    return re.sub(r"(?i)(apikey=)[^&]+", r"\1<key>", url)


class DataApiTests(unittest.TestCase):
    """One test per Developer-tab link, each on the live and the old address."""

    @classmethod
    def setUpClass(cls):
        cls.kennel, cls.public_id, cls.key = _pick_kennel()

    def _get(self, base, params):
        """GET and parse; returns the first rowset. Follows the old host's 302."""
        q = dict(PublicKennelId=self.public_id, ApiKey=self.key, **params)
        url = base + "?" + urllib.parse.urlencode(q)
        shown = _redact(url)
        req = urllib.request.Request(url, headers={"Origin": "https://example.org"})
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                status, final, body = r.status, r.geturl(), r.read()
                cors = r.headers.get("Access-Control-Allow-Origin")
        except urllib.error.HTTPError as err:
            self.fail(f"{shown} → HTTP {err.code}: {err.read()[:200]!r}")
        self.assertEqual(status, 200, shown)
        if base == LEGACY:
            self.assertTrue(final.startswith(LIVE), f"{shown} did not redirect to the live API (ended at {_redact(final)})")
        # A browser on a kennel's site reads the answer only with this header.
        self.assertEqual(cors, "*", f"{shown}: no Access-Control-Allow-Origin: *")
        try:
            data = json.loads(body)
        except ValueError:
            self.fail(f"{shown} did not return JSON: {body[:200]!r}")
        self.assertIsInstance(data, list, shown)
        self.assertGreaterEqual(len(data), 1, f"{shown}: no rowset")
        rows = data[0]
        self.assertIsInstance(rows, list, shown)
        # The procedure reports a refused key or a bad call as a 200 with an error row.
        if rows and "errorId" in rows[0]:
            self.fail(f"{shown} answered an error: {rows[0].get('errorTitle')} — {rows[0].get('errorUserMessage')}")
        return rows

    def test_future_event_list(self):
        """'API for <kennel> future event list': every future run, oldest first."""
        for base in (LIVE, LEGACY):
            with self.subTest(host=base):
                rows = self._get(base, FUTURE_LIST)
                self.assertGreaterEqual(len(rows), 1, f"{self.kennel} has future runs but the list is empty")
                # eventStartDatetime is the kennel's wall clock (often with a spurious
                # +00:00, /hc-event-datetimes), so compare dates with a day's slack.
                yesterday = (datetime.now(timezone.utc) - timedelta(days=1)).date().isoformat()
                starts = [r["eventStartDatetime"][:19] for r in rows]
                for r in rows:
                    self.assertEqual(r.get("publicKennelId"), self.public_id, "a run from another kennel")
                    for k in ("publicEventId", "eventName", "eventStartDatetime"):
                        self.assertIn(k, r)
                    self.assertGreaterEqual(r["eventStartDatetime"][:10], yesterday, f"past run in the future list: {r['eventStartDatetime']}")
                self.assertEqual(starts, sorted(starts), "future list not in ascending order")

    def test_next_run(self):
        """'API call to return next run': one run, the first of the future list, with full details."""
        future = self._get(LIVE, FUTURE_LIST)
        self.assertGreaterEqual(len(future), 1, f"{self.kennel} has no future runs, so there is no next run to check")
        first = future[0]
        for base in (LIVE, LEGACY):
            with self.subTest(host=base):
                rows = self._get(base, NEXT_RUN)
                self.assertEqual(len(rows), 1, "next run should be exactly one run")
                run = rows[0]
                self.assertEqual(run.get("publicKennelId"), self.public_id)
                self.assertEqual(run["eventStartDatetime"], first["eventStartDatetime"], "next run is not the earliest future run")
                # fullDetails=1 adds the price and tag columns the short list leaves out.
                for k in ("formattedMemberPrice", "formattedNonMemberPrice", "currencySymbol"):
                    self.assertIn(k, run, f"fullDetails=1 but no {k}")

    def test_run_counts(self):
        """'API call to return run counts': the leaderboard, top 10 hashers by runs."""
        for base in (LIVE, LEGACY):
            with self.subTest(host=base):
                rows = self._get(base, RUN_COUNTS)
                self.assertGreaterEqual(len(rows), 1, f"{self.kennel}: the leaderboard is empty (a kennel with no attendance recorded has none)")
                self.assertLessEqual(len(rows), 10, "numberOfRecords=10 returned more than 10")
                for r in rows:
                    self.assertIn("hashName", r)
                    for k in ("totalRuns", "ytdRuns", "last365dayRuns"):
                        self.assertIsInstance(r.get(k), int, f"{k} is not a number: {r.get(k)!r}")
                        self.assertGreaterEqual(r[k], 0)


if __name__ == "__main__":
    unittest.main(argv=sys.argv[:1] + ["-v"] + sys.argv[1:])
