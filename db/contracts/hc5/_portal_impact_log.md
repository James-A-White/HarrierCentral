# Portal Impact Log — HC5 → HC6 Migration

Items that will require changes in the Flutter Web Portal when SPs are migrated to HC6.
Organized by impact type.

---

## 1. New Error Handling Envelope

**Affects: ALL portal API calls**

HC6 SPs will return a standard success/error envelope:
```
Success: { Success: 1, ErrorMessage: NULL }
Error:   { Success: 0, ErrorMessage: "..." }
```

HC5 returns ad-hoc error rowsets with `errorType` codes. The portal currently handles:
- errorType 2 (validation)
- errorType 3 (auth)
- Multiple error rowsets possible (non-short-circuiting validation)

**Portal action**: Update the API response parser to handle the new envelope format. The old multi-rowset error pattern goes away — HC6 will short-circuit on first error.

---

## 2. Sentinel Value Harmonization

### Geographic "Set to NULL" Sentinel
HC5 is inconsistent:
- `addEditEvent2`: -99.0 (lat), -999.0 (lon)
- `editKennel`: 999 (both)

**HC6 decision: Use -999.0 for all geographic "set to NULL" sentinels.**
SQL NULL cannot be used here because NULL means "no change" (don't touch this field). The sentinel is needed to distinguish "the user explicitly cleared this value" from "the user didn't edit this field". -999.0 is safely outside valid lat (-90 to 90) and lon (-180 to 180) ranges.

**Portal action**: Update event and kennel edit forms to send -999.0 for both latitude and longitude when the user clears the value.

### "No Change" Sentinel for evtDisseminateAllowWebLinks
HC5 `addEditEvent2` uses **2** where it should use **-2**.

**HC6 fix**: Change to -2 for consistency.

**Portal action**: Update addEditEvent2 call to send -2 instead of 2 for "set to NULL".

### Membership Expiration "Never Expires"
HC5 uses `2100-01-01`. This is consistent across `bulkAddHashers` and `updateKennelHasher`.

**HC6 decision: Change from `2100-01-01` to `2999-12-31` for "never expires".**
MembershipExpirationDate carries three business states:
- **NULL** = not a member of this kennel
- **A real date** = member with expiring (or expired) membership
- **2999-12-31** = member, never expires (lifetime/permanent membership)

Additionally, HC6 introduces a generic "set date to NULL" sentinel: **`1970-01-01`** (Unix epoch). This is available for any edit SP that needs to let callers explicitly clear a date field. Currently no UI case requires clearing MembershipExpirationDate to NULL (a past date has the same business effect), but the sentinel is standardized for all date parameters.

**Portal action**: Update any code that sends `2100-01-01` to send `2999-12-31` instead. This affects `bulkAddHashers` and `updateKennelHasher` calls.

**Data migration**: Existing `2100-01-01` values in HasherKennelMap.MembershipExpirationDate should be updated to `2999-12-31` as part of the HC6 cutover.

---

## 3. Parameter Type Changes

These type corrections in HC6 will require the portal to send data differently:

### addEditEvent2
| Parameter | HC5 | HC6 | Portal Change |
|-----------|-----|-----|---------------|
| @eventPriceForMembers | FLOAT | DECIMAL(10,4) | Ensure decimal formatting (no floating point quirks) |
| @eventPriceForNonMembers | FLOAT | DECIMAL(10,4) | Same |
| @eventPriceForExtras | FLOAT | DECIMAL(10,4) | Same |
| @deleted | SMALLINT | BIT | Send 0/1 only (no other integers) |
| @integrationEnabled | SMALLINT | INT | Minor — widen from SMALLINT to INT |
| @eventName | NVARCHAR(120) | NVARCHAR(250) | Update max-length validation in form |
| @locationPostCode | NVARCHAR(50) | NVARCHAR(250) | Update max-length validation in form |

### updateKennelHasher — String-to-Typed Parameters
HC5 accepts NVARCHAR for everything. HC6 should use proper types:

| Parameter | HC5 | HC6 (proposed) | Portal Change |
|-----------|-----|----------------|---------------|
| @isMember | NVARCHAR | BIT | Send 0/1 not string |
| @status | NVARCHAR | BIT | Send 0/1 not string |
| @emailAlerts | NVARCHAR | SMALLINT/INT | Send integer not string |
| @notifications | NVARCHAR | SMALLINT/INT | Send integer not string |
| @historicTotalRuns | NVARCHAR | INT | Send integer not string |
| @historicHaring | NVARCHAR | INT | Send integer not string |
| @historicCountsAreEstimates | NVARCHAR | BIT | Send 0/1 not string |
| @firstName | NVARCHAR(150) | NVARCHAR(250) | Update max-length validation |
| @lastName | NVARCHAR(150) | NVARCHAR(250) | Update max-length validation |

### editKennel
| Parameter | HC5 | HC6 | Portal Change |
|-----------|-----|-----|---------------|
| @kennelUniqueShortName | NVARCHAR(25) | NVARCHAR(50) | Update max-length validation |
| @disseminateOnGlobalGoogleCalendar | INT | SMALLINT | Ensure values fit SMALLINT range |

### regenerateExtApiKey
| Parameter | HC5 | HC6 | Portal Change |
|-----------|-----|-----|---------------|
| @publicKennelId | NVARCHAR(250) | UNIQUEIDENTIFIER | Send as GUID format, not arbitrary string |


---

## 4. Removed Parameters

### @ipAddress and @ipGeoDetails — Removed from ALL SPs

These parameters are being removed from **all 22 portal SPs** that had them (every SP except `test`, which already had them removed as dead inputs). Request logging and IP capture are moving to the .NET API shim. See `_api_impact_log.md` for full details on the shim's new logging responsibilities.

**Portal action**: The portal does not send these directly (the shim injects them), so no portal code change is needed. Listed here for completeness.

### Other Removed Parameters

These parameters were dead inputs or redundant and are removed in HC6:

| SP | Parameters to Remove | Reason |
|----|---------------------|--------|
| `addEditEvent` (was addEditEvent2) | `@isAdmin` | Declared/set but never used in logic |
| `addEditEvent` (was addEditEvent2) | `@deleted` | Deletion path removed; use `deleteEvent` exclusively |
| `getSongs` | `@hcVersion`, `@hcBuild` | Dead inputs (never used in SP body) |
| `toggleKennelSong` | `@hcVersion`, `@hcBuild` | Dead inputs (never used in SP body) |
| `test` | `@publicHasherId`, `@accessToken` | Dead inputs (no auth validation performed) |

**Portal action**: Remove these from API call payloads. If the .NET shim auto-maps parameters, unused params may cause errors when the SP no longer declares them.

---

## 5. Authentication Fixes

### getEvent — Token Validation Will Be Enforced
HC5 has token validation **commented out**. HC6 will enforce it.

**Portal action**: Ensure `getEvent` calls include valid `@accessToken`. If the portal currently skips token generation for this call (because HC5 doesn't check), it must start sending valid tokens.

### updateFcmToken — Token Validation Will Be Enforced
Same as above — HC5 has it commented out, HC6 will enforce.

**Portal action**: Ensure `updateFcmToken` calls include valid `@accessToken`.

### updateFcmToken — Inverted Validation Fixed
HC5 rejects valid service account GUIDs and accepts invalid ones. HC6 will fix this.

**Portal action**: If the portal works around this bug by sending a non-service-account GUID, update to send the correct one.

---

## 6. Obsolete Column Removal

**HC6 decision: Remove `eventChatMessageCount` / `EventChatMessageCount`.**

Removed from both `getEvents` (both summary and full detail rowsets) and `sendEventMessage`. These were hardcoded to 0 since v2.1.3 and served no purpose.

**Portal action**: Remove any references to this column. The portal reads columns by name (not ordinal position), so removing columns from SPs will not break other column references.

---

## 7. Deletion Path (addEditEvent2)

HC5 deletion path is a **stub** — it opens a transaction, does nothing, commits, and returns "Deletion processed".

**HC6 decision: Remove the deletion path from addEditEvent2. Use `deleteEvent` exclusively.**
The `@deleted` parameter will be removed from HC6's addEditEvent SP. All deletion logic lives in `deleteEvent`, which already implements proper soft-delete with attendance checks.

**Portal action**: Ensure all event deletion calls go through `deleteEvent`, not `addEditEvent2`. Remove any code that sends `@deleted = 1` to addEditEvent.

---

## 8. Silent Empty Return → Explicit Error

### confirmAuthentication
HC5 returns **no rowset at all** when no matching auth request is found. HC6 will return the standard error envelope.

**Portal action**: Update the "no QR match found" handling from "empty response" to "error envelope with message".

---

## 9. Items Requiring Investigation

These need clarification before HC6 migration:

1. ~~**Magic GUIDs**~~: **Resolved.** `22222222-2222-2222-2222-222222222222` = admin portal (`HC_ADMIN_PORTAL_INTERNAL_USER_ID` in Flutter). `11111111-1111-1111-1111-111111111111` = public/HashRuns.org.

2. ~~**Permission bitmask `0x40000019`**~~: **Resolved.** = authIsSuperAdmin | authCanManageMembers | authCanManageHashCash | authIsAdmin. Full flag definitions documented in cross-cutting notes.

3. **Message releasability bit flags**: The SP uses simple low flags (0x0001-0x0020) but Flutter defines a different scheme with a `0x100000000` high-bit prefix. Not fully implemented yet — will need reconciliation when chat infrastructure is built out in HC6. Do not change SP flags until then.

4. ~~**LOG.GeneralLog table schema**~~: **Resolved.** Now in repo at `db/schema/tables/LOG.GeneralLog.Table.sql`. 5 columns: idx, LogSource (NVARCHAR(50)), Message (NVARCHAR(255)), StrParam1, Data (NVARCHAR(4000)), Timestamp.

5. **Datetime conversion hack**: `getEvent` and `getEvents` convert datetimeoffset to datetime2, losing timezone info. **Context**: Originally the system didn't need timezone awareness, but Google Calendar and push notification integrations required it. Migration to UTC + timezone offset is in progress, but many UIs still expect local time. **HC6 approach**: Return both representations — the proper DATETIMEOFFSET column for new/updated clients, plus a computed DATETIME2 (local time) column for backward compatibility. Portal screens migrate individually; legacy column dropped when all screens are updated. Decision deferred to per-SP migration.

---

## 10. Presentation Logic Moved to Portal

**Affects: `getCategoryDetail` and `getCategoryDetail2` consumers**

### What changed

HC5 `getCategoryDetail` returns a single `message` column containing a pre-formatted string with embedded time-ago formatting (e.g. `"(5 min) John Smith  ---  London, England"`). HC5 `getCategoryDetail2` returns 6 generic columns (`col1`-`col6`) with the time-ago formatting pre-computed in `col1` and other data pre-formatted as strings.

**HC6 has already made this change — both SPs now return raw typed columns.** The portal is responsible for all time-ago formatting and string concatenation. This is a breaking change from HC5.

### Time-ago formatting

HC5/HC6 SPs compute relative timestamps in SQL:
- Less than 60 minutes: `"Xm ago"` (getCategoryDetail2) or `"(X min)"` (getCategoryDetail)
- Less than 24 hours: `"Xh XXm ago"` or `"(X:XX)"`
- 1+ days: `"Xd ago"` or `"(X day)"`

When the portal takes over formatting, it must implement equivalent logic in Flutter using the `createdAt`/`updatedAt` timestamp column returned by each category.

### Column layout per category (getCategoryDetail2)

Each category uses the 6-column grid differently. The header rowset defines column names:

| Category | col1 | col2 | col3 | col4 | col5 | col6 |
|----------|------|------|------|------|------|------|
| 0 - New Hashers | Time | Name | Location | - | - | - |
| 1 - Event RSVPs | Time | Kennel | Run # | Hasher | Status | Runs / Hares |
| 2 - New Events | Time | Source | Kennel | Run # | Event Date | Event Name |
| 3 - New Kennels | Time | Kennel | Location | - | - | - |
| 4 - App Logins | Time | Name | Device | OS | Location | - |
| 5 - Payments | Time | Event | Hasher | Processed By | Amount | Type |
| 6 - Portal Access | Time | Name | Kennel | - | - | - |
| 7 - Errors | Time | Error | User | Stored Proc | - | - |
| 8 - HashRuns.Org | Time | Location | Page | Kennel | Event | - |
| 100 - Version Adoption | Time | Logins | This Ver | Name | Version | Platform |

("-" = empty string, column unused for that category)

### getCategoryDetail (single-message format)

`getCategoryDetail` concatenates all data into one `message` string per row, alongside a `createdAt` timestamp. When the portal takes over formatting, it will need to parse raw data columns instead of a pre-built string. This is a **significant change** — the current portal code parses a single `message` column.

### Portal action

**This change is live in HC6.** Before cutover, the portal must:
1. Implement time-ago formatting in Flutter using the raw timestamp column returned per category
2. For `getCategoryDetail`: read the raw typed columns instead of a single `message` string — see the HC6 contract for the exact column set per category
3. For `getCategoryDetail2`: the `col1`-`col6` header metadata rowset has been removed — HC6 returns the same raw typed columns as `getCategoryDetail`
4. Reference the HC6 contracts (`/db/contracts/hc6/`) for exact column definitions per category

---

## 11. KennelSongMap Bug Fix (No Portal Action Required)

**Affects: `getSongs` and `toggleKennelSong`**

Both HC5 SPs had a logic error where `HC.KennelSongMap.KennelId` (which stores the internal `HC.Kennel.id`) was compared against `@publicKennelId` (the public GUID) directly. This meant:
- `getSongs` always returned `isInKennel = 0` for every song regardless of the kennel's actual library
- `toggleKennelSong` never wrote any rows — add/remove operations silently had no effect

The bug has been fixed in both HC5 (applied to live DB, 2026-03-15) and HC6. The external interface is unchanged — same parameters, same rowset shape. The SP now simply returns correct results.

**Portal action**: None. However, be aware that once HC6 is deployed, `getSongs` will start returning `isInKennel = true` for songs that are genuinely in the kennel's library (as intended). If any portal code made assumptions based on the broken behavior, it should be reviewed.

---

## 12. Auth Helper (Internal Change, No Portal Impact)

**Affects: No portal code changes required**

HC6 introduces `HC6.ValidatePortalAuth`, an internal helper SP that consolidates the ~15-30 lines of inline auth validation (publicHasherId NULL check + `HC.CHECK_PORTAL_ACCESS_TOKEN` call) that was duplicated in every HC5 portal SP.

This is purely an internal database refactor. The portal still sends the same `@publicHasherId` and `@accessToken` parameters to every SP. The SPs still validate auth the same way — they just delegate to the helper instead of inlining the logic.

**Portal action**: None. No change to request payloads or response handling.

---

*Last updated: 2026-03-15*
