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

**All eight fixed on dev 2026-10-14, not yet deployed** (SPs, API +106, app,
portal): receipts `3e765cd3`/`9ce35dac`, run email `19c6a37d`/`f75b610b`/
`3d7524da`, help pushes `dd2ba8ba`, share song `8d27fce0`/`4f86a51c`,
membership `8ce8c993`/`4ebae57e`, down downs `a5a2a941`/`30a931ce`,
haberdashery `bd1b9d00`, snooze `9d87ed11`. Where a fix differs from the
proposal: the run-email send id lives in the log row's `Data` JSON (no
schema change) and the sends of one run queue on the run's `HC.Event` row;
share song treats the same person, run and song within 60 s as a repeat
(no new parameter); the receipt check is also scoped to the run, closing an
edit-another-run's-receipt hole.

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

---

# Part 2 — Portal (audited 2026-10-14)

**Transport:** the portal does **not** retry. `ServiceCommon.sendHttpPostToHC6Api`
(`portal/lib/services/service_common.dart:315-364`) is one `http.post` with a
30 s timeout; the direct endpoints (invite emails 180 s, kennel-from-website
200 s, runs-page test 90 s) are single attempts too. Every repeat is a person:
a double click, or a second press after a timeout while the server is still
working. Today's feedback fixes guard most double clicks; the risks below are
the press-again-after-a-lost-reply and concurrent cases.

## Real risks (most harmful first)

| # | Feature | Caller | SP / endpoint | What duplicates | Fix | Schema? |
|---|---|---|---|---|---|---|
| P1 | **Runs-page Import** (creates runs) | `kennel_page_new/runs_page_test.dart:155`→`:199` | `RunsPageImport.cs:257` → `nonApi_importRunsPageRuns` (`:204-209`) | Upsert on (KennelId, `EventFacebookId='runspage:<n>'`), but NOT EXISTS → `NEWID()` → INSERT has no lock and no unique index. A second Import while the first (AI read can exceed 90 s) is still running, or the 4×/day timer at the same moment, inserts the same runs twice | `sp_getapplock` on the kennel inside the transaction (or UPDLOCK, HOLDLOCK on the check); a filtered unique index (KennelId, EventFacebookId) WHERE InboundIntegrationId = 6 AND deleted = 0 as a backstop | Lock: none. Index: James |
| P2 | **Chat send** (push to the audience) | `chat_page/chat_page_controller.dart:1014`→`:1041` | `hcportal_sendEventMessage` (INSERT `:208`, no existence check); pushes in `PortalApiHC6.cs:159` | A failed send only marks the bubble; no Retry, so the admin retypes → new uuid → second message + second push. Re-sending the same id hits the PK and answers with an error | SP: existing `@messageId` under lock ⇒ return it as success with no recipients (as `hcapp_sendEventMessage` does); portal: Retry on the errored bubble, same uuid | None |
| P3 | **Invite-code emails** | `kennel_hashers_page.dart:1208` | `InviteEmails.cs:137-147` | Stamped only after ACS accepts; two overlapping sends (two tabs/admins) both email everyone; a failed stamp (`RecordAsync` swallows, `:217`) or a crash between send and stamp re-emails on the next press | Claim first: compare-and-set `InviteEmailedAt` under UPDLOCK, HOLDLOCK (only if NULL or > 7 days), send only claimed rows, release the claim on a failed send | None |
| P4 | **New kennel request from a website** | `kennel_requests/kennel_from_website_page.dart:166-176` | `KennelFromWebsite.cs:135` → `hcportal_createKennelRequestFromDraft` (`NEWID()` `:152`) | Save again after a timeout = a second request (approving both = two kennels, the second `LH3-GB`); logo blob re-copied | `@kennelImportId` minted once per draft page; locked existence check returns it as success | None (new optional param) |
| P5 | **Add product** | `kennel_products_ui.dart:575-583` → `queries/product_query.dart:86` | `hcportal_addEditProduct` (`NEWID()` `:128`) | A repeat after a lost reply = a duplicate product, synced to every phone, twice at check-in | `@newProductId` minted once per dialog; unknown id + create intent ⇒ insert with it under lock (today an unknown id is refused, `:113`) | None |
| P6 | **Add song** | `kennel_page_new_controller.dart:980-1023` | `hcportal_addSong` (`NEWID()` `:120` + KennelSongMap) | A repeat after a failure = a duplicate song | `@newSongId` once per add form; locked check returns it | None |
| P7 | **Create newsflash** | `newsflash_management_page.dart:119-133` → `queries/newsflash_query.dart:147` | `hcportal_addEditNewsflash` (insert `:109`) | Lost reply + retyped = a duplicate (lower likelihood) | `@newNewsflashId` once per dialog — **if** the key is a GUID; if it is an INT identity, keying it needs a column (James) | Possibly |
| P8 | **Import from file** (`@fromImport = 1`) | `kennel_hashers_page.dart:1984` | `hcportal_bulkAddHashers` `:246-251`, `:290-297` | Rows upsert by unique email — safe — except a row with no email, no hash name and not both names: each re-run mints a new `hc-…@noemail.invalid` and a duplicate hasher. The email lookup has no lock (a concurrent batch rolls back on the unique index — an error, not a duplicate) | A stable per-row key from the portal (hash of the file row), or a deterministic placeholder from (kennel, names); UPDLOCK, HOLDLOCK on the email lookup | None |
| P9 | **Toggle kennel song** (concurrency) | `queries/song_query.dart:133` | `hcportal_toggleKennelSong` `:108-124` | Set-state, but check-then-INSERT on KennelSongMap with no lock and no unique (KennelId, SongId): two concurrent toggles = two map rows | UPDLOCK, HOLDLOCK or `MERGE … HOLDLOCK`; a unique index is James's | Optional |

## Error-on-repeat (no duplicate, but a repeat answers with an error)

- **Approve kennel request** (`kennel_requests_controller.dart:270-276`): the SP locks
  the request and refuses "already approved" — no second kennel, no second welcome.
  But `approve()` sets `isBusy` only after the await, and a lost reply shows "already
  approved". If the SP is changed to return the original result on a repeat it must
  flag it, or `PortalApiHC6.cs:165-177` would send the welcome email again.
- **Merge hashers**: locks both and refuses a second run — no double move. It takes
  **internal** hasher ids from the browser, against `/hc-primary-keys` (platform-admin only).
- **Web admin token**: a repeat leaves a spare 10-minute token. Harmless.
- **Regenerate ext API key**: a repeat rotates again; after a lost reply the screen shows a stale key until reload.

## Safe

`addEditEvent` (keyed), `updateKennelHasher` (absolute values), `editKennel`,
`updateKennelWebsite`, `deleteEvent`, `batchUpdatePhotoStatus`, `deleteNewsflash`,
`editSong`, `respondToNewsflash`, `setPlatformAdmin`, `savePermissionMatrix`,
`markEventChatRead` (`MERGE … HOLDLOCK`), `reactToChatMessage`, `deleteChatMessage`,
`clearEmailBounce`, `updateFcmToken`, `update/rejectKennelRequest`, `getKennelWebsite`'s
default row (PK), `getLandingPageData` (access log by design), `confirmAuthentication`,
`getInviteEmailList`, `RosterImport` (no writes), upload SAS (an orphan blob at most).
The portal has no payment, credit, receipt, haberdashery or membership-by-months write.

## Not verified

`PortalNewsflash.NewsflashId`'s type (P7); whether the runs-page timer and a portal
Import overlap in practice (P1); `nonApi_recordInviteEmailed` internals (P3); whether a
duplicate KennelSongMap row shows twice anywhere (P9).

---

# Part 3 — Public web (audited 2026-10-14)

**Transport:** nothing retries a write by itself. `callAdminApi` / `callAppApi`
(`public-web/lib/member-api.ts`) are single `fetch` calls; there are no Server
Actions; components make one call behind a `busy`/`sending` flag. The one retry —
a failed chat photo — correctly reuses its messageId (`ChatThread.tsx:337`).
**The web sends no pushes** (`PublicWebAdminApi.cs:302-310` strips the push
rowsets), so a duplicate web chat message is a duplicate row, not a push. Repeats
come from a person, a link opened twice, or a **mail scanner fetching a GET link**.

## Real risks (most harmful first)

| # | Feature | Route / trigger | Chain | What goes wrong | Fix | Schema? |
|---|---|---|---|---|---|---|
| W1 | **Unsubscribe link in every run email** (GET with a side effect) | `api/Endpoints/EmailUnsubscribe.cs:25` (GET and POST; the plain link acts at once, `:73`) | `nonApi_setKennelEmailOff` (`&do=block` → `nonApi_setEmailBlocked`) | Set-state, so repeats are harmless — but a mail security scanner (Safe Links, Mimecast, Proofpoint) fetching the link silently unsubscribes the member from the kennel's run emails. The link sits in the run email's top bar and footer (`RunEmail.cs:598-613`) | GET of the plain link renders a confirm page; its button POSTs, and only the POST acts. RFC 8058 one-click already arrives as POST (`List-Unsubscribe-Post`), so Gmail's button is unaffected. Same for `do=block`. Also: the URL carries the internal hasher id (`h=`, signed) — `/hc-primary-keys` wants a public id | No |
| W2 | **Kennel request resubmitted** (emails a code) | `public-web/app/api/kennel-request/route.ts:53` | `publicWeb_submitKennelRequest` → code email (`PublicWebAdminApi.cs:273-283`) | The row dedupes correctly (natural key under lock), but a repeat while unconfirmed **rotates the code** (`:198-200`) and emails the new one: the first email's code is now dead, entering it counts as a wrong attempt, and five mark the request as spam | A repeat within ~30 min keeps `ConfirmCode` and resends the same code (or sends nothing); `updatedAt` times it | No |
| W3 | **Chat text and location send** | `components/member/ChatThread.tsx:239` (text), `:352` (location) → `app/api/member/chat/route.ts:47` | `publicWeb_sendChatMessage` → `hcapp_send*Message` (idempotent on `@messageId`) | The id is minted per press; after "Couldn't send", Send mints a new one, so a message whose first attempt committed appears twice for everyone | Keep the unconfirmed messageId (keyed to the draft text and reply target) and reuse it until success or the text changes; same for location. Client only | No |
| W4 | **Sign in by emailed code** (creates a device) | `app/api/member/verify-code/route.ts:22` (`randomUUID()` per request) | `hcapp_authorizeDevice` — DELETE then INSERT `HC.Device` (`:228-233`); the code is not consumed | A double submit or retry creates a second device row with a live secret no browser holds — a phantom in Signed-in devices (no second account) | Mint the browser's deviceId once per sign-in flow (a signed httpOnly cookie set at request-code); the SP returns the existing secret for an existing device of the same user instead of DELETE/INSERT (as `confirmAuthentication` does) | No (SP behaviour) |
| W5 | **Chat report** (emails the reviewers) — shared with the app | `app/api/member/chat/report/route.ts:16` | `publicWeb_reportChatMessage` → `hcapp_reportChatMessage` → `AbuseReportEmails` | Its dedupe (`:88-93`) is check-then-insert on `LOG.GeneralLog` with no lock or transaction: two concurrent reports = two log rows and **two reviewer emails** (sequential repeats are already refused) | `sp_getapplock` on the report key inside a transaction (a locked `LIKE` over the log table would be expensive) | No |
| W6 | **Web admin token redeem** (GET, consumes the token) | `app/api/admin/auth/route.ts:26` | `publicWeb_redeemAdminToken` — `DELETE … OUTPUT` (`:35`) | Not a duplicate, the opposite: a link preview, a lost redirect or a reload burns the token and the admin is refused. Low (the portal opens it directly) | Make the page POST the token; or mark it redeemed and allow ~60 s re-redemption | POST: no. Grace window: a column (James) |
| W7 | **QR sign-in poll** (low) | `app/api/member/qr/poll/route.ts` | `publicWeb_confirmAuthentication` | The request is marked removed (`:74`); if the reply with the cookie is lost, later polls say "pending" until expiry while the device row exists but cannot be reached. Its device check (`:53`) has no lock — concurrent polls hit the PK (an error, not a duplicate) | Find the request regardless of `Removed` when `HC.Device` already holds `@newDeviceId` for that hasher; UPDLOCK, HOLDLOCK on the device read | No |

## UI-only

- **Signup double click:** `hcapp_addEditUser` (lock + unique email) makes no second
  hasher, but a concurrent second call returns its duplicate envelope with
  `errorCode 1510, errorType 10005`, and `createMember` tests `errorCode === 10005`
  (`member-api.ts:172`), so the person is told the account could not be created when it
  just was. Test `errorType`.
- Request code, signup, run-counts report: a repeat is another email to the caller; the
  invite code stays the same for a week.
- "I'm in / Can't make it" links: applied client-side only with a member cookie
  (`RsvpPanel.tsx:81`), so a scanner cannot RSVP; repeats are set-state.

## Safe

RSVP, follow/home kennel, notification and email prefs, chat react, delete and mark
read, photo upload (orphan blob at most), block, DM start/respond/end/mute/preference,
passkey register/login/delete, sign out device, member logout, kennel request confirm,
save layout (PK on KennelId), web-error log.

## Not verified

That every write button is actually `disabled={busy}` (the handlers set busy but do not
test it first); whether a preview could fetch the admin token URL (W6); whether
`AddKennelForm` says a resubmit replaced the code (W2); `PublicWebApi.cs` (read-only
proxies seen, not read).
