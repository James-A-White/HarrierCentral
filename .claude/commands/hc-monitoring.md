# HC — Continuous Monitoring & Rollout Health

> **Load this skill whenever James asks "how is the rollout looking", "any
> errors?", "check the logs", or before declaring a release healthy.** It is
> the read-only counterpart to `/hc-debugging` (which covers how logs get
> *onto* the server). Everything here is a query; nothing here changes state.

The system has no dashboard and no alerting. Monitoring means running the
sweep below against the production database and reading the result with the
interpretation rules in this file. The sweep is deliberately cheap enough to
run after every release and again a day or two later, when the logs have
actually arrived.

---

## The one command

```bash
./tools/log_sweep.sh [SINCE] [OUT_DIR]     # e.g. ./tools/log_sweep.sh 2026-09-07
```

Read-only. Uses the `.env` SQL credentials, same as `deploy_hc6.sh`. Default
window is the last three days. It prints six sections and dumps the raw client
logs to a text file whose path it names in section 4. Use the scratchpad
directory as `OUT_DIR` in a Claude session.

| Section | Source | What it answers |
|---|---|---|
| 1 Adoption | `HC.Device` | Who is on the new build, and which OS |
| 2 Server errors | `HC.ErrorLog` | Did any SP fail, and which |
| 3 Client sessions | `HC.ClientErrorLog` | How many sessions per build, how many clean |
| 4 Client `[ERROR]` lines | raw dump | Every client-side error, counted, per build |
| 5 Dart exceptions | raw dump | Stack traces — the real bugs, shown in full |
| 6 MetricKit kinds | raw dump | iOS crash/hang diagnostics vs routine metrics |

When you need to drill in, the raw dump is grep-able. Each session starts with
a `#### <LoggedAt> build=<N> dev=<DeviceId>` header and entries are separated
by `===`.

---

## Where the truth lives — and where it does not

Three tables. Know what each can and cannot tell you.

**`HC.ErrorLog`** — server-side, written by SPs. Every CATCH block and every
graceful error return logs here (CLAUDE.md mandates it). A quiet ErrorLog means
the *stored procedures* are healthy. It says nothing about the API shim.

**`HC.ClientErrorLog`** — one row per app *session*, uploaded on the boot
*after* the session (see `/hc-debugging`). Since 2026-08-30 the harvest flag
is on for every user, so this is the broad signal. It contains `[ERROR]`,
`[TRACE]`, `[STARTUP]` and `[METRICKIT]` entries. Retention is 90 days
(`nonApi_pruneLogs`).

**`HC.Device`** — current `Version`/`BuildNumber`/`LastLogin` per device.
`OperatingSystem` is a computed column from the iOS device payload; **NULL
means Android** (the Android payload has no `systemName`). Web portal
sessions appear here too as `chrome`/`safari`/`firefox` on `2.0.x`.

**What is NOT logged anywhere:** a 500 that dies *inside the Azure Function
shim* before the SP runs. Application Insights is commented out in
`api/HcWebApi.csproj`. The only trace of these is the client's
`Retry N failed: 500` line with an **empty** `Response:`. If you ever see a
burst of those across many devices at once, the shim is the suspect and the
DB will look innocent. (Memory `signup-broken-five-ways`: empty 500 = shim,
400 with a JSON body = SP.)

---

## Attribution trap: `HC.Device.Version` is *now*, not *then*

The client log payload does not carry the app version. The sweep joins to
`HC.Device`, which holds the version the device is on **today**. A device
that upgraded yesterday will have last week's session attributed to the new
build.

**Rule:** before blaming a build for an exception, compare the entry's own
timestamp (`[2026-09-06T20:50:06]`) against the release date in
`mobile-app/CHANGELOG.md`. In the 2026-09-09 sweep both Dart exceptions
"on 3.0.12" were from 09-02 and 09-06 sessions — before 3.0.12 existed, and
both already fixed in commit `04cd0c7a` (3.0.10).

Then check the source: does the line in the stack trace still contain the
failing call? `git log -S'<expression>' -- <file>` finds the commit that
removed it.

---

## Reading the client `[ERROR]` lines

Sorted roughly from "ignore" to "act".

| Line | Meaning | Action |
|---|---|---|
| Row `LEN = 38` | `[STARTUP]` only — a clean session | None; it is the healthy baseline |
| `[ERROR][FLUTTER] HttpException: Invalid statusCode: 404 … profile-photos/…` | A cached avatar URL whose blob is gone (bad upload later repaired, or user changed photo) | None unless one key repeats across many devices for days — then check `HC.Hasher.Photo` and the blob |
| `… platform-lookaside.fbsbx.com … 404` | Facebook-hosted avatar expired | None |
| `[ERROR][HTTP] 599` | Locally synthesised: no response within 30 s (`ServiceCommon.kLocalTimeoutStatus`). Not a server code | Phone was offline or on a bad link. Only worrying if one `queryType` dominates across devices |
| `[ERROR][HTTP] transport failure (server NOT reached …)` | DNS / socket failure before any request left. `Bad file descriptor` = the iOS suspend footgun (memory `http-one-shot-clients`) | None if isolated. If it recurs on many devices after a release, check the http client changes |
| `Retry N failed: 500` with **empty** `Response:` | Shim-level 500 — see above, no server record | One device, a handful in a day: transient. Many devices in the same minute: the Function app |
| `400 Bad Request` with `{"errorType":…}` | An SP said no, on purpose, and logged it | Look the `errorId` up in `HC.ErrorLog`. `errorType 13` = not authorised; `10005` = duplicate email (contractual, part of signup) |
| `[ERROR][ASYNC]` / `[ERROR][FLUTTER]` with a `#0 … package:harrier_central/…` stack | A Dart exception in our code | **Always read it.** Confirm the date, confirm the line still exists, then fix or file |
| `[METRICKIT] {"kind":"crash"|"hang"|"diskWriteException"}` | iOS diagnostic | Read it. `"metric"` is routine and can be ignored |

`[TRACE]` lines are not errors. PackTrack map open/close, lifecycle changes
and location stream state are logged deliberately so a session can be
reconstructed; a log full of them is a busy user, not a problem.

---

## What "healthy" looks like

A release is healthy when, over the two or three days after it ships:

1. Section 2 has nothing new in the `ProcName`/`ErrorName` pairs — the usual
   residents are `Duplicate email` on `hcapp_addEditUser` and the occasional
   `Invalid access token` (a phone with the wrong time).
2. Section 5 shows no exception whose entry timestamp is after the release.
3. Section 4's per-build lines for the new build are the same *shapes* as the
   previous build's, in proportion to session count.
4. Section 6 has only `"metric"`.

Adoption context matters: the App Store build lags TestFlight/Play internal by
days, so the new build's session count is small at first. Fourteen Android
and two iOS devices on 3.0.12 on day two (2026-09-09) is normal.

---

## Drill-down recipes

Who owns a noisy device:

```sql
SELECT d.id, d.Version, d.BuildNumber, h.HashName, d.LastLogin
FROM HC.Device d LEFT JOIN HC.Hasher h ON h.id = d.UserId
WHERE d.id = '<DeviceId from the #### header>';
```

Everything one user's devices reported in the window:

```bash
grep -A40 "dev=<DEVICEID>" <raw dump> | less
```

An `errorId` from a 400 body:

```sql
SELECT * FROM HC.ErrorLog WHERE id = '<errorId>';
```

Is an SP failing for everyone or one kennel:

```sql
SELECT kennelId, COUNT(*) FROM HC.ErrorLog
WHERE ProcName = 'hcapp_…' AND createdAt >= '<since>' GROUP BY kennelId;
```

Launch stream by version (finer than `HC.Device`, one row per login):

```sql
SELECT HcVersion, COUNT(*) n, COUNT(DISTINCT UserId) users
FROM HC.LaunchAndLogin WHERE LoginDate >= '<since>'
GROUP BY HcVersion ORDER BY n DESC;
```

Note `HC.LaunchAndLogin.SystemName` holds the iOS build string, not the OS
name, despite its name.

---

## Cadence

- **Day of release:** run the sweep once for adoption and server errors. Client
  logs will be nearly empty — they arrive one boot late.
- **Day +1 and +2:** run it again. This is when the real client signal lands.
- **Weekly while stable:** a three-day sweep is enough to catch a slow leak.
- **Before "Dance baby!":** run it so the release plan can say whether the
  previous build is clean.

When something real turns up, it goes to a GitHub Issue quoting the story ID —
but **never open one without James asking** (CLAUDE.md).

---

## Worked example — 3.0.12+1327, swept 2026-09-09

Server: 3 rows in two days, all expected. Client: 40 sessions on 1327, 14
clean, 9 with errors. Every error was one of: stale-avatar 404s from one
photo key that had already been repaired; 599 stalls and `Bad file descriptor`
transport failures on a single beta tester's iPhone (Opee) alongside
`syncUserData` 500s with empty responses, i.e. the phone's link, not the
server; and one `EnumFollowType` exception from a 09-06 session, fixed in
3.0.10. Verdict: clean.
