# Idempotency audit — mobile app writes (2026-10-14)

Which user actions in the mobile app can write the same thing twice, and how
to stop each one. Written after a run was saved four times in two seconds
(`E3.F1.S7`). The rule that comes out of it is in `CLAUDE.md` under
**Idempotent writes**.

Scope: every user-triggered write in `mobile-app/lib` and the stored
procedure behind it. Read-only audit; nothing below is fixed yet unless it
says so. The portal and the public web were not audited.

---

## Why a single tap can write twice

A write is repeated in two ways:

1. **The person repeats it.** They tap twice before the first request returns,
   usually because nothing on screen moved. Or the reply is lost, the app says
   "try again", and they do. A double tap is stopped by the UI; a lost reply is
   not.
2. **The app repeats it on its own.** `ServiceCommon.sendHttpPost`
   (`lib/data/services/service_common.dart`) retries a failed write up to
   **six times** (`_maxRetryAttempts = 6`) on a 5xx, including the empty 500 it
   synthesises for a transport failure. It also retries once, silently, after
   a 599 that straddled an iOS suspend. A timeout does not prove the server did
   nothing: the write may have committed and only the reply was lost.

So an in-flight guard on the button is necessary but never enough. A write
that **creates** something must also be safe to arrive twice.

---

## Real risks — a repeat creates a duplicate (most harmful first)

| # | Feature | Trigger | SP | What duplicates | Fix |
|---|---|---|---|---|---|
| 1 | **New expense receipt** (money) | `pages/run_admin/receipt_detail_page.dart:457`; id sent as `GUID_EMPTY` (~:153); `_isLoading` set only after the blob upload (~:170) | `hcapp_addEditReceipt` — `GUID_EMPTY` → NULL (:76), then `NEWID()` (:181); default retries | A second `HC.Receipt` row, so a second reimbursement; each extra tap re-uploads the image | Mint the receipt id once per page and send it (the SP already treats an existing id as an edit); `WITH (UPDLOCK, HOLDLOCK)` on its existence check (~:161); set `_isLoading` before the upload and return early if set |
| 2 | **Run email "Send"** (whole kennel) | `pages/run_admin/run_email_composer_page.dart:285` → `run_email_composer_controller.dart:188` (button disabled while busy) | `api/Endpoints/RunEmail.cs:117-226` → `nonApi_recordRunEmailSent`, then a background send; no dedupe key | After a timeout the app says "try again"; a resend emails every recipient again. The "already emailed" warning is from when the page opened, so it is stale | Mint a `sendId` per composer; the API checks it before recording and sending, and on a repeat returns the stored count without sending. Reload the context after a failed send. Same change in the portal's Email members (parity). **Open:** where the send id is stored — `LOG.GeneralLog` `Data` JSON or a column (schema, James's call) |
| 3 | **Help / I'm Lost / Back on trail** (pushes the pack) | `pages/live_run_pages/live_run_general_page.dart:2233`, `lost_compass_dialog.dart:1187` (guarded while in flight) | `hcapp_sendEventMessage` — already idempotent on `@messageId` | The id is minted per call (`live_run_general_page.dart:1023`, `:1115`), so a retry after "Nothing got through… Try again" is a new message and a second push to everyone. Weak signal on trail makes this likely | Keep the unacknowledged `messageId` on the controller and reuse it on the next attempt for ~2 minutes; clear it on success. No SP change |
| 4 | **Share song** (silent push to everyone RSVP'd) | `pages/top_level/songs_page.dart:970` → `songs_page_controller.dart:181`; `pages/run_admin/down_downs_page.dart:187` → `down_downs_controller.dart:167`; no in-flight guard | `hcapp_selectSong` — plain INSERT into `HC.SongSession` (:172), returns push recipients | Each tap is another session row and another fan-out; adds to iOS silent-push throttling | `isSharing` guard and disabled button in both controllers; SP returns no recipients when the same user/event/song was selected in the last ~10 s (check under `UPDLOCK, HOLDLOCK`) |
| 5 | **Extend membership by months** (an increment) | `pages/kennel_admin/kennel_members.dart:193`, `:290-305`, `:73` → `kennel_members_controller.dart:446`, `:384` | `hcapp_joinKennel` — `@monthsToAddToMembership = +n` adds n months to the current expiry (:285-292) | After a lost reply the admin swipes again: 24 months instead of 12. `addMember` on an existing member extends them too | Compare-and-set: send `@expectedExpiry` (what the phone shows); apply the delta only if the stored expiry still equals it, else return the current row as success. Or send the absolute target date. In-flight check in `modifyMembership` |
| 6 | **Add Down Down** | `pages/run_admin/add_down_down_page.dart:102` → `down_down_form_controller.dart:321`; `submit()` does not check `isSaving` | `hcapp_addDownDown` — `NEWID()` (:144), no key; `noRetries` already set | After "Failed to save" the user taps again: a second charge with its own `DownDownHashers` rows | Optional `@downDownId`, minted once per Add controller; insert only if absent under `UPDLOCK, HOLDLOCK`, else return the existing id. `if (isSaving.value) return;` at the top of `submit()` |
| 7 | **Haberdashery sale** (edge case) | `pages/shared/haberdashery_sale_sheet.dart:100` (guarded by `isSaving`) | `hcapp_processPayment`, `productType 3` — the one product that does not replace an earlier payment | A new `clientPaymentId` per tap; a delivered sale that comes back empty leaves the sheet open (:142-145), so a second tap is a second sale | Mint the `clientPaymentId` once per sheet and reuse it until it closes; treat "delivered, empty results" as success |
| 8 | **Snooze promotion** (minor) | `data/services/snooze_promotion_service.dart:22`; default retries | `hcapp_snoozePromotion` — plain INSERT into `HC.HasherPromotionMap` (:73), no unique key | Duplicate snooze rows; probably harmless (how they are read was not checked) | `MERGE … WITH (HOLDLOCK)` on (UserId, PromotionId) |

---

## UI-only risks — the server is idempotent; a repeat costs a call or a screen

- **Message a hasher** (`services/direct_messages/message_hasher.dart:21`) has no
  guard; a double tap can open the DM page twice. The SP is idempotent.
- **DM accept** (`chats_page.dart:146`) is guarded, but a retry after a commit
  says "That request is no longer waiting" although the accept worked.
  `respondDirectMessageRequest` also reads `@pending` outside its transaction
  without a lock.
- **Card payment** (`check_in_pack_page_controller.dart:827`, `payByCard`) has no
  in-flight flag; a second hand-off would charge the card twice in SumUp, though
  the server keeps one live run-fee row.
- **Pay buttons** in the payment report and check-in mint a new `clientPaymentId`
  each time; the server keeps one live payment per attendance and product, so a
  repeat cancels and re-inserts.
- **Join as visitor, RSVP, attendance, bulk attendance, copy RSVPs**: anti-joins
  and updates; `HasherEventMap` has a unique key, so a concurrent duplicate is a
  logged error, not a second row.
- **Reset code, invite code, run-counts report, payment report email**: email
  only the caller; a repeat is an extra email to yourself.
- **Camera-roll import** (`widgets/run_photo_gallery.dart:130`, guarded): picking
  the same photo again creates a new `photoId` and a duplicate photo; no asset
  dedupe on that path.

---

## Checked and safe

- **Payments.** `hcapp_processPayment` holds `UPDLOCK, HOLDLOCK` on the
  attendance row, recognises a replayed `clientPaymentId`, and replaces an
  existing payment of the same product. The payment outbox reuses the id on
  every retry. `processBulkPayment` locks and cancels-then-inserts per product.
- **Inserts already keyed on a client id:** `addKennelPhoto` (`photoId`),
  `submitTrackImport` (`jobId`), chat and room sends (`messageId`),
  `addEditEvent` (`E3.F1.S7`, 2026-10-14).
- **Set-to-state and upserts:** `setEventRsvp`, `setEventAttendence` (counts
  recomputed, not incremented), `setMultiRunRsvpAndCheckin`, `setEventNotes`,
  `saveHashTrash`, `setOfficialTrail`, `setChatPin`, `setChatRoomParticipation`,
  `setHasherBlock`, `startDirectMessage`, `reactToChatMessage`,
  `reportChatMessage`, the down-down update/cancel/done SPs, photo status and
  caption, `deleteChatMessage`, `deleteTrackImport`, `endDirectMessage`, DM mute
  and preference, `setEmailAndNotificationPrefs`, `joinKennel`'s follow and
  notification fields, `clearEmailBounce`, `setFcmTokens`, `gdprDelete`,
  `signOutDevice`, `deletePasskey`.
- **Sign-up:** `processThirdPartyLogin` cannot create a second hasher —
  `HC.Hasher.Email` is unique.

## Not verified

- Where a run-email send id would be stored (risk 2).
- How snooze rows are read (risk 8).
- That hash-credit balances ignore cancelled payment rows. Assumed; if not, the
  payment "replace" paths need a second look.
- Whether the shim's six automatic retries should apply to writes at all. They
  were added for reads and flaky links; with every creating write keyed, they
  become safe, but a write that cannot be keyed should opt out (`noRetries`).

---

## Suggested order

1. **Receipts (1)** and **Add Down Down (6)**: money, and the fix is the
   `E3.F1.S7` pattern exactly — a client id on the page, a locked existence check
   in the SP.
2. **Help / I'm Lost (3)**: client-only, no SP change.
3. **Run email send (2)**: needs the send-id storage decision, and the portal too.
4. **Membership extension (5)**: compare-and-set; the shape most likely to
   recur elsewhere, so worth doing once well.
5. **Share song (4)**, **haberdashery (7)**, **snooze (8)**.
