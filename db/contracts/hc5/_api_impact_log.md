# API Shim Impact Log — HC5 to HC6 Migration

Items that will require changes in the .NET Azure Function API shim when SPs are migrated to HC6.
Organized by responsibility area.

---

## 1. Request Logging (NEW Responsibility)

**Affects: ALL portal SP calls**

HC5 SPs logged every call internally via `INSERT INTO [LOG].[GeneralLog]`. HC6 SPs no longer do this — the shim must take over request logging.

**What HC5 did per SP:**
```sql
INSERT INTO [LOG].[GeneralLog]
    ([LogSource], [Message], [Data], [Timestamp])
VALUES (
    'Admin Portal: hcportal_<spName>',
    COALESCE(@ipAddress, '<no IP address>'),
    COALESCE(@ipGeoDetails, '{ "ip": "<no IP address>", ... }'),
    @now
)
```

**What the shim must now do:**
- Log every SP call to `LOG.GeneralLog` (or a new structured logging system) with:
  - `LogSource`: `'Admin Portal: hcportal_<spName>'` (NVARCHAR(50) — keep the same format for dashboard compatibility)
  - `Message`: caller's IP address from the HTTP request context (NVARCHAR(255))
  - `Data`: IP geolocation JSON from the HTTP request context (NVARCHAR(4000))
  - `Timestamp`: current UTC time (DATETIMEOFFSET(7))
- The IP address and geolocation data must be extracted from the HTTP request context — these values are no longer passed as SP parameters
- Note: 8 HC5 SPs logged the **wrong SP name** in LogSource (see cross-cutting notes). The shim can now log the correct name since it knows which SP it is calling.

**LOG.GeneralLog schema** (for reference):
| Column | Type | Notes |
|--------|------|-------|
| idx | INT IDENTITY | PK, auto-increment |
| LogSource | NVARCHAR(50) | e.g. `'Admin Portal: hcportal_getKennel'` |
| Message | NVARCHAR(255) | IP address string |
| StrParam1 | NVARCHAR(500) | Nullable, not used by portal logging |
| Data | NVARCHAR(4000) | IP geolocation JSON |
| Timestamp | DATETIMEOFFSET(7) | Default GETDATE() |

---

## 2. Error Logging (NEW Responsibility)

**Affects: ALL portal SP calls that return an error envelope**

HC5 SPs logged errors internally via `INSERT HC.ErrorLog`. HC6 SPs no longer do this — the shim must take over error logging.

**What HC5 did per SP (on validation/auth failure):**
```sql
INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, string_1)
VALUES (NEWID(), '<unknown>', 'Error name here',
    'Description of what went wrong',
    OBJECT_NAME(@@PROCID), @publicHasherId, @accessToken)
```

**What the shim must now do:**
- When an SP returns the error envelope (`Success = 0`), log to `HC.ErrorLog`
- The shim has all the context it needs:
  - `id`: generate a new GUID
  - `HcVersion`: use a shim-level constant (e.g. `'HC6-API'`)
  - `ErrorName`: derive from SP name + error type (e.g. `'Auth failure'`, `'Validation error'`)
  - `ErrorDescription`: the `ErrorMessage` value from the error envelope
  - `ProcName`: the SP name the shim just called
  - `userId`: the `@publicHasherId` from the request (if available)
  - `string_1`: optional — could store the access token for auth failures (for debugging)

**HC.ErrorLog schema** (for reference):
| Column | Type | Notes |
|--------|------|-------|
| serial | INT IDENTITY | PK |
| id | UNIQUEIDENTIFIER | NOT NULL, default NEWID() |
| HcVersion | NVARCHAR(250) | NOT NULL, default `'pre 0.6.4'` |
| ErrorName | NVARCHAR(250) | Nullable |
| ErrorDescription | NVARCHAR(2500) | Nullable |
| ProcName | NVARCHAR(250) | Nullable |
| userId | UNIQUEIDENTIFIER | Nullable |
| kennelId | UNIQUEIDENTIFIER | Nullable |
| eventId | UNIQUEIDENTIFIER | Nullable |
| deviceId | NVARCHAR(250) | Nullable |
| string_1 | NVARCHAR(4000) | Nullable |
| string_2 | NVARCHAR(1000) | Nullable |
| string_3 | NVARCHAR(1000) | Nullable |
| string_4 | NVARCHAR(1000) | Nullable |
| errorCode | INT | Nullable |
| createdAt | DATETIMEOFFSET(7) | NOT NULL, default SYSUTCDATETIME() |
| updatedAt | DATETIMEOFFSET(7) | NOT NULL, default SYSUTCDATETIME() |
| deleted | BIT | NOT NULL, default 0 |

---

## 3. HC6 Error Envelope Handling

**Affects: ALL portal SP calls**

HC6 SPs return a standard success/error envelope. The shim needs to interpret this.

**Envelope format:**
```
Success: SELECT 1 AS Success, NULL AS ErrorMessage
Error:   SELECT 0 AS Success, 'message' AS ErrorMessage
```

**Shim behavior:**
1. After calling an SP, check the first rowset for a `Success` column
2. If `Success = 0`:
   - Log the error to `HC.ErrorLog` (see Section 2)
   - Return an appropriate HTTP error response to the caller (e.g. 400 for validation, 401 for auth)
   - The `ErrorMessage` column contains a human-readable message
3. If `Success = 1`:
   - For write SPs: the envelope row IS the response — forward it
   - For read SPs: the data rowsets follow the envelope (or are the only rowsets on success). Forward all data rowsets to the caller.

**Important nuance:** Some read SPs (e.g. `getKennel`, `getEvents`) return data rowsets directly on success — the envelope only appears on error (where it replaces the data). Write SPs (e.g. `addEditEvent`, `editKennel`) always return the envelope explicitly. The shim should check whether the first rowset contains a `Success` column to distinguish error responses from data responses.

---

## 4. Parameter Changes — @ipAddress and @ipGeoDetails Removed

**Affects: 22 of 23 portal SPs (all except `test`)**

The `@ipAddress` and `@ipGeoDetails` parameters have been removed from all HC6 portal SPs. The `test` SP never had them in HC6 (they were already removed as dead inputs).

The shim must **stop passing** these parameters when calling HC6 SPs. If the shim auto-maps request parameters to SP parameters, it should either:
- Remove them from the parameter mapping, or
- Gracefully handle the fact that the SP no longer declares them

**Full list of affected SPs:**

| # | SP Name |
|---|---------|
| 1 | `hcportal_addEditEvent` (was addEditEvent2) |
| 2 | `hcportal_bulkAddHashers` |
| 3 | `hcportal_confirmAuthentication` |
| 4 | `hcportal_deleteEvent` |
| 5 | `hcportal_editKennel` |
| 6 | `hcportal_getCategoryDetail` |
| 7 | `hcportal_getCategoryDetail2` |
| 8 | `hcportal_getCountries` |
| 9 | `hcportal_getEvent` |
| 10 | `hcportal_getEventMessages` |
| 11 | `hcportal_getEvents` |
| 12 | `hcportal_getKennel` |
| 13 | `hcportal_getKennelHashers` |
| 14 | `hcportal_getLandingPageData` |
| 15 | `hcportal_getLoginHistory` |
| 16 | `hcportal_getSongs` |
| 17 | `hcportal_getUsageData` |
| 18 | `hcportal_regenerateExtApiKey` |
| 19 | `hcportal_sendEventMessage` |
| 20 | `hcportal_toggleKennelSong` |
| 21 | `hcportal_updateFcmToken` |
| 22 | `hcportal_updateKennelHasher` |

**Not affected:** `hcportal_test` (params were already removed in HC6).

---

## 5. SP Rename

**Affects: 1 SP**

| HC5 Name | HC6 Name |
|----------|----------|
| `HC5.hcportal_addEditEvent2` | `HC6.hcportal_addEditEvent` |

The shim routing must be updated. If the portal calls the shim with the old name (`addEditEvent2`), the shim needs to map it to the new HC6 SP name (`addEditEvent`), or the portal must be updated first.

---

## 6. Other Removed Parameters

**Affects: specific SPs**

Beyond `@ipAddress` and `@ipGeoDetails` (Section 4), these parameters were also removed:

| SP | Removed Parameters | Reason |
|----|--------------------|--------|
| `hcportal_addEditEvent` (was addEditEvent2) | `@deleted` | Deletion now exclusively via `deleteEvent` SP |
| `hcportal_addEditEvent` (was addEditEvent2) | `@isAdmin` | Was declared/set but never used in logic |
| `hcportal_getSongs` | `@hcVersion`, `@hcBuild` | Were dead inputs (never used in SP body) |
| `hcportal_toggleKennelSong` | `@hcVersion`, `@hcBuild` | Were dead inputs (never used in SP body) |
| `hcportal_test` | `@publicHasherId`, `@accessToken` | Were dead inputs (no auth validation in test SP) |

The shim must stop sending these parameters. If the shim auto-maps from request payload to SP parameters, extra/unmapped parameters should be silently ignored (or the mapping should be updated).

---

## 7. New SP — HC6.ValidatePortalAuth

`HC6.ValidatePortalAuth` is an **internal helper SP**. It is called by other HC6 portal SPs to consolidate auth validation logic that was previously inlined in every SP (~15-30 lines of auth boilerplate per SP).

**The shim must NOT expose this SP as an API endpoint.** It is never called directly by the portal or any external client. If the shim has an allowlist of callable SPs, `ValidatePortalAuth` should not be on it. If it auto-discovers SPs by prefix, note that this SP does NOT have the `hcportal_` prefix — it uses the name `ValidatePortalAuth` specifically to distinguish it from API-facing SPs.

---

## 8. Migration Sequence Recommendation

The shim changes in Sections 1-3 (logging, error logging, envelope handling) are prerequisites for switching to HC6 SPs. Recommended sequence:

1. **Phase 1**: Implement error envelope handling (Section 3) — the shim must understand HC6 responses
2. **Phase 2**: Implement request logging in the shim (Section 1) — so no logging is lost when HC5 SPs are swapped out
3. **Phase 3**: Implement error logging in the shim (Section 2) — so error audit trail is preserved
4. **Phase 4**: Update parameter mappings (Sections 4, 5, 6) — remove deprecated params, update SP name
5. **Phase 5**: Switch SP calls from HC5 schema to HC6 schema

Phases 1-3 can be done while still calling HC5 SPs (the shim can dual-log alongside HC5's own logging). This allows testing before the cutover.

---

## 9. Auth Architecture Change — deviceId Replaces publicHasherId

**Affects: ALL portal SP calls**

### Summary

HC6 portal SPs no longer accept `@publicHasherId`. They now accept `@deviceId` instead. `HC6.ValidatePortalAuth` has been rewritten to perform a `HC.Device JOIN HC.Hasher` lookup using `@deviceId`, returning the resolved `@hasherId` (internal PK) and `@callerType` to the calling SP.

### Shim changes required

1. **Replace `@publicHasherId` with `@deviceId` in all SP call parameter mappings.** The portal will send `deviceId` in the request payload; the shim must pass it to the SP as `@deviceId`.

2. **Remove `@publicHasherId` from error logging.** The shim's `HC.ErrorLog` inserts (Section 2) currently record `@publicHasherId` as the `userId` field. Update to record the `@deviceId` value instead (or omit if hasher resolution failed).

3. **`confirmAuthentication` parameter rename:** The device being provisioned is now `@newDeviceId` (was `@deviceId`). The service account's device ID is now `@deviceId` (was authenticated by `@publicHasherId`). The shim must map correctly:
   - `deviceId` from request → SP param `@deviceId` (service account auth)
   - `newDeviceId` from request → SP param `@newDeviceId` (device being provisioned)

4. **New prerequisite function: `HC6.CHECK_PORTAL_ACCESS_TOKEN`** — This scalar function must be created in the database before HC6 SPs can be deployed. It has the same signature as `HC.CHECK_PORTAL_ACCESS_TOKEN` except the first parameter is `@deviceId UNIQUEIDENTIFIER` instead of `@publicHasherId UNIQUEIDENTIFIER`. The shim does NOT call this function directly — it is called internally by `HC6.ValidatePortalAuth`.

5. **New prerequisite: service account device rows** — Two rows must be pre-seeded in `HC.Device` for the service accounts:
   - One for the hasher whose `PublicHasherId` = `11111111-1111-1111-1111-111111111111` (HashRuns.org)
   - One for the hasher whose `PublicHasherId` = `22222222-2222-2222-2222-222222222222` (admin portal)
   These device rows provide the `deviceId` and `deviceSecret` that service account calls use for token generation.

### No change to shim transport

The shim's transport layer (JSON payload extraction → SP parameter mapping → result forwarding) does not change in structure. Only the parameter name changes from `publicHasherId` to `deviceId`.

---

*Last updated: 2026-03-15*
