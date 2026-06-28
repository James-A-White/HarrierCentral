# HC Event Date/Times — Canonical Reference

> **Load this skill whenever you touch run/event start times** — any SP, public-web
> feed, portal view, or mobile query that filters, sorts, groups, or displays when a
> run happens. Getting the wrong column is SILENT: the query runs, returns rows, and
> is simply wrong for a fraction of events. This caused a real production regression
> (see "The regression" below).

`HC.Event` stores a run's start time in **six** columns with different meanings. The
single most important rule:

> **Instant / chronological (future vs past, "is it now", ordering across kennels) →
> `EventStartDateTimeGmt`.
> Local wall-clock (calendar date, run-number order, display) →
> `EventStartLocal` / `EventStartLocalDate`.
> NEVER filter or sort by the *instant* of raw `EventStartDatetime`.**

---

## The columns

| Column | Type | Meaning | Use for |
|---|---|---|---|
| `EventStartDatetime` | `datetimeoffset` **NOT NULL** | Local wall-time. **Its offset is frequently a spurious `+00:00`** (see gotcha). | Wall-clock display (CAST to `datetime2(7)` to strip the `+00:00`). Per-kennel ordering (within one kennel, order is consistent). **NEVER for instant compare/sort across kennels.** |
| `EventStartDateTimeGmt` | `datetimeoffset` **NOT NULL** (since 2026-06-28, `DEFAULT '1900-01-01…+00:00'`) | **TRUE UTC instant** — computed from the wall-clock via Kennel→City→Timezone by trigger. | **All instant/chronological filter + sort**: future/past, "now-relative", cross-kennel ordering. |
| `EventStartLocal` | `datetime2` PERSISTED computed | FB-aware local wall-clock (= `SyncEventStartDatetime` cast to `datetime2`). | Local-clock ordering & bucketing: run-numbering, stats, YEAR/DATEDIFF buckets. |
| `EventStartLocalDate` | `date` PERSISTED computed | Local calendar date = `CONVERT(date, EventStartDatetime)`. | Grouping/filtering by local calendar date (global calendar). |
| `SyncEventStartDatetime` | `datetimeoffset` PERSISTED computed | FB-aware effective start: `FbEventStartDatetime` when `UseFbRunDetails=1`, else `EventStartDatetime`. | Source for the computed columns above. **Unreferenced directly in HC6 SPs.** |
| `EventStartDatetimeIndexed` | `datetimeoffset`, trigger-maintained | FB-aware local wall-clock with offset zeroed to `+00:00` (legacy). | **HC5 only.** HC6 moved to `EventStartLocal`. Drop at HC5 retirement — see `/db` notes / `project_retire_hc5_todos`. |

Also: `EventEndDatetime` (`datetimeoffset`), `FbEventStartDatetime` (`datetimeoffset`, the
Facebook override source). Neither is filtered/sorted directly.

---

## ⚠️ The gotcha: spurious `+00:00` on `EventStartDatetime`

The portal often saves the local wall-time **tagged with a `+00:00` offset** even when the
kennel is not at UTC. As of 2026-06-28 this affected **~67% of rows (10,273 / 15,365)**.

Consequence: **raw `EventStartDatetime`'s UTC *instant* is wrong** for those rows. A run at
`13:00 +00:00` (stored) for a `+01:00` kennel is really `12:00` UTC — `EventStartDateTimeGmt`
holds `12:00`, raw holds `13:00`. So:

- `WHERE EventStartDatetime >= @utcCutoff` → wrong for ~67% of rows.
- `ORDER BY EventStartDatetime` across kennels → wrong chronological order.
- But `CONVERT(date, EventStartDatetime)` / `CONVERT(datetime2, EventStartDatetime)` →
  **correct**, because they take the wall-clock and ignore the offset. That's why the
  *Local* columns derive from raw safely.

**The instant lives only in `EventStartDateTimeGmt`.** Use it for any time-comparison.

---

## How `EventStartDateTimeGmt` is maintained (and why it's never null)

Trigger **`HC.trgUpdateModifiedOnDateForEvent`** (AFTER INSERT, UPDATE) recomputes it when
`EventStartDateTime` changes:

```sql
SET EventStartDateTimeGmt =
    CASE WHEN tz.Timezone IS NOT NULL
         THEN (CAST(EventStartDatetime AS datetime) AT TIME ZONE tz.Timezone) AT TIME ZONE 'UTC'
         ELSE EventStartDatetime AT TIME ZONE 'UTC'   -- fallback: never null
    END
-- LEFT JOIN Kennel -> City -> DomainValues.Timezone
```

- It casts to a naive `datetime` (drops the spurious offset → wall-clock), interprets it in
  the kennel's timezone, converts to UTC. That's how it corrects the spurious offset.
- **LEFT JOINs + the `ELSE` fallback guarantee a non-null result** for every row (the old
  version used `INNER JOIN City` and left Gmt null for city-less / timezone-less kennels).
- The column is **`NOT NULL` with `DEFAULT '1900-01-01…+00:00'`**. The default is a transient
  placeholder only — the AFTER trigger overwrites it in the same transaction (and
  `EventStartDatetime` is NOT NULL so the trigger always fires), so committed rows never
  contain it. A far-past default means any trigger-bypassed row is obviously broken and
  sorts to the distant past.
- **`HC.Event` is a mobile-synced table.** Any schema change must disable
  `trgUpdateModifiedOnDateForEvent` first (see `feedback_trigger_disable_before_alter`).
  Editing the trigger *definition* (CREATE OR ALTER) does not write rows → no re-sync.

---

## Facebook override

`SyncEventStartDatetime` / `EventStartLocal` / `EventStartDatetimeIndexed` are all **FB-aware**:
when `UseFbRunDetails = 1` they use `FbEventStartDatetime`, else the manual `EventStartDatetime`.
`EventStartDateTimeGmt` is computed from the *manual* wall-clock (not FB) — if you need the
FB-aware instant, that's a known gap; today the feeds display via Gmt + IANA timezone and the
FB override is reflected in the Local columns. Don't assume Gmt tracks the FB time.

---

## Indexing strategy

| Need | Column | Index |
|---|---|---|
| Instant, cross-kennel | `EventStartDateTimeGmt` | `IX_Event_GmtStart_Visible` (Gmt) INCLUDE(KennelId) WHERE visible |
| Instant, per-kennel | `EventStartDateTimeGmt` | `IX_Event_Kennel_GmtStart_Visible` (KennelId, Gmt) WHERE visible |
| Local calendar date | `EventStartLocalDate` | `IX_Event_LocalDate_Visible` |
| Local wall-clock order / run# / stats | `EventStartLocal` | `IX_Event_EventStartLocal`, `IX_EvtRunCount_Local`, `IX_EventUsageData_Local` |
| Per-kennel raw run list | `EventStartDatetime` | `IX_EventByKennelIsCountedStartDateAbsEvtNum` |

`WHERE visible` = `WHERE IsVisible=1 AND deleted=0 AND removed=0`. The source rarely changes
after insert, so over-index for reads. See `project_sp_index_audit` for the full map.

---

## SQL patterns

**Sargable, sort-free future/past feed** (Gmt is non-null, so no `OR`-fallback, and a plain
`ORDER BY` is served by the index — split direction into IF/ELSE so it's not a CASE):

```sql
IF @IsFuture = 1
    SELECT ... FROM HC.Event e
    WHERE e.KennelId=@KennelId AND e.IsVisible=1 AND e.deleted=0 AND e.removed=0
      AND e.EventStartDateTimeGmt >= @FutureCutoff
    ORDER BY e.EventStartDateTimeGmt ASC;     -- index-ordered, no Sort
ELSE
    SELECT ... WHERE ... AND e.EventStartDateTimeGmt < @UtcNow
    ORDER BY e.EventStartDateTimeGmt DESC;
```

- `@FutureCutoff` / `@UtcNow` are `datetimeoffset` in UTC (`SYSDATETIMEOFFSET() AT TIME ZONE 'UTC'`).
- Do **not** wrap the date column in `COALESCE`/`CAST`/`CONVERT` in the WHERE — non-sargable.
- A **cross-kennel-SUBSET** top-N-by-date (e.g. a `#ValidKennels` join) inherently needs a
  Sort (can't merge N ordered streams without one) — that's expected, not a missing index.
- Display: return `CAST(e.EventStartDatetime AS datetime2(7))` (strips spurious `+00:00`) plus
  `EventStartDateTimeGmt` and the kennel IANA timezone; the client renders local time.

---

## The regression (don't repeat it)

2026-06-28: a commit switched the public feed filters to raw `EventStartDatetime` believing
its instant equalled Gmt. It does not (67% spurious offset). Result: upcoming/past lists were
silently wrong for two-thirds of events. Fixed by reverting to `EventStartDateTimeGmt` and
hard-guaranteeing Gmt non-null. **Lesson: instant ⇒ Gmt, always.**

## Checklist when working with event times
1. Comparing to "now" or another instant, or ordering chronologically across kennels? →
   `EventStartDateTimeGmt`.
2. Showing/grouping by the local date or local clock, or assigning run numbers? →
   `EventStartLocal` / `EventStartLocalDate`.
3. Never put a function around the date column in a WHERE you want indexed.
4. Changing `HC.Event` schema? Disable `trgUpdateModifiedOnDateForEvent` first.
5. New time-based read path? Check the index table above; add a `WHERE visible` index if missing.
