# Log triage: how the fingerprints work

A 15-minute read. The reference is `/hc-monitoring`; this page explains
*why* it is built the way it is.

## The problem it solves

`tools/log_sweep.sh` shows every error. On a normal day that is a few hundred
lines, and almost all of them are known: a phone lost signal (599), an avatar
blob has gone (404), a phone's clock is wrong (invalid token). The one or two
lines that matter are in there somewhere, and finding them means reading all of
it every time.

So the question changes. It is no longer "what is in the logs?" but "what is in
the logs that I have not already understood?" That needs two things:

1. a way to say that two errors are **the same error**, and
2. a list of the errors you have **already understood**.

The first is the **fingerprint**. The second is `tools/known_errors.tsv`.

## 1. The fingerprint: making "the same error" precise

Take this crash, logged three times on three phones:

```
[2026-09-18T06:50:05] [ERROR][ASYNC] RangeError (length): Invalid value: Only valid value is 0: 2
#2  CheckInPackController._processPayment (package:harrier_central/…/check_in_pack_page_controller.dart:899)
```

The raw text differs every time: the timestamp, the numbers in the message
(`0: 2`, `1: 3`), the line number after an edit. The fingerprint keeps what
identifies the bug and throws the rest away:

```
app ASYNC RangeError (length): Invalid value: Only valid value is N: N @ check_in_pack_page_controller.dart CheckInPackController._processPayment
```

| Part | Kept because | Normalised how |
|---|---|---|
| `app` / `sp` / `web` / `portal` / `api` | which component failed | from `HcVersion` |
| `ASYNC` | how it surfaced | the log tag |
| the message | what went wrong | numbers → `N`, GUIDs → `<id>`, URLs → host |
| first frame **in our code** | where it went wrong | file and function, **no line number** |

🧠 **Why no line number?** Line numbers move whenever someone edits the file
above the crash. If they were part of the fingerprint, an unrelated edit
would make an old bug look new. The function name only changes when the code
is genuinely restructured.

🧠 **Why "first frame in our code"?** A Dart stack starts inside Flutter or a
package (`List.[]`, `AnimationController.stop`). Those tell you *what* broke,
not *whose* code called it. The first `package:harrier_central/` frame is the
line you would open to fix it. When no frame is ours (a pure Flutter or
`flutter_map` failure), the first package frame stands in.

Network failures get coarser fingerprints on purpose: `app HTTP 599`,
`app NET host lookup blob`. You would never fix those per endpoint or per
tile server, so splitting them only adds rows to read.

## 2. The baseline: what you already know

`tools/known_errors.tsv` is one line per fingerprint: the fingerprint, a
status and a note.

| Status | Meaning | What triage does |
|---|---|---|
| `noise` | Expected. Not a bug. | Counts it and says nothing, **unless** it hits ≥5 devices in one hour. That is a spike: an outage, not a flaky phone. |
| `open` | A real bug, not fixed yet. | One line when it fires. |
| `fixed:1397` | Fixed in that build (or `web 0.21.74`, or a date for SP deploys). | Silent on older builds. **REGRESSED** if it shows up on 1397 or later. |

🧠 **Why `fixed:` carries a version and not just "fixed".** Store builds never
go away. Phones on 3.0.12 will keep throwing the bugs 3.0.12 had for months.
The version is what lets triage say "old phone, old bug, fine" instead of
"it's back!".

## 3. What you see

```bash
python3 tools/log_triage.py          # last 3 days
python3 tools/log_triage.py --days 30 --all
```

- **REGRESSED**: a fix did not hold. Read these first.
- **NEW**: not in the baseline. Each one ends with a `↳` line to paste into the TSV once you have decided what it is.
- **SPIKES**: noise that suddenly hit many devices at once.
- **OPEN**: known bugs still firing.
- **NOISE**: one total.

Exit code: `0` quiet, `1` something to look at, `2` triage could not run.

## 4. The two habits it needs

1. **When you fix a bug, set its line to `fixed:<next build>` in the same
   commit.** The next triage then proves the fix held, or tells you it didn't.
2. **When something is NEW, decide what it is and add its line.** A NEW entry
   that is never baselined nags every day. That is deliberate.

## 5. What runs on its own

- **Every morning at 08:00**, launchd runs `tools/log_triage_daily.sh`. It
  iMessages you *only* on exit 1 or 2. No message means a clean day. Full
  reports are in `~/Library/Logs/hc-log-triage/`. Install or refresh the job
  with `tools/install_log_triage_job.sh`; `--uninstall` removes it.
- **Azure Monitor alert "HC API 5xx burst"** (resource group
  `harriercentralpublicapi`) emails you when the API returns more than 40 5xx
  errors in 15 minutes. This covers what the tables cannot see: an empty 500
  that died in the shim never writes an `HC.ErrorLog` row.

## 6. Things to try, to make it click

1. Open `tools/known_errors.tsv` and find the `SnackbarController._removeEntry` line. Read its note, then find the fix commit (`3c621239`).
2. Run `python3 tools/log_triage.py --days 30 --all` and match three noise rows to lines in the TSV.
3. Change one `fixed:` build to a lower number and run triage again. It will
   report a regression. Change it back. That is the mechanism that catches a fix
   that didn't hold.
