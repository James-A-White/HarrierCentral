# Chat — block a hasher, report a message

`E9.F1.S16` (block) and `E9.F1.S17` (report), James 2026-09-29. The two
things an app with messaging between hashers needs before direct messages
(`E9.F1.S7`) can ship: the user's own tool, and a letterbox to the platform.
Harrier Central does not moderate: a report goes to people, not to a queue.

## Block — `HC.HasherFriendMap.Ignore = 1`

The 2019 table, unused until now, already has the row: directional
`UserId → Friend_UserId`, unique on the pair, `Ignore SMALLINT`. Run-once
`2026-09-29_hasher_block.sql` adds `createdAt`/`updatedAt` (not a synced
table; no trigger dance).

| Where | Effect of A blocking B |
|---|---|
| `hcapp_getEventMessages` / `getKennelMessages` / `getRoomMessages`, `hcportal_getEventMessages` (web wraps the app SPs) | B's messages are omitted from A's reads |
| `hcapp_sendEventMessage` / `sendKennelMessage` / `sendRoomMessage`, `hcportal_sendEventMessage` | A's devices are left out of B's push audience |
| `HC6.UserUnreadChatThreads` (icon badge, chat list) | B's messages above A's read mark are not counted, so A can always clear the badge |
| B | Nothing. B is not told, sees nothing different, and can still read A |

The filter is one `NOT EXISTS` on the unique key in each SP, never a scalar
function in a `WHERE`. After a block or unblock the client re-fetches the
open thread in full (`since = NULL`), because a delta by sequence number
never revisits what is already on screen.

SPs: `hcapp_setHasherBlock(targetPublicHasherId, blocked)` → returns the
blocked list; `hcapp_getBlockedHashers`. Web: `publicWeb_setHasherBlock`,
`publicWeb_getBlockedHashers` (thin wrappers). UI: long-press → Block;
Settings → Blocked hashers → Unblock. Portal: readers filter, no UI.

## Report — a letterbox

`hcapp_reportChatMessage(messageId, reason?)`: writes one `LOG.GeneralLog`
line (reporter, sender, thread, text, reason) and returns the report
(rowset 1) and the reviewer addresses (rowset 2) for the API, which emails
them through `AbuseReportEmails` and strips both rowsets from the reply.
Reviewers = `HC.PlatformAdmin` with `CanEditKennel` plus the shared mailbox,
the same rule as `publicWeb_confirmKennelRequest`. The same reporter
reporting the same message again succeeds and sends nothing. Own messages
cannot be reported. Reason ≤ 1,000 characters (`NVARCHAR(MAX)` parameter,
`LEN` check).

A report hides nothing and removes nothing. The reporter blocks the sender
themselves; a chat administrator (kennel chats) or a super admin (rooms) can
delete the message from the app. That division — the user's tool, the
club's moderation, the platform's letterbox — is deliberate.

## Known gaps

- The shared reviewer mailbox is Gmail, which Harrier Central email does
  not reach today (DMARC, open since 2026-09-28); platform admins' own
  addresses still get it.
- No rate limit on reports beyond the once-per-message rule.
