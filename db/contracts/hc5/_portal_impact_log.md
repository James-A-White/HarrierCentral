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

## 4. Removed Dead Parameters

These parameters will be removed in HC6. The portal should stop sending them:

| SP | Parameters to Remove |
|----|---------------------|
| `addEditEvent2` | @ipAddress, @ipGeoDetails, @isAdmin |
| `getSongs` | @hcVersion, @hcBuild |
| `toggleKennelSong` | @hcVersion, @hcBuild |
| `test` | @publicHasherId, @accessToken, @ipAddress, @ipGeoDetails |

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

4. **LOG.GeneralLog table schema**: Missing from repo. Needs to be exported before we can fully validate logging side-effects in HC6.

5. **Datetime conversion hack**: `getEvent` and `getEvents` convert datetimeoffset to datetime2, losing timezone info. HC6 should return proper UTC — but does the portal expect local time?
