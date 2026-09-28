# Kennel requests — HC6 redesign (E12.F1.S5+)

*Drafted 2026-09-28. Replaces the WordPress-era intake and the HC3W web app's
approval with a hashruns.org form and a portal review page.*

## Why

The old flow still runs, and it is failing in three ways:

1. **Real kennels are waiting.** Unapproved requests go back to 2021 (Wasatch,
   Calgary, Lyon, Madrid, Cairns…); the latest are Mersey Thirstday H3,
   Scottish Hashers Attempting Golf, Brum & Black Country H3 and Cha-Am H3
   (sent twice). Approval lives in the deprecated HC3W web app.
2. **Bots own the front door.** `ProcessWpForm` is an anonymous GET that takes
   the whole request in the query string. 11 of the pending rows since August
   are spam (random strings from "Afghanistan", Coinbase phishing).
3. **Approval creates broken kennels.** `HC3W.importKennel` gives every new
   kennel the logo `bundle://C-NNN` — art compiled into the old app. 62 of the
   63 `bundle://` logos in `HC.Kennel` came from it; they broke the auto
   check-in prompt on 2026-09-27. It also creates a `dbo.Users` login with a
   hard-coded password hash and hard-codes Tuna Melt's id as a helper admin.

Smaller faults: `EXT.ImportNewKennel` takes the whole form as one
`NVARCHAR(4000)` while two fields alone may each be 4,000 characters (silent
truncation); `EXT.ProcessKennelImports` geocodes with a cursor and
`CityName LIKE '%' + @City + '%'`.

## Today

```
harriercentral.com/index.php/add-kennel-standalone/  (static page, GET form)
  → API ProcessWpForm (anonymous, query string)
    → EXT.ImportNewKennel(@jsonData NVARCHAR(4000))
      → INSERT EXT.OfficeForms_KennelImport (462 rows since 2021)
      → EXT.ProcessKennelImports (guess CountryId/RegionId/CityId)
HC3W web app → EXT.vwOfficeForms_KennelImport (INSTEAD OF trigger: edit, soft delete)
            → HC3W.importKennel(@KennelImportId)  → HC.Kennel + dbo.Users + HKM
```

## Target

```
hashruns.org/add-kennel  (Next.js form: cascading country/region/city, honeypot,
                          time-to-submit, rate limit)
  → publicWeb_submitKennelRequest         → row, status 0 = awaiting email
  → email: "confirm your request" code    → publicWeb_confirmKennelRequest
                                             → status 1 = new (review queue)
Portal › Platform admin › Kennel requests  (CanEditKennel)
  → hcportal_getKennelRequests / hcportal_updateKennelRequest
  → hcportal_approveKennelRequest  → HC.Kennel + requester as kennel admin
                                     (hasher created if absent) + platform
                                     admins as helpers + sign-in code emailed
  → hcportal_rejectKennelRequest   → rejected / spam / duplicate + note
harriercentral.com add-kennel page → links (redirects) to hashruns.org/add-kennel
```

### Why these choices

- **The form moves to hashruns.org.** It is our live stack (server-side
  validation, error logging to `HC.ErrorLog`, the same auth-free pattern as the
  other `publicWeb_` writes), and harriercentral.com is a static mirror with
  no server to validate anything. The old page becomes a link.
- **Email confirmation is the spam wall.** A request enters the review queue
  only after the submitter types back a code we emailed them. Bots do not read
  mail; the honeypot, the time-to-submit check and a per-IP rate limit catch
  the rest before an email is ever sent. It also proves the address, which
  approval will use to create the admin's account and send their sign-in code.
- **Location is picked, not guessed.** The form offers the database's own
  countries, regions and cities (as the portal's run-location selector does),
  with "my city isn't listed" → free text the reviewer resolves. No cursor, no
  `LIKE`.
- **Approval does everything the club needs to start** — kennel, first admin
  (account created if they have none, exactly as `publicWeb_createMember`
  does through `hcapp_addEditUser`), and an emailed sign-in code — so the
  requester can run their club the same day.
- **A real logo.** New kennels get a stored default image (a URL), never a
  `bundle://` value.

## Storage — no new table

Keep `EXT.OfficeForms_KennelImport` (history intact) and add columns:

| Column | Type | Meaning |
|---|---|---|
| `RequestStatus` | `SMALLINT NOT NULL DEFAULT 1` | 0 awaiting email · 1 new · 2 approved · 3 rejected · 4 spam · 5 duplicate |
| `ConfirmCode` | `NVARCHAR(10) NULL` | Email confirmation code (cleared once used) |
| `ConfirmedAt` | `DATETIMEOFFSET NULL` | When the submitter confirmed |
| `ReviewedBy` | `UNIQUEIDENTIFIER NULL` | Platform admin who approved/rejected |
| `ReviewedAt` | `DATETIMEOFFSET NULL` | |
| `ReviewNote` | `NVARCHAR(1000) NULL` | Why rejected / what was changed |
| `SubmitIp` | `NVARCHAR(64) NULL` | Rate limiting and spam triage |

Not synced to phones, so no trigger precaution. Backfill: rows with a
`KennelId` → 2; `removed = 1` → 3; the rest stay 1 and appear in the queue
(the spam is then marked in one pass). The covid-era and feature-wish columns
stay for history; the new form no longer asks them.

## Stored procedures (one per commit, each with a contract)

| SP | Replaces | Notes |
|---|---|---|
| `publicWeb_submitKennelRequest` | `EXT.ImportNewKennel` | Typed parameters, `NVARCHAR(MAX)` + `LEN` checks, required fields, duplicate check (same email + short name in 30 days), returns the request id; emails the code |
| `publicWeb_confirmKennelRequest` | — | Code → status 1; wrong code 5× → spam |
| `hcportal_getKennelRequests` | the view | Filter by status; flags likely duplicates (short name already in the country) and existing accounts for the email |
| `hcportal_updateKennelRequest` | view trigger (update) | Edits incl. CountryId/RegionId/CityId |
| `hcportal_approveKennelRequest` | `HC3W.importKennel` | Unique short name (existing `-CC`, `-CCn` rule), real default logo, requester → kennel admin (created if absent), platform admins with `CanEditKennel` → helper access (replaces the Tuna Melt hard-code), sign-in code emailed, status 2; transacted; UPDLOCK on the request row so a double click cannot create two kennels |
| `hcportal_rejectKennelRequest` | view trigger (delete) | Status 3/4/5 + note |

All HC6 rules apply: TRY/CATCH with logging, rollback before `HC.ErrorLog`,
`ValidatePortalAuth` + `CanEditKennel` gate on the portal SPs.

## Portal

Platform admin menu → **Kennel requests**: a list (status chips: New · Awaiting
email · Approved · Rejected · Spam, count on New), and a detail page — the
request as submitted, editable fields, the location selector, "similar
kennels" and "existing account" warnings, and **Approve** / **Reject ▾**
(rejected · spam · duplicate). Light backdrop and portal dialog buttons as the
rest of the portal.

## Retire and clean up (after the new flow is live)

- harriercentral.com add-kennel page → link to hashruns.org/add-kennel.
- Remove the API `ProcessWpForm` endpoint (the spam vector).
- Archive `EXT.ImportNewKennel`, `EXT.ProcessKennelImports`,
  `EXT.vwOfficeForms_KennelImport` + trigger, `HC3W.importKennel`.
- Data fix: the 63 `bundle://C-NNN` kennel logos → stored image URLs.
- Triage the waiting requests in the new page (approve the real ones, mark
  the spam).

## Order

1. Columns + backfill (James runs the ALTER).
2. `hcportal_getKennelRequests`, `hcportal_updateKennelRequest`,
   `hcportal_approveKennelRequest`, `hcportal_rejectKennelRequest` + portal
   page → **the waiting kennels can be approved.**
3. `publicWeb_submitKennelRequest` + `publicWeb_confirmKennelRequest` +
   hashruns.org form + confirmation email.
4. Point harriercentral.com at it; retire `ProcessWpForm` and the old objects.
5. Logo data fix.
