# Cross-Cutting Notes — HC5 Portal SP Contract Extraction

Patterns and issues observed across all 23 portal SPs during contract extraction.
These notes inform the second-pass review and HC6 migration.

---

## Structural Patterns

### Universal (all 23 SPs)
- **No `SET XACT_ABORT ON`** — runtime errors won't auto-rollback
- **No `TRY/CATCH`** — errors propagate unhandled to caller
- **Validation doesn't short-circuit** (17 of 23 SPs) — each failed check SELECTs an error rowset but doesn't RETURN, so callers may receive multiple error rowsets
- **Standard auth pattern**: `@publicHasherId` + `@accessToken` validated via `HC.CHECK_PORTAL_ACCESS_TOKEN`
- **Standard error rowset**: errorId, errorType, errorTitle, errorUserMessage, debugMessage, errorProc
  - errorType 2 = validation, 3 = auth, 4 = concurrent modification (addEditEvent2 only), 5 = unhandled DB error (addEditEvent2 only)
- **`DATALENGTH` for GUID validation**: `DATALENGTH(@publicHasherId) != 16` — technically correct for UNIQUEIDENTIFIER but inconsistent with string validation where LEN should be used

### No Transaction Wrapping (11 SPs with write operations)
These SPs modify data without transaction protection:
- `addEditEvent2` — nonApi_updateRunNumbers called *after* commit
- `bulkAddHashers` — cursor INSERT/UPDATE loop, nonApi_updateRunCounts called per iteration
- `confirmAuthentication` — Device INSERT
- `deleteEvent` — Event UPDATE
- `editKennel` — Kennel UPDATE
- `getLandingPageData` — Device UPDATE + PortalAccess INSERT
- `regenerateExtApiKey` — Kennel UPDATE
- `sendEventMessage` — EventMessage INSERT
- `toggleKennelSong` — KennelSongMap INSERT/UPDATE
- `updateFcmToken` — Device UPDATE
- `updateKennelHasher` — HasherKennelMap + Hasher UPDATEs

### Shared Functions/SPs Called
- `HC.CHECK_PORTAL_ACCESS_TOKEN` — auth (nearly all SPs)
- `HC.nonApi_updateRunNumbers` — addEditEvent2
- `HC.nonApi_updateRunCounts` — bulkAddHashers
- `HC.nonApi_updateRunCountsByUser` — updateKennelHasher

---

## Common Code Smells

### Wrong SP Name in Log Messages (8 SPs)
Copy-paste errors in LOG.GeneralLog entries:

| SP | Logs As |
|----|---------|
| `addEditEvent2` | "hcportal_addEditEvent" (missing '2') |
| `editKennel` | "hcportal_addEditEvent" |
| `getCategoryDetail2` | "hcportal_getCategoryDetail" (missing '2') |
| `getEventMessages` | "hcportal_getKennelHashers" |
| `getLandingPageData` | "hcportal_getKennelHashers" |
| `getUsageData` | "hcportal_getKennelHashers" |
| `sendEventMessage` | "hcportal_getKennelHashers" |
| `updateFcmToken` | "hcportal_confirmAuthentication" |

### Authentication Bypasses (3 SPs)
- `getEvent` — token validation **commented out** (lines 148-164)
- `updateFcmToken` — token validation **commented out** (lines 61-76), plus validation logic is **inverted** (rejects valid service account GUIDs)
- `test` — accepts auth params but performs no validation

### Dead Inputs
Truly unused (not even for logging):
- `addEditEvent2` — @ipAddress, @ipGeoDetails
- `getSongs` — @hcVersion, @hcBuild
- `test` — @publicHasherId, @accessToken, @ipAddress, @ipGeoDetails
- `toggleKennelSong` — @hcVersion, @hcBuild

Dead variables:
- `addEditEvent2` — @isAdmin declared/set, never used
- `editKennel` — @isAdmin only used in wrong log message
- `getKennel` — @isAdmin only used in log source prefix

### Commented-Out Debug Code
Nearly all SPs contain commented-out EXEC statements with hardcoded GUIDs, `SELECT 'Step N'` debug outputs, or old feature code. Security concern if GUIDs are production values.

### Stub/Incomplete Logic
- `addEditEvent2` — deletion path (@deleted = 1) is a stub. **HC6 decision: remove it entirely, use `deleteEvent` SP exclusively.** The @deleted parameter will be removed from HC6's addEditEvent.
- `updateKennelHasher` — nonApi_updateRunCountsByUser call is commented out for haring updates

### Column Safety
The portal reads rowset columns by **name, not ordinal position**. Adding or removing columns from SP rowsets will not break other column references.

### Obsolete Columns — Removed in HC6
- `sendEventMessage` — EventChatMessageCount removed (was hardcoded to 0 since v2.1.3)
- `getEvents` — eventChatMessageCount removed from both summary and full detail rowsets (was hardcoded to 0)

---

## Sentinel Value Inventory

### "No Change" / "Set to NULL" Sentinel Convention
Write SPs use a two-tier system because SQL NULL means "don't touch this field":
- **NULL / not passed** = "no change" — the caller is not editing this field
- **Sentinel value** = "the user explicitly set this to empty/none"

Common sentinels: **-1 = "no change"** (alternative to NULL), **-2 = "set to NULL"**

**Exception**: `addEditEvent2` — `evtDisseminateAllowWebLinks` uses **2** instead of -2

### Geographic Sentinels
HC5 is inconsistent — **HC6 standardizes on -999.0** for all geographic "set to NULL":

| SP | Parameter | HC5 Value | HC6 Value |
|----|-----------|-----------|-----------|
| `addEditEvent2` | @hcLatitude | -99.0 | -999.0 |
| `addEditEvent2` | @hcLongitude | -999.0 | -999.0 (no change) |
| `editKennel` | latitude/longitude | 999 (positive) | -999.0 |

### Date Sentinels
**HC6 standard date sentinels:**
- **`2999-12-31`** = "never expires" (replaces HC5's `2100-01-01`)
- **`1970-01-01`** = "set this date to NULL" (generic sentinel for clearing date fields during edits)

MembershipExpirationDate has three business states:
- **NULL** = not a member (has real business meaning, unlike edit params where NULL = "no change")
- **A real date** = member with expiring membership
- **2999-12-31** = member, never expires (lifetime/permanent)

HC5 used `2100-01-01` for never-expires in `bulkAddHashers` and `updateKennelHasher`. HC6 changes this to `2999-12-31` for clarity.

The `1970-01-01` sentinel (Unix epoch) is available for any edit SP that needs to let callers explicitly clear a date field. Currently no UI case requires clearing MembershipExpirationDate to NULL (a past date has the same business effect), but the sentinel exists for future use across all date parameters.

### Numeric Sentinels
- `999` = "all time" for @weeksToDisplay — `getEvents`
- `2880` minutes (48 hours) = recent events window — `getUsageData`
- `AttendenceState >= 20` = "checked in" — `deleteEvent`

### Magic GUIDs (Service Accounts)
Used across 5+ SPs:
- `11111111-1111-1111-1111-111111111111` — public/HashRuns.org service account (non-admin)
- `22222222-2222-2222-2222-222222222222` — admin portal service account (`HC_ADMIN_PORTAL_INTERNAL_USER_ID` in Flutter code)

### Magic Coordinates
- Latitude `51.503300000` — London default, used to exclude default-location kennels in `getCategoryDetail`/`getCategoryDetail2`

### Permission Bitmasks
AppAccessFlags bit definitions (from Flutter constants):
- `0x00000001` — authIsAdmin
- `0x00000002` — authCanManageKennel
- `0x00000004` — authCanManageRuns
- `0x00000008` — authCanManageHashCash
- `0x00000010` — authCanManageMembers
- `0x00000020` — authCanManageAwards
- `0x00000040` — authCanManageSongs
- `0x40000000` — authIsSuperAdmin
- `0x0000007f` — authAllFlags (all non-super flags)

Composite masks used in SPs:
- `0x40000019` = authIsSuperAdmin | authCanManageMembers | authCanManageHashCash | authIsAdmin — used in `getKennelHashers` and `regenerateExtApiKey`

### Message Releasability Bit Flags
HC5 SP (`sendEventMessage`) currently uses simple low flags:
- `0x0001` = Admins, `0x0002` = Committee, `0x0004` = Members, `0x0008` = Subscribers, `0x0010` = Former Members, `0x0020` = Everyone

Flutter code defines a different scheme (partially implemented, for future chat infrastructure):
- `0x100000001` = Mismanagement (admins)
- `0x100000002` = Members
- `0x100000004` = Followers
- `0x100000008` = Local Hashers
- `0x100000010` = Everyone

Note: Flutter flags use a `0x100000000` high-bit prefix plus the low flag. The SP flag checking will need to be reconciled with the Flutter constants when chat is fully implemented in HC6.

---

## Table Schema Observations

### Type Mismatches (Parameter vs Table Column)

| SP | Parameter | SP Type | Table Type |
|----|-----------|---------|------------|
| `addEditEvent2` | @eventName | NVARCHAR(120) | NVARCHAR(250) |
| `addEditEvent2` | @locationPostCode | NVARCHAR(50) | NVARCHAR(250) |
| `addEditEvent2` | @eventPriceFor* | FLOAT | DECIMAL(10,4) |
| `addEditEvent2` | @deleted | SMALLINT | BIT |
| `addEditEvent2` | @integrationEnabled | SMALLINT | INT |
| `confirmAuthentication` | @qrCodeData | NVARCHAR(250) | NVARCHAR(100) |
| `editKennel` | @disseminateOnGlobalGoogleCalendar | INT | SMALLINT |
| `editKennel` | @kennelUniqueShortName | NVARCHAR(25) | NVARCHAR(50) |
| `regenerateExtApiKey` | @publicKennelId | NVARCHAR(250) | UNIQUEIDENTIFIER |
| `regenerateExtApiKey` | @currentExtApiKey | NVARCHAR(1000) | NVARCHAR(120) |
| `updateFcmToken` | @fcmToken | NVARCHAR(1000) | NVARCHAR(500) |
| `updateKennelHasher` | @firstName | NVARCHAR(150) | NVARCHAR(250) |
| `updateKennelHasher` | @lastName | NVARCHAR(150) | NVARCHAR(250) |

### String Parameters for Non-String Data
`updateKennelHasher` passes boolean/integer values as NVARCHAR:
- @isMember, @status, @emailAlerts, @notifications, @historicTotalRuns, @historicHaring, @historicCountsAreEstimates

### LOG.GeneralLog Schema (now in repo)
Referenced by every SP for audit logging. Columns: `idx` (INT IDENTITY PK), `LogSource` (NVARCHAR(50)), `Message` (NVARCHAR(255)), `StrParam1` (NVARCHAR(500)), `Data` (NVARCHAR(4000)), `Timestamp` (DATETIMEOFFSET(7), default GETDATE()). Note: `LogSource` is only 50 chars — the wrong SP names in log messages still fit but should be fixed in HC6.

### Datetime / Timezone Migration
HC5 uses `CONVERT(datetime2, datetimeoffset)` to strip timezone info and return local time. This was fine before Google Calendar and push notification integrations required timezone awareness. Migration to UTC + offset is in progress but many UIs still expect local time. **HC6 approach**: return both a DATETIMEOFFSET column (source of truth) and a computed DATETIME2 column (backward compat) so portal screens can migrate individually. Affects `getEvent` and `getEvents` primarily. Decision handled per-SP during HC6 migration.

### Performance Anti-Patterns
- `getCategoryDetail` / `getCategoryDetail2` — READ UNCOMMITTED + NOLOCK + OPTION(RECOMPILE) on all queries
- `confirmAuthentication` — TRIM(LOWER()) on scanData forces table scan
- `getEvents` — 22+ OR conditions with TRIM(LOWER(REPLACE())) in geographic WHERE clause forces table scan
- `bulkAddHashers` — cursor-based processing instead of set-based operations
