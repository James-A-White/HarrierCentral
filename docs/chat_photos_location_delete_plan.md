# Chat — photos, locations, copy, delete and moderation

Stories `E9.F1.S11`–`E9.F1.S15` (James, 2026-09-29). This is the contract the
database, the API and all three clients (app, web, portal) build against.

| Story | What |
|---|---|
| `E9.F1.S11` | Send a photo in any chat; shown in a carousel |
| `E9.F1.S12` | Send a location — where I am now, or a dropped pin |
| `E9.F1.S13` | Delete my own message — it vanishes for everyone |
| `E9.F1.S14` | A chat administrator deletes anyone's message in their kennel's chats |
| `E9.F1.S15` | Copy a message |

Decisions (James, 2026-09-29): users delete **their own messages** (not
threads); a deleted message **vanishes** (no placeholder); location offers
**my location + drop a pin**; **all three clients** send, show and delete.

---

## 1. Storage — one column, no new table

`HC.EventMessage.MessageKind SMALLINT NOT NULL DEFAULT 0` with a CHECK
`IN (0, 1, 2)`:

| Kind | Meaning | `MessageContent` holds |
|---|---|---|
| `0` | Text | the text, as today |
| `1` | Photo | the blob URL: `https://harriercentral.blob.core.windows.net/chat-photos/<yyyy>/<MM>/<userId>-<guid>.jpg` |
| `2` | Location | `https://www.google.com/maps/search/?api=1&query=<lat>,<lng>` — lat/lng with up to 6 decimals, `.` separator |

`MessageType` is NOT reused: it already names the chat room.

🧠 **Why the content is a URL:** builds that predate this feature read only
`text`, so they show a photo or a location as a link rather than an empty
bubble. A new client reads `messageKind` and draws the photo or the map card.

`HC.EventMessage` has no `updatedAt` trigger and is not in the mobile sync, so
the ALTER does not stamp rows. Run-once script:
`db/hc6/app/2026-09-29_chat_kind_and_moderation.sql` (archive after it runs).

Two scalar helpers keep the rules in one place (row-at-a-time, not filters):

- `HC6.ChatMessageKindError(@kind, @content)` → `NULL` when valid, else a
  user-facing reason. Kind 1 must start with the chat-photos prefix; kind 2
  must be the maps URL with a lat in [-90, 90] and a lng in [-180, 180].
- `HC6.ChatMessagePreview(@kind, @content)` → `'📷 Photo'`, `'📍 Location'`,
  or the content. Used for the push body and `HC.PushLog`.

## 2. Sending

Every send SP gains an optional `@messageKind SMALLINT = 0` — additive, so
every existing caller is unchanged:

- `hcapp_sendEventMessage`, `hcapp_sendKennelMessage`, `hcapp_sendRoomMessage`
- `hcportal_sendEventMessage`
- `publicWeb_sendChatMessage` (passes it through)

They refuse an invalid kind/content with the existing error envelope
(errorType 2), and rowset 0's `MessageContent` is the **preview**, because
the API shim uses that column as the push body. Rowset 0 also gains
`MessageKind`.

## 3. Reading

`hcapp_getEventMessages`, `hcapp_getKennelMessages`, `hcapp_getRoomMessages`
and `hcportal_getEventMessages` add two columns to the message rowset and one
rowset after it:

| Addition | Meaning |
|---|---|
| `messageKind` (SMALLINT) | 0 / 1 / 2 as above |
| `canDelete` (SMALLINT) | 1 when the caller may delete this row (their own, or they moderate the thread) |
| next rowset: `{ id }` | ids of **removed** messages in this thread, UPPER like the message ids |

`publicWeb_getChatMessages` delegates to the app SPs, so it inherits all three.

🧠 **Why a removed-ids rowset:** the readers already filter `Removed = 0`, and
the delta fetch asks only for sequence numbers above the last one seen. A
deletion changes neither, so a phone that already drew the message would keep
it forever. Every fetch (full or delta) returns the thread's removed ids and
the client drops any it is showing. Deletions are rare, so the list is short.
Old builds read rowset 0 only and never see the extra rowset.

## 4. Deleting

`hcapp_deleteChatMessage(@deviceId, @accessToken, @messageId)`:

- Allowed when the caller **wrote it**, or **moderates** its thread:
  - run chat → `CheckKennelPermission(@userId, Event.KennelId, 'moderateChat')`
  - kennel chat → `CheckKennelPermission(@userId, KennelId, 'moderateChat')`
  - room → SuperAdmin only (any HKM row with `AppAccessFlags & 0x40000000`)
- Sets `Removed = 1`, `updatedAt = SYSDATETIMEOFFSET()`. The activity trigger
  refreshes the run card's chat count.
- Writes a `LOG.GeneralLog` audit line when a moderator removes someone
  else's message (who, whose, which thread).
- Idempotent: deleting an already-removed message succeeds.
- Returns the standard success envelope.

Wrappers: `publicWeb_deleteChatMessage` (`EXEC`s the app SP — writes wrap,
per CLAUDE.md) and `hcportal_deleteChatMessage` (portal auth, then the same
rule). The rule itself lives once, in `HC6.nonApi_deleteChatMessage`.

## 5. The permission — "Chat administrator"

| Row | Value |
|---|---|
| `HC.PermissionRole` | `flagManageChat`, "Manage chat", `appFlag`, bit `512` (`0x200`) |
| `HC.PermissionFunction` | `moderateChat`, "Delete any chat message", area `chat` |
| `HC.RolePermission` (global) | `gm`, `webMeister`, `flagManageChat` → Allowed = 1 |

App: `authCanManageChat = 0x200`, `authAllFlags` widens to `0x3ff`, and
`KennelFeature.moderateChat(0x00001002, authCanManageChat, false, PermissionArea.chat)`.
The flag appears wherever flags are granted (app and portal editors). The
`chat` area must not create an empty admin doorway.

## 6. Photos — upload

- **App:** new API function `GetChatPhotoUploadToken` → SP
  `hcapp_getChatPhotoUploadToken` (auth only; returns userId). Container
  `chat-photos`, path `<yyyy>/<MM>/<userId>-<photoGuid>.jpg`, 15-min
  write-only SAS. Returns `{ sasUrl, blobUrl }`. Resize before upload
  (max 1600 px, JPEG ~75).
- **Web:** a Next route receives the file from the browser, resizes if
  needed, asks `GetChatPhotoUploadToken` with the member's device
  credentials, PUTs the bytes server-side and returns `blobUrl` — no browser
  CORS to the blob account.
- **Portal:** existing `GetPortalUploadSas`, with `chat-photos` added to its
  container allowlist; filename `<yyyy>/<MM>/<userId>-<guid>.jpg`.

Then send with `messageKind = 1`, `messageContent = blobUrl`.

## 7. Showing

- **Photo:** at its own aspect ratio, never cropped (CLAUDE.md photo rule).
  Tap opens a **carousel of every photo in this chat**, starting at the one
  tapped, on the client's backdrop (app jungle, portal light hash foot, web
  kennel art). The web downloads through `/api/photo-download`.
- **Location:** a card with a pin icon, "Location" and the coordinates; tap
  opens the map app (app: the same chooser as the run pin; web/portal: the
  maps URL in a new tab).
- **Long-press (app) / hover menu (web, portal) on a message:** **Copy** always
  (text → the text; photo and location → the URL), **Delete** when `canDelete = 1`,
  with a confirm. Delete removes the bubble at once, and restores it if the SP refuses.

## 8. Known gaps (v1)

- A deletion reaches another open chat on its next fetch (next message push,
  resume or reopen), not instantly — no "message removed" push.
- A removed photo's blob is not deleted; the URL still works for anyone who
  saved it.
