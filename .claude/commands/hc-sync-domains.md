# HC Mobile App — Sync Domain Architecture

> **Always apply this skill when working on the mobile app.** Domain mistakes
> are silent — wrong-domain queries return empty results rather than errors,
> making them hard to diagnose. Any time you write or review a SQLite query
> in the mobile app, verify the table prefix matches the intended domain.


This skill describes the three local database domains used by the Harrier Central
mobile app, how they map to the backend sync SPs, and the rules governing what
data lives where. Use this when working on any feature that reads from or writes
to the local SQLite database, or when diagnosing data availability bugs.

---

## The Three Domains

The mobile app maintains three isolated local database namespaces. Every synced
table exists in one or more of these domains. The `EnumDataTables` enum
(`lib/util/enums.dart`) is the authoritative source — it declares which domains
each table participates in via `hasCommonTable`, `hasKennelTable`, and
`hasEventTable` booleans.

Physical table names are derived by prefixing the internal name:
- `common_hashers`, `common_events`, `common_payments`, etc.
- `kennel_hasherKennelMap`, `kennel_payments`, etc.
- `event_hasherEventMap`, `event_payments`, `event_receipts`, etc.

### Domain membership at a glance

| Table | common_ | kennel_ | event_ |
|---|---|---|---|
| hashers | ✓ | | |
| cities | ✓ | | |
| regions | ✓ | | |
| countries | ✓ | | |
| kennels | ✓ | | |
| events | ✓ | | |
| payments | ✓ | ✓ | ✓ |
| receipts | | | ✓ |
| songs | ✓ | | |
| hasherKennelMap | ✓ | ✓ | ✓ |
| hasherEventMap | ✓ | ✓ | ✓ |

---

## Domain 1: Common (User) Domain

**SP:** `HC6.hcapp_syncUserData`
**Purpose:** Everything a regular (non-admin) user needs. Loaded at boot and
kept alive indefinitely via delta syncs. Non-admin users never need the other
two domains.

### What's in it and how it's scoped

| Table | Scope |
|---|---|
| hashers | All hashers updated since watermark (global) |
| cities | Only cities that have a kennel (global) |
| regions | Only regions that have a kennel (global) |
| countries | All countries (global) |
| kennels | All kennels (global) |
| songs | All songs (global) |
| events | Narrow: recent + followed + attended (see below) |
| hasherKennelMap | All HKM rows for the current user across all kennels — complete history regardless of following state |
| hasherEventMap | All HEM rows for the current user — complete history |
| payments | All payment rows for the current user |

**The HKM and HEM common tables are the source of truth for the Hash History
pages.** They hold the user's complete cross-kennel run history. Do not filter
or scope these when querying history.

### Event narrowing rules

Events in the common domain are filtered to rows where ANY of these is true:
1. `EventStartDatetimeIndexed > now - 10 days` (recent events globally)
2. The event's kennel is in the user's followed kennels
3. The user has attended the event (`AttendenceState >= 3`)

This means: for kennels the user follows, the app has the full run history. For
everything else, only the past 10 days.

### Following a kennel — force-replicate

When a user follows a new kennel, pass `@forceReplicateAllRunsForKennel` with
the kennel's UUID. This triggers a separate events rowset that loads all events
for that kennel (full history), bypassing the narrow sync. The narrow sync
rowset is skipped when force-replicate is active.

---

## Domain 2: Kennel Domain

**SP:** `HC6.hcapp_syncKennelAdminData`
**Purpose:** All members and their data for a single kennel. Only used when
the user enters the admin section for a kennel.

### What's in it

| Table | Scope |
|---|---|
| kennels | All kennels updated since watermark (global watermark) |
| hasherKennelMap | All HKM rows for the given kennel (all members) |
| hashers | All hashers updated since watermark (global) |
| payments | Optionally scoped to a specific `@targetHasherId` |
| hasherEventMap | Optionally scoped to a specific `@targetHasherId` |

**Events are NOT in the kennel domain.** Event history for a kennel is served
by the common domain. A kennel admin sees run history via `common_events`.

### Lifecycle

- **Entering kennel admin:** Wipe all kennel_ tables, do a full sync for the
  target kennel (pass epoch watermarks).
- **Returning to the same kennel:** Kennel tables are still valid — do a delta
  sync only.
- **Switching to a different kennel's admin:** Wipe and full sync for the new
  kennel.
- The common domain is untouched by kennel admin entry/exit.

### Admin access guard — IMPORTANT TODO

**A kennel admin must be following the kennel before entering admin screens.**
If they are not following it, `common_events` will not have the full run
history, making admin tasks unreliable.

**Required behaviour (not yet implemented):** When an admin taps the gear icon
for a kennel they are not currently following:
1. Silently follow the kennel on the user's behalf.
2. Trigger a `syncUserData` call with `@forceReplicateAllRunsForKennel` set to
   that kennel's UUID to load full event history.
3. Only then navigate into the admin screens.

Do not silently fail or show incomplete data — always ensure the follow +
force-replicate has completed before the admin UI is accessible.

---

## Domain 3: Event Domain

**SP:** `HC6.hcapp_syncEventAdminData`
**Purpose:** All attendees, payments, and receipts for a single event. Only
used when the user enters the run admin screen for a specific event.

### What's in it

| Table | Scope |
|---|---|
| hashers | All hashers updated since watermark (global) |
| hasherEventMap | All HEM rows for the given event (all attendees) |
| hasherKennelMap | All HKM rows for the event's kennel (kennel-scoped) |
| events | Single row — the event being synced |
| payments | All payments for the given event |
| receipts | All receipts for the given event |

**Receipts only exist in the event domain** — there is no `common_receipts` or
`kennel_receipts`.

### Lifecycle

- **Entering event admin:** Wipe all event_ tables, do a full sync for the
  target event.
- **Returning to the same event:** Event tables still valid — delta sync only.
- **Switching to a different event:** Wipe and full sync for the new event.
- The common and kennel domains are untouched by event admin entry/exit.

---

## Key invariants — never violate these

1. **Common tables are never wiped.** They accumulate delta updates indefinitely.
   Wiping them requires a full re-sync from scratch (boot flow).

2. **Kennel and event domains are single-tenant.** Only one kennel's data and
   one event's data live in those tables at any time.

3. **Hash History reads from common tables only.** `common_hasherEventMap` and
   `common_hasherKennelMap` hold the user's complete history. Never read history
   from `kennel_` or `event_` tables.

4. **Admin entry requires the common domain to be complete.** For kennel admin,
   this means the user must be following the kennel (so full event history is
   present). Enforce the follow + force-replicate guard before navigating into
   admin.

5. **Table prefix determines domain.** Always double-check that queries
   targeting history use `common_` prefixed tables, and queries targeting admin
   views use the appropriate `kennel_` or `event_` prefixed tables.

---

## EnumDataTables — helper accessors

```dart
// Get the physical table name for a given domain
EnumDataTables.hasherEventMap.commonTableName  // → 'common_hasherEventMap'
EnumDataTables.hasherEventMap.kennelTableName  // → 'kennel_hasherEventMap'
EnumDataTables.hasherEventMap.eventTableName   // → 'event_hasherEventMap'

// Check domain participation
EnumDataTables.receipts.hasCommonTable   // → false
EnumDataTables.receipts.hasEventTable    // → true

// Get all flags for a domain (for sync bitmask operations)
EnumDataTables.kennelTableFlags   // OR of all tables with hasKennelTable = true
EnumDataTables.eventTableFlags    // OR of all tables with hasEventTable = true
EnumDataTables.userTableFlags     // OR of all tables with hasCommonTable = true
```
