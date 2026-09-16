# Participate without the app — web member identity (E9.F7)

Designed 2026-09-16 with James. Status: **written up, not started** — the app is
finished first, then this becomes the public-web focus.

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

## Pieces

### Database (`db/hc6/public-web/`)

| Object | Kind | Auth | Notes |
|---|---|---|---|
| `2026-xx-xx_web_member_login.sql` | run-once | — | Widen `HC.PublicWebAdminToken` (above). Archive after running. |
| `publicWeb_requestLoginCode(@email, @kennelSlug, @ipAddress)` | write | none (rate-limited) | Inserts the challenge; returns `challengeId` + the plaintext code **to the server route only**, which emails it. Rate limits counted from the token table's own rows. |
| `publicWeb_verifyLoginCode(@challengeId, @code, @deviceId, @deviceData, @hashName = NULL, @firstName = NULL, @lastName = NULL)` | write | none (challenge-bound) | Checks hash + expiry + attempts. Found hasher → device row → returns `{userId, deviceId, deviceSecret, timeWindow, hashName, known = 1}`. Unknown and no `@hashName` → `{known = 0}` and the challenge stays alive (marked verified). Unknown with `@hashName` → creates hasher + following HKM for the slug's kennel (mirror `hcapp_addEditUser`'s insert, `nonApi_ensureUserInviteCode`), then device row. Device row exactly as `hcapp_authorizeDevice`: `CRYPT_GEN_RANDOM(150)` secret, `TimeWindow` 30–44, `IsMobile = 0`. Delete-then-insert on `@deviceId`. |
| `publicWeb_setRunRsvp(@deviceId, @accessToken, @publicEventId, @rsvpState)` | write | device token for `hcapp_setEventRsvp` | Maps `PublicEventId → EventId`, then `EXEC HC6.hcapp_setEventRsvp` with watermarks `'2000-01-01'`. The inner SP validates the token; the wrapper adds nothing but the id map. |
| `publicWeb_getRunPack(@deviceId, @accessToken, @publicEventId)` | read | `HC6.ValidateAppAuth` | Own RSVP/attendance state + pack: hash name (per `NameDisplayPreference`), avatar URL, `RsvpState`, `IsHare`. |

All four: TRY/CATCH, `HC.ErrorLog` in every CATCH, `ROLLBACK` before the log.
`/hc-authorizations`: `ValidateAppAuth` is identity, not authorisation — the
pack read is member-gated by design (any valid device), and RSVP writes only
the caller's own row (`@hasherId = caller`).

### API (`api/Endpoints/PublicWebAdminApi.cs`)

Add `requestLoginCode`, `verifyLoginCode`, `setRunRsvp`, `getRunPack` to
`AllowedQueryTypes`. None in `SecretRequiredActions`: the first two are the
public flow (rate-limited in the SP, like `redeemAdminToken`); the last two
carry the device token. One small deploy (`func publish`).

### Public web (`public-web/`)

| Path | What |
|---|---|
| `lib/member-session.ts` | AES-GCM-encrypted cookie `hc_member` `{userId, deviceId, deviceSecret, timeWindow, hashName}`; `generateToken(userId, procName, deviceSecret, timeWindow)` — byte-for-byte the app's algorithm (`UPPER(userId#proc#blocks#param)`, base 1993-07-25 15:00 UTC). New env `HC_MEMBER_SESSION_SECRET` (32 bytes) and `HC_EMAIL_LOGICAPP_URL`. |
| `app/api/member/request-code` | POST `{email, slug}` → SP → Logic App email. |
| `app/api/member/verify-code` | POST `{challengeId, code, hashName?}` → SP → set cookie. |
| `app/api/member/rsvp` | POST `{publicEventId, rsvp}` → `setRunRsvp` under the cookie's device. |
| `app/api/member/pack?publicEventId=` | GET → `getRunPack`. |
| `components/kennel/RsvpPanel.tsx` | Client component on the run page: reads `?RSVP=`; signed in → posts at once, shows tick + pack; signed out → "I'll be there / Can't make it" buttons open the email → code → (hash name) sheet, then completes the pending RSVP. Past runs: pack only, no buttons. |

`resolveKennelAndEvent` already yields `PublicEventId`; the run page passes it
and the `?RSVP=` value down.

### Build order (one day, James 2026-09-16: "as many features as we can
into that capability in a day and then wrap it up")

1. Email code (S2) · 2. QR via `/login/` (S7, app + web) · 3. Unknown-email
signup (S3) · 4. RSVP (S1) · 5. Passkeys (S6). Pack list (S4) if time.

### Slice one — RSVP only (James, 2026-09-16: "all I'm interested in is the
RSVP capability so the WhatsApp works")

S1 + S2 + S3: web handles `?RSVP=`, email-code sign-in, unknown-email signup,
RSVP recorded, own tick shown. The pack list (S4), history (S5) and passkeys
(S6) are *not* in the slice; they are what the same identity makes cheap
later. `getRunPack` is therefore also deferred — slice one needs only
`requestLoginCode`, `verifyLoginCode`, `setRunRsvp` (three SPs, three
allow-list lines, three routes, one panel).

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
