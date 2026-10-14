---
paths:
  - "db/hc6/**"
  - "public-web/**"
---

# Which SP the Web Calls

Moved verbatim from the root `CLAUDE.md` in October 2026 (see `docs/history/claude-md-restructure-2026-10.md`).
Loads when you read an HC6 SP or a public-web file.

---

### Which SP does the web call? Wrap for writes, query for screens

The browser is a device (E9.F7), so the public web can call the app's own
`hcapp_` SPs. Whether it *should* depends on what the call is for:

| The call… | Use | Why |
|---|---|---|
| **changes** something — RSVP, follow, prefs, send a message, revoke a passkey | a thin `publicWeb_` wrapper that `EXEC`s the `hcapp_` SP | A write carries the rules (run counts, push fan-out, sequence numbers, permission gates) and is stateless, so nothing about a browser changes it. Writing those twice is how one product grows two behaviours. A wrapper is ~20 lines and cannot drift. |
| **draws a screen** — the runs list, my history, the pack | its own `publicWeb_` query SP | The app's reads are not reads, they are a **replication protocol**: `hcapp_syncUserData` takes eleven `@xUpdatedAfter` watermarks and answers "what changed since I last looked" into a local SQLite database. A browser has no such store, so it has no watermark to send and nothing to merge into — calling it means `'ignore'` on every parameter on every page load. The app's read SPs answer a question the web never asks. |

As of 2026-09-20: 10 of 44 `publicWeb_` SPs wrap an app SP, and almost all of
them are writes; the other 34 are screen queries.

**The app SPs do not care that the caller is a browser.** `ValidateAppAuth`
makes no distinction — a device is a device. Only `IsMobile` does, and only
for push: `hcapp_selectSong` requires `d.IsMobile = 1` alongside an FCM token,
because a browser cannot receive FCM. That is why web chat polls.

**The risk is in the 34, not the 10.** Each screen query re-implements a rule
the app also holds — what counts as attended, the past-run window,
`runClassification`. HC3 is the cautionary tale: `syncUserData`,
`syncUserData392`, `_668`, `_705`, `_800` are forked procs that diverged, and
that forking is much of why HC6 exists.

So: **a rule both sides need lives in ONE object, not two copies.** Prefer a
VIEW or an inline table-valued function. Do **not** reach for a scalar UDF in
a `WHERE` clause over `HC.Event` / `HC.HasherEventMap` — it is a per-row call
that wrecks the plan. Scalar functions are for small, row-at-a-time gates
(`HC6.UserMayEnterChatRoom`, `HC6.DevicePlatformName`), not for filtering big
tables.

**Beware the naked literal.** `AttendenceState >= 20` means *attended*;
`>= 3` appears in `hcapp_selectSong` and `hcapp_syncUserData` and means
something else entirely — "has any row for this run", used to pick a push
audience and to widen what syncs to the phone (a run you declined should
still reach your history). They look alike and ask different questions. When
you copy one, copy its meaning, and say which you meant.
