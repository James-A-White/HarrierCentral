# HC6 adHocData Pattern — Returning Non-Sync Data from App SPs

Load this skill whenever an HC6 app SP needs to return data back to the Flutter
caller that is not sync data (i.e. not rows that get written into a local SQLite
table). The canonical example is returning a generated ID after an insert.

---

## When to Use

Use adHocData when a write SP needs to hand something back to the caller — a
newly generated ID, a server-computed value, a confirmation token — that does
not belong in any sync table. Do **not** invent a dedicated named rowset, and
do **not** add columns to the success envelope.

Response rowset layout for an SP that uses adHocData:

```
rowset 0  — success envelope  { success, errorCode, errorType }   (unchanged)
rowset 1  — adHocData         { adHocDataId, ...fields... }
rowsets 2+ — sync data from hcapp_syncUserData (or equivalent)
```

---

## SQL Pattern

Add `adHocDataId = 1` as the **first** column. The sync framework identifies
adHocData rowsets by checking `ms.startsWith('[{"adHocDataId"')` — the column
name and position are load-bearing.

```sql
-- After the success envelope SELECT, before the syncUserData EXEC:
SELECT
    1                                         AS adHocDataId,
    LOWER(CAST(@eventId AS NVARCHAR(40)))     AS eventId;
    -- add other fields as needed
```

Document it in the SP header:

```sql
-- Returns:
--   rowset 0 — success envelope { success, errorCode, errorType }
--   rowset 1 — adHocData { adHocDataId, eventId }
--   rowsets 2+ — sync data from hcapp_syncUserData
```

### Real examples

- `HC6.hcapp_addEditEvent` — returns `eventId` (insert or update)
- `HC6.hcapp_joinEventAsVisitor` — returns `hasherEventMapId`
- `HC6.hcapp_setEventRsvp` — returns `hasherEventMapId`, `serverMessage`, etc.
- `HC6.hcapp_joinKennel` — returns `following`, `kennelNotificationPreference`, etc.
- `HC6.hcapp_copyEventRsvps` — returns `serverMessage`

---

## Flutter Pattern

`updateSqlTablesWithResultsFromApiWithAdHocData` already handles adHocData
rowsets internally and **returns** them to the caller. Capture the return value.

```dart
final List<dynamic> adHocData = await tableModel.syncUserDataService
    .updateSqlTablesWithResultsFromApiWithAdHocData(responseBody);

if (adHocData.isNotEmpty) {
  final String? returnedId = adHocData[0]['eventId'] as String?;
  if (returnedId != null && returnedId.isNotEmpty) {
    eventId = returnedId;
  }
}
```

If using `syncEventAdminService` or `syncKennelAdminService` instead of
`syncUserDataService`, the same return-value pattern applies — all three
delegate to `BaseService.updateSqlTablesFromJsonWithAdHocData`.

### Real examples in Flutter

- `EventsService.addEditEvent` — reads `eventId` from adHocData
- `HasherEventMapService.joinEventAsVisitor` — reads `hasherEventMapId`
- `HasherEventMapService.setEventRsvp` — reads multiple fields

---

## What NOT to Do

- Do not add data columns to the success envelope `{ success, errorCode, errorType }`.
  The envelope is intentionally consistent across all HC6 SPs.
- Do not invent a standalone named rowset (e.g. `SELECT @eventId AS eventId` with
  no `adHocDataId`). The sync framework will skip it silently and the data will
  be lost.
- Do not parse `responseJson[0][0]` or `responseJson[1][0]` directly from the
  raw JSON. Always go through `updateSqlTablesWithResultsFromApiWithAdHocData`
  and read from its return value.
