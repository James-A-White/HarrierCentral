# Participate without the app — web member identity (E9.F7)

Designed 2026-09-16 with James. Status: **LIVE 2026-09-16** — migration run,
190 SPs deployed, API 1.0.49+47, public-web 0.21.49, `HC_MEMBER_SESSION_SECRET`
set; app builds 3.1.0+1378 / 3.0.40+1379 (TestFlight internal, Play internal
1379) carry the `/login/` handling. Smoke-tested live: `/login` 200, unknown
email → `{sent:false, known:false}`, QR start/poll `{pending:true}`, pack
without cookie 401, run page shows the panel with `?RSVP=Yes`. Built in one day, as asked: email code, QR
via `/login/`, unknown-email signup, RSVP, pack list, passkeys.

## Why

| | |
|---|---|
| Hashers in the DB | 10,289 |
| …with a real email | 7,204 |
| Ever had the app on a device | 1,570 |
| **Attended a run in the last 2 years, never had the app** | **2,978** |
| …of whom have a real email | **2,953** |

The population that could RSVP from a WhatsApp notice without the app is
almost twice the app population, and we already hold an email for 99% of them.
They already have accounts — a kennel admin created them on the check-in
screen, run after run. Nobody signs up; they **claim the row that exists**.

## The decision: the browser is a device

The app's identity model is not username/password. A device holds a secret
(`HC.Device.DeviceSecret`, 75 random chars) and proves it with a 30-second
SHA-256 token (`/hc-access-tokens`). `HC.Device` already records browsers —
its computed `OperatingSystem` column reads `$.browserName` from `DeviceData`,
because the Flutter portal registers browsers as devices.

So the public web does not get a new auth model. A browser becomes an
`HC.Device` row bound to the right hasher, and from then on Next.js calls the
**same `hcapp_` SPs the app calls, through the same shim** (`AppApiHC6`). RSVP
on the web is `hcapp_setEventRsvp`, unchanged. Notifications, sequence
numbers, run counts, badge rows — all behave exactly as from the app, because
it *is* the app's path.

Reuse the trust chain that exists rather than build a parallel one — the same
principle as the admin OTP decision in CLAUDE.md. A second identity system is
a second thing to get wrong and a second place where "who is this?" drifts.

## Decisions taken (James, 2026-09-16)

1. **Browser-as-device**, reusing `HC.Device` and the app's SPs. Yes.
2. **Identity proof: six-letter email code.** We hold the email; the Logic App
   (`Utilities.SendEmailAsync` in the API, HTTP-trigger URL) already delivers
   invite codes. No SMS (no Twilio, phones mostly not held). Apple/Google
   later via the existing `hcapp_processThirdPartyLogin`.
3. **Unknown email creates a hasher**, home/following kennel = the kennel
   whose link was tapped. Never "ask your GM to add you".
4. **Pack list shows hash names and avatars**, as the app's RSVP tab does.
   First member-only content on the public web; gated on a valid device.
5. **Cookie: 365 days**, encrypted httpOnly, secret never in browser JS.
   Revocation = remove the device row (admins already see devices).
6. **Rate limits in the SP**: 3 codes per email per 15 min, 20 per IP per
   hour, 5 verify attempts per code. Ten-minute code expiry.
7. **No new table.** The login challenge lives on `HC.PublicWebAdminToken`,
   widened with `Email NVARCHAR(250) NULL`, `CodeHash NVARCHAR(64) NULL`,
   `Attempts SMALLINT NOT NULL DEFAULT 0`, `IpAddress NVARCHAR(45) NULL`.
   `HasherId` becomes nullable (a challenge for an unknown email has none).
   Not a synced table, so no trigger dance.
8. **Chat stays in the app.** It needs push, moderation and the store UGC
   posture; it is where the pull to install should come from.
9. **Two doors, chosen by the person, not by a rule** (James, 2026-09-16 —
   "three months is arbitrary and there's no way to know upfront"). On a
   computer: the QR code first, "Send a code to my email instead" under it.
   On a phone: the email box only — there is nothing to scan on a phone. No
   recency lookup, no gate, no hint.
10. **The QR is the portal's flow, reused, with the code carried in a URL.**
    The public web shows `https://www.hashruns.org/login/UWP:<authCode>`;
    the phone's camera opens the app through the universal link and
    `DeepLinkService` calls `hcapp_authenticateWebPortal(scanData)` — the
    same SP and the same `HC.WebPortalAuthenticationRequests` row the
    portal uses. The browser polls a new `publicWeb_confirmAuthentication`
    (same provisioning as `hcportal_confirmAuthentication`, behind
    `HC_INTERNAL_SECRET` rather than the portal's service-account device).
    **The portal is untouched**: it keeps `UWP:<code>`, the in-app scanner
    reads both shapes for ever, and `/login` becomes a reserved slug. The
    app build carrying `/login/` must ship before the web login goes live.
11. **Passkeys last in the build order** (email code → QR → unknown-email
    signup → RSVP → passkeys), so a slipped afternoon costs nothing above.
    A passkey is stored on the browser's `HC.Device` row (credential id,
    public key, counter); verification is `@simplewebauthn/server` in the
    Next.js route. Bound to `hashruns.org` — a Tier 3 custom domain would
    need its own registration or a bounce through hashruns.org.

## The flow

```
tap  ✅ I'll be there: hashruns.org/ch3/1490?RSVP=Yes
  │
  ├─ app installed → the app (E9.F6.S5, shipped 3.1.0+1374)
  │
  └─ no app → web run page reads ?RSVP=
        ├─ hc_member cookie → RSVP recorded → ✅ tick + who else is coming
        └─ no cookie → "Who are you?" → email
              → code by email (Logic App)
              → matched to HC.Hasher.Email
                   ├─ found   → HC.Device row → cookie → RSVP → tick + pack
                   └─ unknown → "What's your hash name?" → hasher + HKM created
                                → HC.Device row → cookie → RSVP → tick + pack
```

Second run: one tap. The friction is paid once, at the moment the person
wants something.

## What was built (2026-09-16)

The email path turned out to be **existing plumbing end to end**: the API's
`EmailInviteCode` already emails the six-letter invite code, and
`hcapp_authorizeDevice` already turns `URC:<code>` into a device row under
the global pre-auth token. No OTP table, no widening of
`HC.PublicWebAdminToken` after all — decision 7 above is superseded.

### Database (`db/hc6/public-web/`) — 7 new SPs, 1 changed, 1 run-once

| Object | Auth | Notes |
|---|---|---|
| `hcapp_authorizeDevice` | global token | **Changed:** optional `@isMobile SMALLINT = 1`; the web passes 0. Non-breaking. |
| `publicWeb_confirmAuthentication` | secret | Web half of the QR flow; provisions the device once the app has approved. |
| `publicWeb_createMember` | secret | EXECs `hcapp_addEditUser` in new-user mode, following the slug's kennel. |
| `publicWeb_setRunRsvp` | device token (inner SP) | Maps `PublicEventId`, EXECs `hcapp_setEventRsvp`. |
| `publicWeb_getRunPack` | `ValidateAppAuth` (sp 109) | Own state + the pack. |
| `publicWeb_savePasskey` | `ValidateAppAuth` (sp 110) | Passkey onto the caller's own device row. |
| `publicWeb_getPasskey` | secret | Key + counter + device credentials for one credential id. |
| `publicWeb_recordPasskeyLogin` | secret | Counter, LastLogin, LaunchAndLogin. |
| `archive/2026-09-16_device_passkey.sql` | — | **Run-once, James runs it:** four nullable passkey columns + filtered unique index on `HC.Device`. Not a synced table. Archive after. |

Contracts in `db/contracts/hc6/`. The `EmailInviteCode` endpoint's 60-minute
code reuse is the spam guard on the SP side; the Next.js routes add per-IP
and per-email limits on top.

### API (`api/Endpoints/PublicWebAdminApi.cs`)

Seven names added to `AllowedQueryTypes` and to `SecretRequiredActions`.
Needs a `func publish`.

### Public web

| Path | What |
|---|---|
| `lib/member-session.ts` | AES-256-GCM cookie `hc_member` (365 d, or session-only when "not my device"); `hcToken()` — the app's algorithm, **parity-tested against `HC.CREATE_ACCESS_TOKEN_V2`**; signed short-lived values for challenges. |
| `lib/member-api.ts` | The three doors: AppApiHC6 (device tokens), EmailInviteCode, PublicWebAdminApi (secret). |
| `lib/member-routes.ts`, `lib/passkeys.ts` | Rate limiter, device-data (browserName for `HC.Device.OperatingSystem`), RP config. |
| `app/api/member/*` | `request-code`, `verify-code`, `signup`, `qr/start`, `qr/poll`, `rsvp`, `pack`, `me`, `logout`, `passkey/{register,login}-{options,verify}`. |
| `components/member/MemberSignIn.tsx` | The two doors. Computer: QR first, "send a code to my email" under it. Phone: email only. Unknown email → hash name → create. Then the passkey offer. |
| `components/member/RsvpPanel.tsx` | On the run page under the header: reads `?RSVP=`, answers at once when signed in, else opens the sign-in and completes the pending answer; shows the tick and the pack. Past runs: pack only. |
| `app/login/page.tsx`, `app/login/[scan]/page.tsx` | Standalone sign-in (`?next=`); the QR's URL lands here when the app is not installed. |
| `RunDetail.memberPanel` | The slot. |

### App (all three branches)

`DeepLinkService` reads `/login/UWP:<code>` and calls
`hcapp_authenticateWebPortal` with the **bare** code (the in-app scanner
strips the prefix, so the row holds the bare code and the web polls with it);
`validateScan` strips `login/` so the in-app scanner reads the URL-form QR
too. `/login` is a reserved slug.

### Environment (web app settings)

| Variable | Purpose |
|---|---|
| `HC_MEMBER_SESSION_SECRET` | **New, required.** Any long random string; hashed to the AES key. |
| `HC_INTERNAL_SECRET` | Already set. |
| `WEBAUTHN_RP_ID` | Optional; default `hashruns.org`. |
| `WEBAUTHN_ORIGINS` | Optional; default `https://www.hashruns.org,https://hashruns.org`. |
| `NEXT_PUBLIC_SITE_ORIGIN` | Optional; default `https://www.hashruns.org` (what the QR URL starts with). |

## Deploy checklist (done 2026-09-16, kept for the next time)

1. **James runs** `db/hc6/public-web/archive/2026-09-16_device_passkey.sql` (parked in archive/ so the deploy script never runs it), then archives it.
2. `./tools/deploy_hc6.sh` (picks up `db/hc6/public-web/*.sql` and the changed `hcapp_authorizeDevice`).
3. API: `func publish harriercentralpublicapi` (allow-list).
4. Web app settings: add `HC_MEMBER_SESSION_SECRET`.
5. Public web deploy (Dance baby).
6. App builds carrying `/login/` (3.1 and 3.0.x) — the QR door needs them; the email door does not.

## Risks and how they are held

- **Email deliverability.** The Logic App is the same path as invite codes;
  the sheet says "check spam" after 60 s and offers resend (rate-limited).
- **Shim pre-auth allow-list.** `PublicWebAdminApi` has an explicit
  allow-list; forgetting it returns "Unknown queryType". The signup
  post-mortem (`project_signup_broken_five_ways`) is the checklist for a
  call that has to work before a device exists.
- **Shared/public computers.** A 365-day cookie on a library PC is a real
  exposure; the sheet has a "not my device" checkbox that shortens it to the
  session, and the device row is revocable.
- **Enumeration.** `requestLoginCode` answers identically for known and
  unknown emails; "known" is only revealed after the code is verified.
- **Two people, one email.** Email is unique on `HC.Hasher`, so a match is
  one row; the admin-typed-the-wrong-email case surfaces as "that's not me"
  on the confirmation and is handled by asking the kennel to fix the record.

## The five tabs (2026-09-16, "replicate the main pages of the app")

`/me/runs` · `/me/kennels` · `/me/map` · `/me/history` · `/me/songs`, behind
the member cookie (`app/me/layout.tsx` redirects to `/login?next=` otherwise),
rendered per request, never cached. Four member SPs under `ValidateAppAuth`
(`getMyRuns` 111, `getMyKennels` 112, `getMyHistory` 113) plus
`setKennelFollowing` (→ `hcapp_joinKennel` self-mode) and the public
`searchKennels` (four `*SearchTags` columns). `PublicWebAdminApi` allow-list
gained four more names. What the web does not do, and says so on the page:
check-in at the start, PackTrack recording, push, chat, payments.
