# HC Chat — Notification Modes & Push Dispatch Reference

> **Load this skill when working on any part of the event chat feature.**
> Chat spans message send/receive (Flutter app + portal), push notification
> dispatch (SQL SPs), and FCM delivery (Azure Function shim). The notification
> preference hierarchy is subtle — wrong implementations silently deliver pushes
> to users who opted out, with no error to diagnose from.

---

## Feature Overview

Event chat lets hashers and mismanagement exchange messages tied to a specific
run event. Messages are stored in `HC.EventMessage`. When a message is sent,
the SP produces two rowsets of FCM recipients which the API shim uses to send:

- **Rowset 1** — full visible push notification (banner + sound)
- **Rowset 2** — silent data-only FCM (triggers app badge refresh, no banner)

The caller (mobile app or portal) never handles notification dispatch directly —
it is entirely driven by the rowsets returned by the send SP.

---

## File Map

| Purpose | File |
|---------|------|
| App chat controller | `mobile-app/lib/pages/detail_pages/chat/chat_page_controller.dart` |
| App chat page | `mobile-app/lib/pages/detail_pages/chat/chat_page.dart` |
| Live run chat page | `mobile-app/lib/pages/live_run_pages/live_run_chat_page.dart` |
| Chat strip widget | `mobile-app/lib/widgets/chat_strip_widget.dart` |
| App send SP | `db/hc6/app/HC6.hcapp_sendEventMessage.StoredProcedure.sql` |
| Portal send SP | `db/hc6/portal/HC6.hcportal_sendEventMessage.StoredProcedure.sql` |
| App read SP | `db/hc6/app/HC6.hcapp_getEventMessages.StoredProcedure.sql` |
| App mark-read SP | `db/hc6/app/HC6.hcapp_markEventChatRead.StoredProcedure.sql` |
| Notification state enum | `mobile-app/lib/util/enums.dart` — `NotificationState` |

---

## Notification Preference Modes

Defined in `NotificationState` enum (`enums.dart`):

| Value | Name | Meaning |
|-------|------|---------|
| `0` | `auto` | Use kennel-level preference — no event-level override |
| `1` | `on` | Always send a full push notification |
| `2` | `ignore` | No notification of any kind |
| `3` | `mute` | **Silver Bell** — silent/in-app only, no push banner |
| `4` | `onBeforeRun` | Full push only within the 6-hour event window |

There are two separate columns storing preferences:

| Column | Table | Scope |
|--------|-------|-------|
| `KennelNotificationPreference` | `HC.HasherKennelMap` | Per-user per-kennel default |
| `EventNotificationPreference` | `HC.HasherEventMap` | Per-user per-event override |

**Preference resolution rule:** event-level overrides kennel-level, EXCEPT when
the event-level value is `0` (auto), which means "no event override — use the
kennel preference". `NULL` and `0` both mean "fall back to kennel preference".

---

## The NULLIF Rule — Critical Pattern

**Never use bare `COALESCE(hem.EventNotificationPreference, hkm.KennelNotificationPreference)`
to resolve the effective preference.** SQL's `COALESCE` treats `0` as a non-null
value, so `COALESCE(0, 3)` returns `0` instead of falling back to the kennel
preference `3`. A user with Silver Bell (`mute=3`) at kennel level whose
HasherEventMap row has `EventNotificationPreference = 0` (the default when a
row is created by RSVP or attendance) would receive a full push notification.

**Always use:**
```sql
COALESCE(NULLIF(hem.EventNotificationPreference, 0), hkm.KennelNotificationPreference)
```

`NULLIF(hem.EventNotificationPreference, 0)` converts `0` (auto) to `NULL`,
so `COALESCE` correctly falls back to the kennel preference. `0` at the
kennel level is unaffected — it stays as `0` (meaning auto → push).

This pattern must appear in **every query** that determines whether a user
receives a push notification or in-app notification based on their preference.

---

## Rowset Structure for Push Dispatch

Both `hcapp_sendEventMessage` and `hcportal_sendEventMessage` return the same
three-rowset contract to the API shim:

### Rowset 0 — Message detail
The inserted message row, returned to the sender for optimistic UI confirmation.

### Rowset 1 — Full push recipients `{ UserId, FcmToken }`
Users who receive a visible banner notification. Qualifies when ALL of:
- Effective preference (via NULLIF/COALESCE) is `0` or `1`; OR `4` AND within 6-hour window
- User has an FCM token
- User matches the message releasability bitmask (see below)
- User is following the kennel OR is a member/hare/RSVP depending on flags

### Rowset 2 — Silent (in-app) recipients `{ UserId, FcmToken }`
Users who receive a data-only FCM to trigger an app refresh. Qualifies when ALL of:
- User is following the kennel OR is a current member
- User has an FCM token
- `KennelNotificationPreference != 2` (not globally opted out)
- User is NOT already in Rowset 1

**Known gap (Bug 2 — deferred):** Rowset 2 does not check `EventNotificationPreference`
for `ignore(2)`. A user who has set event-level preference to `ignore` but has
kennel-level `mute(3)` will still appear in Rowset 2. This has no visible user
impact (silent FCMs show no banner), but it is semantically incorrect. Fix when
next modifying either send SP — apply the NULLIF/COALESCE pattern to the
Rowset 2 gate and add a `hem` LEFT JOIN to the Rowset 2 query in the app SP.

---

## Releasability Bitmask

`@messageReleasabilityFlags` controls which audience segments receive the
notification. The Flutter app currently sends `63` (all bits set = everyone).

| Bit | Hex | Audience |
|-----|-----|---------|
| 0 | `0x0001` | Mismanagement |
| 1 | `0x0002` | Members |
| 2 | `0x0004` | Followers |
| 3 | `0x0008` | RSVPs |
| 4 | `0x0010` | Hares |
| 5 | `0x0020` | Everyone |

Constant in Flutter: `kChatReleasabilityAll = 63` (`chat_page_controller.dart:4`).

---

## App-Side FCM Handling

The app uses **FCM-only delta fetch** — no polling timer. Chat messages arrive
via FCM data messages; the app fetches new messages on:
1. `onInit` — full fetch (`sinceSequenceCount = null`)
2. FCM `onMessage` — delta fetch using `_lastKnownSequenceCount`
3. `onAppResumed` — delta fetch (catches messages received while backgrounded)

The delta mechanism uses `sinceSequenceCount` passed to `hcapp_getEventMessages`.
The SP returns messages where `MessageSequenceCount > sinceSequenceCount`,
newest-first. The controller reverses to oldest-first for display.

**Re-entrant guard:** `_isFetching` / `_pendingFetch` flags in
`ChatPageController._fetchDelta()` prevent concurrent fetches. If a fetch
arrives while one is in progress, `_pendingFetch = true` and a second fetch
fires immediately after the first completes.

**Optimistic send deduplication:** `handleSendPressed` inserts the message
optimistically before the SP call. On delta fetch, messages already in
`chatController.messages` (matched by `id`) are skipped to prevent duplicates.

---

## Message Sequence Count

`HC.EventMessage.MessageSequenceCount` is an auto-incrementing INT computed
by the DB (identity or trigger). It is the authoritative ordering key for
delta fetches — not `createdAt`. Always use `sinceSequenceCount` for
incremental loads, never timestamp-based filtering.

---

## Sender Exclusion

The send SP immediately updates `HC.EventMessageBadgeCounts` for the sender
with the new `MessageSequenceCount`, so the sender's own message never
appears as unread to themselves. The delta fetch will skip it (sequence count
already known) or the optimistic insert will deduplicate it.

---

## Known Issues / Deferred Work

| Severity | Issue | Location |
|----------|-------|---------|
| Medium | Rowset 2 does not respect `EventNotificationPreference = ignore(2)` — user still gets silent FCM | Both send SPs |
| Low | RSVP/Hare releasability guard uses `COALESCE(..., 1) != 0` which incorrectly excludes `auto(0)` and includes `ignore(2)` | Both send SPs, Rowset 1 |

---

## Things to Watch Out For

- **Always use `NULLIF(hem.EventNotificationPreference, 0)` before COALESCE** — see
  the NULLIF Rule section above. This is the single most likely source of
  notification bugs and was confirmed to be causing Silver Bell users to receive
  push notifications in production (fixed 2026-05-27).
- **Both send SPs must stay in sync** — `hcapp_` (mobile) and `hcportal_` (portal)
  share the same notification logic. Any change to one must be mirrored in the other.
- **Rowset 2 uses `KennelNotificationPreference` only** — it does not currently
  consider `EventNotificationPreference`. Keep this in mind when extending Rowset 2.
- **`MessageSequenceCount` not `createdAt`** — all delta fetch logic must use
  sequence count. Timestamps are not monotonic across devices.
- **`publicHasherId` not `userId`** — author identity in messages uses
  `HC.Hasher.PublicHasherId` (the externally visible UUID), not the internal
  `HC.Hasher.id`. The app resolves users via `publicHasherId`.
