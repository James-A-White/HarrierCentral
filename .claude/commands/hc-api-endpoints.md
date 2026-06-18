# HC API Endpoints

> **Load this skill before working on any code that calls the API shim from
> the mobile app, portal, or public web.** The most common mistake is assuming
> a new SP needs an API change — it almost never does. Read this first.

---

## The golden rule

**Adding a new HC6 SP never requires a change to the API.** Each endpoint
already routes generically based on `queryType`. The only time the API needs
changing is when a new *post-write side effect* must be triggered server-side
(push notifications, Google Calendar sync, etc.).

---

## Endpoint map

| Endpoint file | Function name | Schema | Who calls it |
|---|---|---|---|
| `AppApi.cs` | `AppApi` | `[HC5]` | Mobile app — legacy HC5 SPs only |
| `AppApiHC6.cs` | `AppApiHC6` | `[HC6]` | Mobile app — all HC6 app SPs |
| `PortalApi.cs` | `PortalApi` | `[HC5]` | Flutter portal — legacy HC5 SPs |
| `PortalApiHC6.cs` | `PortalApiHC6` | `[HC6]` | Flutter portal — all HC6 portal SPs |
| `PublicWebApi.cs` | `PublicWebApi` | `[HC6]` | Next.js public web — unauthenticated GET |
| `PublicWebAdminApi.cs` | `PublicWebAdminApi` | `[HC6]` | Next.js public web — authenticated admin POST |

---

## How generic routing works (AppApiHC6 as the canonical example)

The caller sends a JSON POST body with a `queryType` field. The endpoint
builds the SP name by interpolating that field into a fixed template:

```csharp
// AppApiHC6.cs line 90
String procedureName = $"[HC6].[hcapp_{data.queryType}]";
```

Every other JSON property in the request body is forwarded as a named
parameter — `"deviceId"` becomes `@deviceId`, `"hasherId"` becomes
`@hasherId`, and so on. There is no whitelist; any property maps directly
to a parameter:

```csharp
foreach (var property in jsonData.Properties())
{
    if (property.Name == "queryType" || property.Name == "includeNulls") continue;
    cmd.Parameters.AddWithValue("@" + property.Name, ...);
}
```

The SP handles auth and logic. The endpoint collects all result sets into
`multipleResults` (a `List<List<Dictionary<string,object?>>>`) and returns
them as JSON.

**Consequence:** a new HC6 SP is callable the moment it is deployed. No API
change, no route registration, no endpoint mapping needed.

---

## The Flutter-side URL

`ServiceCommon.sendHttpPost()` in the mobile app always posts to
`BASE_AF_API_URL`, which is `AppApiHC6`:

```dart
// constants.dart
const String BASE_AF_API_URL = 'https://$BASE_AF_URL/api/AppApiHC6';
```

When writing a new service method in the mobile app, use
`ServiceCommon.sendHttpPost()` with no URL override — it already hits the
right endpoint.

---

## HC6 error envelope handling

`AppApiHC6` detects the HC6 error envelope automatically. If rowset 0 has
exactly one row containing an `errorType` key, the endpoint returns HTTP 400
with safe fields only (`errorType`, `errorUserMessage`, `errorId`). The full
detail row (including `debugMessage` and `errorProc`) is logged server-side
only — never exposed to the client.

---

## Post-write side effects

Some SPs trigger additional server-side work after the DB write. These are
wired up in the `switch` block that runs after `multipleResults` is
populated. Current cases in `AppApiHC6`:

| `queryType` | Side effect |
|---|---|
| `addEditEvent` | `UpdateGoogleCalendar()` — triggers an Azure Logic App to sync Google Calendars for all kennels with integration enabled |
| `sendEventMessage` | `SendNotifications()` — fans out FCM push notifications to event chat recipients |
| `markEventChatRead` | `SendReadSyncAsync()` — sends a silent FCM data push to the user's other devices |
| `selectSong` | `SendSongToAttendeesAsync()` — pushes a visible FCM notification to all hashers currently at the run |

**When to add a new case:** only when the SP write alone is not enough and
the server needs to reach out to an external system (FCM, Google Calendar,
email relay, etc.) as a direct consequence of that specific call. Business
logic always stays in the SP.

**When NOT to add a new case:** almost always. If the SP just writes data
and returns sync rowsets, the generic routing handles it completely.

---

## Checklist — adding a new HC6 app SP

1. Write the SP in `db/hc6/app/` following the standard HC6 pattern
2. Deploy with `./tools/deploy_hc6.sh`
3. Write the Dart service method using `ServiceCommon.sendHttpPost()`
   with `queryType` matching `OBJECT_NAME(@@PROCID)` in the SP exactly
4. **Do not touch any API `.cs` file** unless the SP requires a new
   post-write side effect against an external system

---

## Checklist — adding a new post-write side effect

1. Confirm the side effect cannot be done from the SP itself (it almost
   certainly can't — SPs can't call external HTTP endpoints)
2. Add a `case "yourQueryType":` to the `switch` in the relevant endpoint
3. Implement the side-effect method in the same `.cs` file
4. Bump the API version and deploy
