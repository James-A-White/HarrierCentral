---
paths:
  - "db/**"
---

# SQL and Stored Procedure Rules

Moved verbatim from the root `CLAUDE.md` in October 2026 (see `docs/history/claude-md-restructure-2026-10.md`).
Loads when you read a file under `db/`.

---

## HC6 SP Standards

Every HC6 stored procedure MUST:

```sql
-- 1. Use CREATE OR ALTER
CREATE OR ALTER PROCEDURE [HC6].[hcportal_yourProcName]

-- 2. Have a header block
-- =====================================================================
-- Procedure: HC6.hcportal_yourProcName
-- Description: What this SP does
-- Parameters: List key params
-- Returns: Describe rowsets
-- Author: Harrier Central
-- Created: YYYY-MM-DD
-- HC5 Source: HC5.hcportal_yourProcName
-- Breaking Changes: List any vs HC5
-- Idempotency: client-id | set-state | compare-and-set | send-id | locked-upsert | log-only | read-only | exempt — why
-- =====================================================================

-- 3. SET NOCOUNT and XACT_ABORT
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- 4. Wrap main body in TRY/CATCH
BEGIN TRY
    BEGIN TRANSACTION;
    -- logic here
    COMMIT TRANSACTION;
    SELECT 1 AS Success, NULL AS ErrorMessage;  -- standard success envelope
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;  -- standard error envelope
END CATCH
```

### TRY/CATCH is mandatory on EVERY SP — no exceptions

This is non-negotiable and applies to **read SPs too**, not just writes. An SP whose body
is not wrapped in TRY/CATCH turns any runtime error (timeout, deadlock, transient, bad
data) into a **raw HTTP 500 with NO `HC.ErrorLog` record** — silent and undiagnosable. An
audit on 2026-07-19 found 28 API-facing SPs missing it; they were all retrofitted. Do not
add another.

Rules for the wrapper:
- **Placement:** put `BEGIN TRY` *after* the `ValidateAppAuth` / `ValidatePortalAuth` error
  block and any pre-flight param/permission checks that do their own graceful `RETURN` —
  those stay OUTSIDE the TRY. Put `END TRY`/`CATCH` at the very end of the proc. A `GO` can
  never appear between `BEGIN TRY` and `END CATCH`.
- **Write SP** (has a success envelope): CATCH rolls back and returns the standard error
  envelope (`SELECT 0 AS Success, ERROR_MESSAGE() …`) — the template above.
- **Read SP** (returns data rowsets, no success envelope): the CATCH must still LOG then
  re-raise, so behaviour is unchanged for the client but the error is recorded:
  ```sql
  END TRY
  BEGIN CATCH
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
      INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
      VALUES (NEWID(), '<unknown>', 'Unhandled error in <procShortName>',
              ERROR_MESSAGE(), @procName, @userId);   -- @userId → NULL if unauthenticated
      THROW;
  END CATCH
  ```
  Use the proc-name variable the SP actually declares (`@procName` / `@effectiveProcName` /
  `@procName_self`, or `OBJECT_NAME(@@PROCID)` if none), and `@userId` or `NULL`.
- **Every CATCH must log to `HC.ErrorLog`** so the failure is diagnosable server-side.
- The API shims also log, so a CATCH that RE-THROWS, or returns the
  `Success = 0` envelope with `ERROR_MESSAGE()`, is traced too (the shim
  writes the row, without the SP's own context). Since 2026-10-13 every shim
  writes a THROWN error to `HC.ErrorLog` as well. Check with:
  ```bash
  python3 tools/catch_log_scan.py     # MUST print nothing
  ```

### Never roll back an error log — `ROLLBACK` comes BEFORE the `INSERT HC.ErrorLog`

An `INSERT HC.ErrorLog` written *inside* an open transaction that the same block
then rolls back is **erased by that rollback**. The client still receives an
`errorId`, so everything looks logged, but the row is gone and the failure is
invisible to every log review. This is worse than not logging at all: it looks
like the SP has no such error.

Found 2026-09-06 in `hcapp_processPayment` and 4 other SPs (8 sites). It hid a
broken self check-in payment path for seven weeks.

**Rule:** in any error branch inside a transaction, `ROLLBACK TRANSACTION;`
comes FIRST, then log, then return the envelope:

```sql
IF (@allowed = 0)
BEGIN
    SET @errorCode = 1340; SET @errorType = 13; SET @errorId = NEWID();
    ROLLBACK TRANSACTION;                       -- ← FIRST: the log must survive
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Not authorised', '...', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, ... ;
    RETURN;
END
```

The same applies in a CATCH block: roll back, then log, then `THROW` or return
the error envelope — never log first. Where a validation can be done *before*
`BEGIN TRANSACTION`, prefer that: no rollback to get wrong.

---

## Code Quality Rules (SQL)

**Always use:**
- `LEN()` for string length checks (not `DATALENGTH`)
- `DECIMAL(10,4)` for monetary values (not `FLOAT`)
- `CREATE OR ALTER PROCEDURE` (not `CREATE` or `ALTER` alone)
- `SMALLINT` for boolean columns — `0` = false, `1` = true

**Never use:**
- `BIT` — never in new columns, SP parameters, or table definitions. Use
  `SMALLINT` instead. The only exception is the pre-existing `deleted BIT NOT NULL`
  column on core HC tables (HC.Event, HC.Hasher, HC.Kennel, etc.) — this column
  is staying as-is and SP parameters that map to it should use `SMALLINT` (SQL
  Server converts implicitly).

**ALTER TABLE on synced tables — disable triggers first:**

Tables that participate in the mobile sync have an `UpdatedAt` trigger. If that
trigger is active when you run `ALTER TABLE ... ADD COLUMN`, SQL Server fires it
against **every row**, stamping a current `UpdatedAt` on all of them. The sync
system then treats every row as recently modified and forces a full re-sync to
all clients — unnecessary load for every user.

**Rule (James, 2026-10-09 — replaces the earlier "James must do it"):** Claude
runs the ALTER itself, inside one script that first `DISABLE TRIGGER`s the
table's `UpdatedAt` trigger (verify the name in `sys.triggers`), adds the
columns, and `ENABLE TRIGGER`s it again — idempotent (`IF COL_LENGTH(...) IS
NULL`), run once, then archived. Never an ALTER with the trigger live.

**Always flag as code smells:**
- Sentinel magic values (`-1`, `-2`, `'<null>'`, `-99.0`, `-999.0`)
- Inconsistent sentinel values across parameters in the same SP
- Parameters accepted but never used in the SP body (dead inputs)
- Logic called outside a transaction that could leave data inconsistent
- Stub logic (e.g. deletion path that does nothing)
- Wrong SP name in log/error messages
- `FLOAT` for money
- `DATALENGTH` for string checks
- Type or length mismatches between SP parameters and base table columns
- **An `NVARCHAR(n)` parameter that receives user text** — SQL Server silently
  truncates a parameter to its declared width: no error, no `HC.ErrorLog` row, a
  message that just ends. `@messageContent NVARCHAR(500)` cut the first admin-room
  announcement in half (2026-09-23). Declare such parameters `NVARCHAR(MAX)`, check
  `LEN()` against the column width, and return the error envelope; cap the client
  at the same number so the refusal is a backstop.
- **An SP parameter with NO default that a client might omit** — SQL refuses the
  call ("expects parameter '@x', which was not supplied") BEFORE the procedure
  runs: no `HC.ErrorLog` row, an empty 500 in the app, and the SP's own graceful
  "missing parameter" check is unreachable. Give every parameter a default and
  check for NULL inside; derive what can be derived (a kennel from an event).
  Rack of Lamb hit this 18 times renumbering a run on 2026-09-29.
- **SP body not wrapped in TRY/CATCH** — any runtime error becomes an unlogged raw 500
  (see "TRY/CATCH is mandatory" above). Flag on sight for reads AND writes.
- CATCH block that doesn't log to `HC.ErrorLog` (swallows the error with no server record)
- **`INSERT HC.ErrorLog` before a `ROLLBACK TRANSACTION` in the same block** — the
  rollback erases the log row it just wrote; the client gets an `errorId` for a row
  that does not exist (see "Never roll back an error log" above). Flag on sight.
- **A write SP with no `-- Idempotency:` header line**, or a create that mints `NEWID()` for a row the client asked for, or a bare delta (`+ @n`) a retry can double — see CLAUDE.md "Idempotent writes"; `python3 tools/idempotency_scan.py` MUST print nothing.
- Check-then-`INSERT` on a UNIQUE key without `WITH (UPDLOCK, HOLDLOCK)` on the existence
  check (concurrent duplicate-key 500), or a non-idempotent insert on a client-supplied id

---

### Archiving run-once database scripts

Migrations, data patches, and other run-once scripts must **not** sit alongside
deployable SPs — the deploy script would re-run them on every deploy.

Once a run-once script has been executed:
1. Move it to an `archive/` subdirectory within its current folder
   (e.g. `db/hc6/public-web/archive/`).
2. The deploy script globs are non-recursive, so archived scripts are never
   picked up again.
3. The file remains in git history for reference.

**Rule:** if a SQL file is not a `CREATE OR ALTER PROCEDURE`, it is a run-once
script and must be archived after it has been run.

---

## Table Schemas

Base table definitions are in `/db/schema/tables/`, ONE FILE PER TABLE,
GENERATED from the live database (`db/schema/tables/INDEX.md` lists them).
Always reference these when working on SPs — never assume column types
from memory. Each file has every column, default, key, index, foreign key,
check constraint and trigger; notes on a column (deprecated, meaning) sit
above it.

**Keep them current — this is Claude's job, without being asked (James,
2026-10-13).** Never edit these files by hand. After ANY run-once script
that changes a table — a column, index, constraint, trigger or column note
— run:

```bash
python3 tools/schema_dump.py           # rewrite what changed
python3 tools/schema_dump.py --check   # drift only, exit 1 (the SP deploy runs this too)
```

and commit the regenerated files WITH the run-once script. A note about a
column goes into the database as `MS_Description`
(`sp_addextendedproperty`), never into the file, so it survives the next
regeneration. Until 2026-10-13 the files were a March SSMS script: 27 of
65 lacked 293 live columns and 22 tables had none, and an SP review took
widths from them and raised false alarms.

The most important tables for portal SPs:
- `HC.Event` — core event data
- `HC.Kennel` — club/kennel data
- `HC.Hasher` — user/member data
- `HC.HasherKennelMap` — membership relationships
- `HC.HasherEventMap` — attendance data
- `HC.ErrorLog` — error logging
- `LOG.GeneralLog` — general audit logging
