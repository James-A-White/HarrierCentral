# PackTrack — Stop⇒On-Inn & Auto-Stop Design

**Status:** Design agreed with James 2026-08-16. Not coded. Parked until after
the 3.0 App Store release.

**Motivating incident:** Brussels Trail #2058 (2026-08-16) — Rack of Lamb left
tracking running 2+ hours after the run ended; the après and journey home were
recorded onto the run's public map. Tracking should end itself when the run is
over instead of relying on tired hashers to remember.

---

## Build order

Four steps; each ships independently and strengthens the next.

```
① Mid-track OIN read rule  →  ② Stop⇒OIN dialog  →  ③ OIN-cluster prompt  →  ④ Admin "everyone in?" + stop flag
```

### ① Mid-track On-Inn read rule (prerequisite — already agreed 2026-08-15)

Readers (mobile `_isOnInn` path in `run_tracker_map_controller` + public-web
viewer) honour an OIN — as terminator AND as icon — only when it is effectively
the runner's LAST point (nothing after it beyond a short grace for straggler
queued fixes). Otherwise ignore it completely: draw through, no icon.

Originally a retroactive cleanup for the LH3 #2846 truncation; under this plan
it is **promoted to prerequisite**, because step ② makes every stop write an
OIN, so stop-then-resume will routinely create mid-track OINs. With the read
rule in place, stop⇒OIN is safe by construction.

### ② Stop Tracking dialog — three buttons

Stopping tracking always confirms with **"Are you On Inn?"**:

| Button | Effect |
|---|---|
| **I'm On Inn** | Drop an OIN mark at current position, then stop tracking |
| **I stopped early** | Stop tracking, no mark — the trail just ends, no icon |
| **Keep Tracking** | Cancel, nothing recorded |

Rationale for three buttons: an early bailer's track ending with an On Inn
icon at km 2 reads wrongly to viewers, and downstream logic (③/④) *trusts*
OIN marks — they must stay semantically honest.

Scope note: this is the **runner's** Stop Tracking. The hare's End Run button
ends the *run* (separate flow, existing confirmation); same OIN mechanics,
distinct wording so a runner never thinks they're ending the event.

### ③ On-device auto-stop prompt — anchored on the pack's OIN cluster

**Not** inactivity-based. A long drink stop is indistinguishable from an On
Inn to a motion sensor (James's explicit objection), so dwell time alone must
never stop tracking. Instead:

> Stationary for N minutes **within ~30m of other runners' On Inn marks**
> → local notification + "Are you On Inn?" dialog (same three buttons)
> → generous countdown auto-stop (≈5 min) if unanswered (phone-in-pocket case).

- A drink stop never triggers this — nobody has marked On Inn there. The
  absence of surrounding OINs is itself evidence the run isn't over.
- Residual false positive: a drink stop held at the On Inn venue. Covered by
  prompt-not-silent-kill + "Keep Tracking" suppressing re-prompts for a good
  while.
- Stationary detection must key on **absence of location callbacks** (a timer
  since last fix), not on position geometry — the distance filter means a
  stationary phone produces no callbacks at all.
- First finisher has no cluster to test against; they stop manually via ②,
  seeding the anchor for everyone else. Graceful degradation, by design.

### ④ Admin "Is everyone in?" + pack-wide stop signal

Detection becomes crisp and countable once OINs are explicit:

> K of M trackers have OIN-terminated tracks; the remaining M−K have been
> silent or stationary inside the OIN cluster for X minutes
> → **visible** push to kennel admins ("Everyone looks in — end tracking?")
> deep-linking to a confirm.

Admin confirms → event-level "tracking ended" flag server-side.

**Signal distribution: piggyback on StorePositions responses, NOT push.**
iOS throttles data-only pushes (~3/hr), so a silent stop-push is unreliable
exactly when needed. Every phone still transmitting calls StorePositions every
~60s; the response carries a stop directive → client stops the loop, shows a
local notification ("Tracking stopped — the run has ended"), offers one-tap
resume for anyone genuinely not in yet. Worst-case latency = one flush
interval; reaches exactly the phones that are still transmitting.

V1 shortcut (no detection component): hook the flag to actions that already
exist — hare's End Run confirm gains "Stop everyone's tracking too?", plus a
manual "End tracking for all" in run admin. V2 adds the detection (needs an
Azure Functions timer evaluating live events).

---

## Related but separate (from the same 2026-08-16 log sweep)

- **Mark-placement guards** (butt-dial/double-tap: whichyway ×2 6s apart on
  the walking test): per-slot cooldown ~8–10s for same-slot repeats, undo
  toast (defer the mark force-flush until the undo window closes), long-press
  placement held in reserve if butt dials recur.
- **"Tell the pack" debounce**: two identical LST:: marks 21s apart on Trail
  #2058 — disable the button briefly after press.
- **Zombie poll bug**: see memory `project_packtrack_zombie_poll_bug` —
  fix independently of this plan.
