# HC Access Token Pattern

> **Always apply this skill when generating or validating access tokens in the
> mobile app.** When in doubt about how to build a token for a specific SP,
> read the SP — it is the definitive source. Every SP must follow the same
> pattern; any variation lives in `@param`, never in the token structure itself.

---

## How a token is built (Flutter side)

`Utilities.generateToken(userId, procName, {paramString, timeWindow})`

```
accessString = UPPER(userId + '#' + procName + '#' + timeBlocks + optional('#' + paramString))
token        = SHA256(accessString).toUpperCase()
```

Where:
```
timeBlocks = floor(secondsSince(1993-07-25 15:00 UTC) / timeWindow)
```

- **Base date:** `DateTime.utc(1993, 7, 25, 15, 0, 0)` — hardcoded, never changes for app tokens.
- **timeWindow:** device-specific, stored in `IntPrefsEnum.timeWindow` (defaults to 30s if not set).
- **paramString:** the raw compound value, passed WITHOUT a leading `#`. `generateToken` prepends `#` internally before including it in the access string.

---

## How a token is validated (SQL side)

`HC.CHECK_ACCESS_TOKEN_V2(@userId, @procName, @accessToken, @paramString, @timeWindow)`

The server calls `HC.CREATE_ACCESS_TOKEN_V2` with offsets **0, +1, -1, +2, -2** and
accepts the token if any match. This tolerates:
- Device clock drift
- Network latency
- Integer rounding differences between client and server

`CREATE_ACCESS_TOKEN_V2` builds:
```sql
@str = UPPER(userId + '#' + procName + '#' + (timeBlocks + offset) + COALESCE('#' + paramString, ''))
HASHBYTES('SHA2_256', @str)
```

The `#` before paramString is added **by the SQL function**, not by the caller.
`@paramString` passed to `CHECK_ACCESS_TOKEN_V2` is always the RAW value (no leading `#`).

---

## Standard vs. compound tokens

| Type | Flutter `paramString` | SP `@param` | When to use |
|---|---|---|---|
| **Standard** | `deviceSecret` | `deviceSecret` | All normal read/write SPs |
| **Compound** | `deviceSecret + someOtherValue` | `deviceSecret + someOtherValue` | Sensitive operations (money, targeting another user) |

`ValidateAppAuth` resolves the context as:
```sql
DECLARE @tokenContext NVARCHAR(650) = COALESCE(@param, @deviceSecret);
```

- `@param = NULL` → token context is the stored `deviceSecret` alone.
- `@param` provided → token context is whatever was passed (replaces the deviceSecret default).

Compound tokens are used where replay attacks are a concern — typically any SP
involving payments, credit, or acting on behalf of a target user. The compound
value binds the token to a specific operation/target, not just the device.

---

## Device secret and time window

Generated once at device registration (`hcapp_authorizeDevice`):

```sql
-- Device secret: cryptographic random, 75 uppercase alphanumeric chars
DECLARE @binaryData   VARBINARY(MAX) = CRYPT_GEN_RANDOM(150);
SELECT @deviceSecret = LEFT(UPPER(REPLACE(REPLACE(
    CAST('' AS XML).value('xs:base64Binary(sql:variable("@binaryData"))', 'varchar(max)'),
    '+', ''), '/', '')), 75);

-- Time window: random integer 30–44 seconds, unique per device
SELECT @timeWindow = CAST((RAND() * 15) + 30 AS INT);
```

Both are returned to the app on first login and stored locally:
- `StringPrefsEnum.deviceSecret`
- `IntPrefsEnum.timeWindow`

---

## First-time device auth (special case)

`hcapp_authorizeDevice` uses a **global shared token** — the device has no secret yet:

```sql
HC.CHECK_ACCESS_TOKEN_V2(
    '00000000-0000-0000-0000-000000000000',  -- null userId
    @procName,
    @accessToken,
    NULL,             -- no paramString
    30                -- hardcoded 30s window
)
```

Flutter generates this with:
```dart
Utilities.generateToken(GUID_EMPTY, 'hcapp_authorizeDevice')
// No paramString, no deviceSecret
```

---

## The delegation pattern (write SPs → sync SPs)

Write SPs that call `syncUserData`, `syncKennelAdminData`, or `syncEventAdminData`
pass their own `@procName` and `@param` through. This means token validation
occurs in the context of the **calling SP**, not the sync SP.

The Flutter app generates the token against the **calling SP's proc name and
param**, then passes `@procName` and `@param` on to the sync call so the server
can re-validate in the same context.

---

## Building tokens correctly — checklist

When adding a new SP call from the Flutter app:

1. **Read the SP** — look at what `@param` it expects and whether it calls
   `ValidateAppAuth` directly or delegates.
2. **Match the proc name exactly** — `procName` in Flutter must equal
   `OBJECT_NAME(@@PROCID)` in the SP.
3. **Use the correct paramString:**
   - No `@param` in SP → `paramString: deviceSecret`
   - `@param = deviceSecret` → `paramString: deviceSecret`
   - `@param = deviceSecret + targetUserId` → `paramString: deviceSecret + targetUserId`
   - Pass the **raw concatenated value** — no `#` prefix, no separators between parts.
4. **Never vary the token structure** — all variation is in `@param`. The
   `userId`, `procName`, `timeBlocks` fields are always the same.
5. **timeWindow comes from device prefs** — `getIntPref(IntPrefsEnum.timeWindow) ?? 30`.
   For the first-time auth only, use hardcoded `30`.
