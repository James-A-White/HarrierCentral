# Chat — direct messages between hashers

`E9.F1.S7` (the DM thread), `E9.F1.S18` (the three-way preference) and
`E9.F1.S19` (the "Message <name>" door and the request list). James,
2026-09-29. Builds on block (`S16`) and report (`S17`), which are live.

## Decisions (James)

- **Default is friends only.** Anyone can be opted into; nobody can be
  chosen. Three states: `0` friends only, `1` anyone, `2` nobody.
- **Discovery is the people you can already see.** The only door is the
  long-press menu on a message in a run, kennel or room chat: **Message
  <name>**. No directory, no search.
- **Harrier Central does not read or moderate DMs.** Block is the hasher's
  tool; Report goes to the reviewers' letterbox; only a super admin can
  delete a DM message.
- Not end-to-end encrypted (discussed and declined 2026-09-29).

## Storage — no new table

| What | Where |
|---|---|
| Preference | `HC.Hasher.Preferences` bits `0x4000|0x8000`: `(Preferences >> 14) & 3`. Every row is 0 today, so **friends only falls out of the default with no data change**, and the value reaches the phone through the user sync it already gets. Written only by `hcapp_setDirectMessagePreference`, which read-modify-writes its own two bits server-side (the bitfield rule). |
| Friendship / request / block | `HC.HasherFriendMap`, directional `UserId → Friend_UserId`. Run-once adds `ThreadId UNIQUEIDENTIFIER NULL` and `Removed SMALLINT NOT NULL DEFAULT 0`. `FriendSince NULL` = request pending; set = friends; `Removed = 1` = unfriended by this side; `Ignore = 1` = blocked (S16). Both direction rows share the `ThreadId`. Not a synced table. |
| Messages | `HC.EventMessage` with `EventId` and `KennelId` NULL, `ThreadId` set, `MessageType 0`. `trgCreateSeqNum` already partitions on `COALESCE(EventId, KennelId, ThreadId)`. Photos, locations, delete, copy, report all carry over. |
| Read state | `HC.EventMessageBadgeCounts` keyed `(UserId, ThreadId)` with `EventId`/`KennelId` NULL, `MessageType 0` — the column was added for this. |

## The door: `hcapp_startDirectMessage(@targetPublicHasherId)`

Returns one row `{ Outcome, ThreadId, OtherPublicHasherId, OtherDisplayName, OtherPhoto }`:

| Outcome | When | Rows written |
|---|---|---|
| `open` | already friends (both rows, `FriendSince` set, neither `Removed`), or target's preference is `anyone` | friendship completed if new (both rows, `FriendSince`, `ThreadId` minted if absent) |
| `requested` | target is friends-only; or **target has blocked the caller** (silent — nothing may reveal a block); or the request already exists | caller's row with `FriendSince NULL` (one row; a re-tap changes nothing) |
| `refused` | target's preference is `nobody`; or the caller has blocked the target | none |

The app shows: open → the thread; requested → "<name> will be asked. You'll be told when they accept."; refused → "<name> isn't accepting messages."

## Requests

- `hcapp_getDirectMessageRequests` → requests **received** and pending:
  `{ FromPublicHasherId, DisplayName, Photo, RequestedAt }`. Shown at the top of
  the chat list with Accept / Decline.
- `hcapp_respondDirectMessageRequest(@fromPublicHasherId, @accept)` — accept:
  write the receiver's row, stamp `FriendSince` on both, mint the `ThreadId`
  on both, push "<name> accepted" to the requester. Decline: `Removed = 1` on
  the requester's row. The requester is **not told** of a decline; their
  view stays "requested". A declined requester who taps again gets
  `requested` and nothing happens (the removed row is not revived — a
  decline is final unless the receiver starts a DM themselves).
- A new request pushes the receiver ("<name> wants to message you") on
  builds ≥ `HC6.MinBuildForDmPush()`.

## Unfriend — `hcapp_endDirectMessage(@threadId)`

`Removed = 1` on the caller's row. The thread stays readable to both but
`sendDirectMessage` refuses while either row is removed or either side has
blocked the other. The other party is not told; they see "You can't message
<name>" only when they try.

## Thread SPs (mirror the room SPs)

- `hcapp_sendDirectMessage(@threadId, @messageId, @messageContent, @messageKind)` —
  caller must hold an active row for the thread; refused if the other side's
  row is removed or either side blocks. Rowset 0 the message (room shape);
  rowset 1 push detail `{ MessageId, ThreadId, UserId, UserDisplayName,
  UserPhoto, MessageTitle = sender name, MessageContent = preview,
  MessageKind }`; rowsets 2/3 visible/silent recipients — the other party's
  devices, gated by `FriendNotificationPreference` (0 auto = visible,
  3 mute = silent, 2 ignore = none) and `MinBuildForDmPush`, with `BadgeTotal`.
- `hcapp_getDirectMessages(@threadId, @sinceSequenceCount, @markRead)` — the
  room reader's shape: messages (+ `messageKind`, `canDelete` = own or
  SuperAdmin), `{ unreadCount, newestSequenceCount }`, `{ removedId }`.
  Marks read like rooms. Refused unless the caller holds a row for the thread.
- `hcapp_setDirectMessageMute(@threadId, @mute)` → `FriendNotificationPreference`.
- `hcapp_setDirectMessagePreference(@preference 0|1|2)`.

`HC6.UserUnreadChatThreads` gains a fourth arm for DM threads the caller
holds a row in, so the icon badge, the chat list and mark-all-read see
them like any thread. New columns on the function, NULL for other kinds:
`ThreadId`, `OtherPublicHasherId`, `OtherDisplayName`, `OtherPhoto`.
`EventName` carries the other party's name for a DM, `KennelLogo` their
photo, so an old list still draws something sensible.

`HC6.nonApi_mayModerateChat`: a DM (`ThreadId` set) → SuperAdmin only.
`HC6.nonApi_deleteChatMessage` and `hcapp_reportChatMessage` already work
on any `EventMessage` row; `ThreadLabel` for a DM = "DM: <sender> ↔ <other>".

Block (`S16`) filters already exclude a blocked sender in every reader and
audience; the DM SPs use the same `NOT EXISTS`.

## Web

`publicWeb_` wrappers for each SP; `publicWeb_getChatThreads`,
`getChatMessages`, `sendChatMessage`, `markChatRead` learn kind `dm`
(`@threadId`). The `/me/chat` list shows requests and DM threads; the
message menu gets **Message <name>**; `/me` settings get the three-way
switch and a mute per DM.

## API

`ChatPushKind.Dm` in `SendChatNotifications` (`ThreadKind: "dm"`,
`ThreadId`, sender name/photo); `case "sendDirectMessage"` and
`case "respondDirectMessageRequest"` / `"startDirectMessage"` (request /
accepted pushes). `HC6.MinBuildForDmPush()` = the first app build that
routes a `dm` push (set when the app ships).

## App

- Long-press → **Message <name>** (hidden on your own messages).
- Chat list: a **Requests** row group at the top (Accept / Decline), DM
  threads in the list with the other party's photo and name.
- DM page = the chat page with kind `dm`; app-bar menu: Mute / Unmute,
  Block, End conversation.
- Settings → **Direct messages:** Friends only (default) / Anyone / Nobody,
  with the one-line explanation. Stored through the bits.
- A `dm` push opens the thread (`_pushIsForThisThread` on `ThreadId`).
- Old builds: the send/read SPs are new names, so nothing changes for them;
  `UserUnreadChatThreads` rows of kind `dm` carry no `EventId`/`KennelId`/
  `RoomType` and the old list must skip them — verify the 1418–1422 list
  code tolerates an unknown row rather than crashing (the memory
  `chat-thread-kind-sites` lists the four sites).

## Known gaps (v1)

- No group DMs; no forwarding; no read receipts beyond the tick.
- Declines and unfriends are silent by design.
