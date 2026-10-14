---
name: hc-primary-keys
description: "Primary key strategy: every PK is a GUID unless James agreed otherwise and it is documented here; Public*Id (Hasher, Kennel, Event) is identification only, never a foreign key, a join or a copy in another table, so it can be rotated if compromised. Use when designing a table or column, writing an SP that takes or returns an id, adding a client field that holds an id, or putting an id somewhere new (URL, QR, push, browser)."
---

# HC Primary Keys — Key Strategy

> **Load this skill whenever you design a table or column, write an SP that
> takes or returns an id, add a client field that holds an id, or put an id
> somewhere new (a URL, a QR code, a push payload, a browser).** Key mistakes
> are not loud: a foreign key on the wrong column works perfectly until the
> day you need to change that column, and then it is a migration across every
> child table.

Two rules, set by James (2026-10-12):

1. **Every primary key is a GUID** unless James has agreed otherwise and the
   exception is written down in this file.
2. **Some entities have a public id and an internal id. The public id is for
   identification only and is never a foreign key**, so it can be rotated if
   it is compromised.

---

## Rule 1 — every primary key is a GUID

A new table's key is `id UNIQUEIDENTIFIER NOT NULL` with a `DEFAULT (NEWID())`,
clustered. Anything else — an `INT IDENTITY`, a natural key, a composite key —
needs James's agreement first, and then a line under *Documented exceptions*
below. (A new table needs his agreement anyway: CLAUDE.md, "Never create a new
database table without asking James first".)

🧠 **Why GUIDs here:**
- **A client can mint the id before the server sees the row.** The phone works
  offline and retries; a chat message carries its own `messageId`, so a retry
  of the same send is the same row, not a duplicate. An identity column cannot
  be known until the INSERT has happened.
- **Rows move between databases without renumbering** — the `HC_BACKUP*`
  schemas, merges, imports. An identity collides; a GUID does not.
- **An id is not a count or a guess.** `/hasher/1042` invites `/hasher/1043`;
  a GUID does not.

**Details that follow from it:**
- `NEWID()` is the norm: 33 of the 43 GUID-keyed HC tables use it.
- Five use `NEWSEQUENTIALID()` (DownDowns, DownDownHashers, KennelPhotos,
  PortalNewsflash, PortalNewsflashRead). It inserts in order and fragments the
  clustered index less, but it is guessable from its neighbours, so use it only
  where the id is never shown to anyone.
- Five have no default:
  - The caller supplies the id: `HC.Device`, `HC.Product`, `HC.TrackImport`.
  - The table is a one-to-one extension keyed by its owner's id:
    `HC.EventTrack` (`EventId`), `HC.KennelWebsite` (`KennelId`). That is
    still a GUID key, and a sound shape for "more columns for one row".
- **Join tables still get their own GUID `id`**, and the pair is held unique
  by an index — e.g. `HC.HasherFriendMap`: `id` plus unique
  (`UserId`, `Friend_UserId`).
- **A client-supplied id needs an idempotent insert**: check with
  `WITH (UPDLOCK, HOLDLOCK)` or `MERGE … WITH (HOLDLOCK)`, or concurrent
  retries race to a duplicate-key 500 (CLAUDE.md code smells).
- Clients hold ids **lowercase** (`HcId` in the app; CLAUDE.md "Ids are
  lowercase, everywhere"). SQL Server writes uppercase whenever it turns a
  GUID into text.

---

## Rule 2 — public id and internal id

Three entities carry both:

| Table | Internal id (the key) | Public id |
|---|---|---|
| `HC.Hasher` | `id` | `PublicHasherId` |
| `HC.Kennel` | `id` | `PublicKennelId` |
| `HC.Event`  | `id` | `PublicEventId`  |

Each public id defaults to `NEWID()` and has a unique index.

**The internal id is the key.** Every foreign key, every join, and every map
row (`UserId`, `KennelId`, `EventId` on HasherKennelMap, HasherEventMap,
EventMessage, Payment …) uses it.

**The public id is identification only.** It goes where an identifier leaves
the database for the outside world: a URL, a QR code, a share link, a push
payload, a chat author id, the web. When a caller hands one in, the SP turns it
into the internal id **once, at the door**, and works with the internal id from
there:

```sql
SELECT @targetId = h.id
FROM HC.Hasher h
WHERE h.PublicHasherId = @targetPublicHasherId AND h.Removed = 0;
```

It is **never** a foreign key, **never** a join condition between two tables,
and **never stored in another table** as a reference.

🧠 **Why: so it can be rotated.** If a public id leaks — a scraped URL, a QR
code posted online, a link someone should not have — you change that one
column on that one row and nothing else notices. No foreign key, map row or
piece of history points at it. Had it been used as a foreign key, rotating it
would mean rewriting every child table, and so in practice it would never
happen.

**Verified 2026-10-12:** none of the database's 95 foreign keys references a
`Public*Id` column.

### Where public ids are copied today — debt, not precedent

| Where | What | Why it matters |
|---|---|---|
| `HC.EventMessage` | `PublicEventId`, `PublicHasherId`, `PublicKennelId` (NOT NULL), beside the internal `EventId` / `UserId` / `KennelId` | Readers already do the right thing: they join `HC.Hasher` on `UserId` and return the hasher's CURRENT `h.PublicHasherId` (`hcapp_getEventMessages`). But `hcportal_mergeHashers` has to rewrite the copy, `hcapp_getEventMessageCounts` returns `em.PublicEventId`, and a rotation must rewrite these too, or old messages carry a dead id. |
| `LOG.KennelReport.PublicKennelId` | a log row | A snapshot of the moment; it does not need to follow a rotation. |
| `HC.HasherBackup`, `HC_BACKUP*` | backups | Snapshots. |

**Do not add another.** If a new table seems to need a public id, store the
internal id and join to read the current public one.

---

## Which id goes where

| Holder | Gets | Notes |
|---|---|---|
| The phone's synced tables | **internal** ids | The user sync sends `h.id AS hasherId`, and the local hasher model has no public id. The phone is the signed-in user's own authenticated device. |
| Browsers, public web pages, URLs, QR codes, emails, push payloads | **public** ids | An SP that serves the app and the web together blanks the internal id for a browser: `CASE WHEN @isWeb = 1 THEN NULL ELSE OtherHasherId END` (`hcapp_getEventBadgeCount`, 2026-10-12). |
| An SP that takes a "which one" | the **public** id | Where a client holds only internal ids (the phone's hasher lists), add a separate optional internal-id parameter. The public id wins, and the two are two seeks, not one `OR` (`hcapp_startDirectMessage @targetHasherId`, 2026-10-12). |

Never put an internal id into a URL, a QR code, an email or anything a
browser receives. Once it is out, it cannot be rotated: it is the key.

---

## Rotating a public id

There is no tool for this. It is a by-hand job, and it is James's decision.
For a hasher:

```sql
UPDATE HC.Hasher SET PublicHasherId = NEWID() WHERE id = @id;
UPDATE HC.EventMessage
SET PublicHasherId = (SELECT PublicHasherId FROM HC.Hasher WHERE id = @id)
WHERE UserId = @id;
```

That is the intended effect: old links and QR codes stop resolving. Before
relying on it, check:
- the hasher's own device keeps their public id in `StringPrefsEnum.publicHasherId`,
  set at device authorisation, so it stays stale until that happens again;
- other phones cache chat author ids until their next fetch.

Kennels and runs work the same way: also rewrite `HC.EventMessage.PublicKennelId`
/ `PublicEventId`, and remember that a kennel's or run's public URLs change.

---

## Documented exceptions (found 2026-10-12)

**Non-GUID primary keys in the live HC and LOG schemas.** These are all
existing; none is a precedent.

| Table | Key | Kind |
|---|---|---|
| `HC.ErrorLog` | `serial INT` | log |
| `HC.LaunchAndLogin` | `idx INT` | log |
| `HC.TierLog` | `id INT` | log |
| `HC.PerfBaseline` | `id INT` | tooling |
| `HC.PortalAccess` | `idx INT` | log |
| `HC.Integration` | `IntegrationId INT` | small lookup; the number is referenced by meaning (1 = Facebook, 3 = San Diego …) |
| `HC.PermissionFunction`, `HC.PermissionRole`, `HC.RolePermission` | `id INT` | permission lookups |
| `LOG.GeneralLog` | `idx INT` | log |
| `LOG.AiUsage` | `Id BIGINT` | log |
| `LOG.AzureDailyCost` | (`CostDate`, `ServiceName`) | one row per day per service |
| `DomainValues.*` | `SMALLINT` / `INT` codes | enum tables — the code IS the meaning |

**HC tables with no primary key at all:** `HC.Song`, `HC.KennelSongMap`,
`HC.IntegrationJob`, `HC.HasherBackup`. Flag this when you touch one, and put a
fix to James rather than adding one quietly — it is schema.

**Not HC6's concern:** `dbo.*`, `Hashers.*`, `HC3W.*`, `WORDZ.*`, `DEV.*`,
`EXT.*` and the `HC_BACKUP*` schemas. These are legacy, imports and backups,
some of them keyed by `INT` or `NVARCHAR`.

To add an exception: James agrees, then add a row here saying why.

---

## Checklist

- [ ] New table: GUID `id`, `DEFAULT (NEWID())`, clustered — and James asked first.
- [ ] Every foreign key and join uses the **internal** id.
- [ ] No `Public*Id` column added to a table other than its owner's.
- [ ] A public id coming in is resolved to the internal id once, at the top of the SP.
- [ ] Nothing a browser, URL, QR code, email or push receives carries an internal id.
- [ ] A client-minted id is inserted idempotently (`UPDLOCK, HOLDLOCK` / `MERGE … HOLDLOCK`).
- [ ] Ids compared in a client are lowercase (`HcId`).
