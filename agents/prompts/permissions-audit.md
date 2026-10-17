# Permissions audit — reviewer prompt (E18.F5.S1)

A repeatable audit of who may call what. Run it before a release, or whenever
gates have changed. It describes the METHOD only. Findings about live
weaknesses never go into this repository (it is public): write them to
`.local/permissions-audit-<date>/` (git-excluded) and to James.

How to run it: build the inventory (one row per SP: auth kind, gates, tables
written), split the SPs into batches of ~40, and give each batch to one
reviewer agent with the brief below. Then have a second agent try to REFUTE
each finding against the code and the live data before it is reported.

---

## Brief for each reviewer

You are auditing Harrier Central's authorization for one batch of stored
procedures (or API endpoints). Read-only: never edit a repo file, never run a
write against the database. You MAY run read-only `SELECT`s with `sqlcmd` and
the credentials in `.env` (see `tools/record_deploy.py` for the call) when the
data decides a question — e.g. which function keys `HC.PermissionFunction`
holds. Never print a secret, a token, a password or a person's email.
Ignore anything TSA-related entirely and do not mention it.

### Load first
- `.claude/skills/hc-authorizations/SKILL.md` — the two bitfields
  (AppAccessFlags, MismanagementRoles), the 0x08 collision, SuperAdmin
  0x40000000 = the kennel's Super Admin flag, scoped to that kennel (NOT platform staff — that is
  `HC.PlatformAdmin`), the stray `0x40000081` mask (should be 0x40000001).
  NOTE: the skill's description of `HC6.CheckKennelPermission` is out of date:
  it now takes `@functionKey` and reads `HC.PermissionFunction` /
  `HC.PermissionRole` / `HC.RolePermission` (Permissions v2), with SuperAdmin
  as the only bypass. Read `db/hc6/app/HC6.CheckKennelPermission.StoredProcedure.sql`.
- `.claude/skills/hc-primary-keys/SKILL.md` — public vs internal ids; a
  browser must hold public ids only.
- `.claude/skills/hc-access-tokens/SKILL.md` — `ValidateAppAuth` /
  `ValidatePortalAuth` prove IDENTITY only, never permission.

### The threat model
- The API shims turn every JSON body key into an SP parameter: `AppApiHC6`
  runs `HC6.hcapp_<queryType>`, `PortalApiHC6` runs `HC6.hcportal_<queryType>`.
  So an attacker is ANY signed-in hasher (any device that ever registered)
  calling ANY hcapp_ SP — or any portal device calling any hcportal_ SP — with
  ANY parameter values, including parameters the app never sends.
- `publicWeb_` SPs are called by the Next.js server through the API; whether a
  caller can reach them directly is part of the endpoint batch's question.
- `nonApi_` / `util_` / helpers are reachable only from other SPs or the API's
  own code — judge them by their callers.

### For every procedure, answer
1. **Who can call it?** App device, portal device, the web server, internal only.
2. **What does the caller choose?** Every id parameter (kennelId, eventId,
   hasherId/userId/targetId, messageId, paymentId, photoId, productId …) and
   every flag that widens scope.
3. **Whose data does it read or write?** The caller's own, a kennel's, a run's,
   another hasher's, money, roles, devices, secrets.
4. **Is every touch of someone else's data gated by a rule that ties the
   caller to THAT kennel / run / hasher?** Acceptable gates:
   `HC6.CheckKennelPermission` with the right function key and the RIGHT
   kennel; `HC6.nonApi_portalKennelAccess`; self-only (the row's UserId is the
   authenticated @userId, never a parameter); hare of that run; membership
   where the feature is members-only; `HC.PlatformAdmin` for platform-wide acts;
   `HC6.UserMayEnterChatRoom` / `HC6.UserInKennelMismanagement` for chats.
5. **Is it the RIGHT kennel?** The classic hole: the permission is checked on a
   caller-supplied @kennelId while the row acted on (found by @eventId,
   @paymentId, @photoId …) belongs to a DIFFERENT kennel. The kennel must be
   derived from the row, or the two must be checked to match.
6. **Mask hygiene:** `0x40000081`; a mask applied to the wrong column (0x08 is
   RA in MismanagementRoles, ManageHashCash in AppAccessFlags); IsAdmin 0x01
   treated as a bypass; SuperAdmin 0x40000000 used as "platform staff" across
   any row.
7. **What leaks in the reply?** Emails, phone numbers, bank details, API keys,
   device secrets, FCM tokens, reset/invite codes, internal ids to a browser,
   data of hashers who chose not to be found (DirectoryVisibility NULL/0),
   removed / GDPR-deleted hashers.
8. **Real names are not a leak** (James, 2026-10-17): first and last names may
   reach any signed-in user by design. Emails, phones, tokens and secrets are.
9. **Money: see vs change** (James, 2026-10-17): any admin of the kennel may
   SEE who paid for a run (and how much) — not a finding. Recording,
   confirming, cancelling or editing a payment, or spending credit, must need
   the Hash Cash permission; a money write gated on anything weaker (RA,
   ManageRuns, a hare) IS a finding. A hasher settling their OWN fee is the
   one self-service exemption.
10. **Writes by design open to all** are NOT findings when the product says so:
   anyone may post in a kennel's general chat; a hasher's own RSVP,
   preferences and attendance are theirs; public run and kennel details are
   public (the website shows them).

### Severity
- **critical** — any signed-in user can change money, roles/flags, another
  person's account, or read secrets (device secrets, reset codes, bank/API
  keys) in a kennel they have no role in.
- **high** — cross-kennel or cross-hasher write of ordinary data, or a read of
  personal data (emails, phones) beyond what the product shows.
- **medium** — a gate on the wrong kennel/function that needs an unusual
  setup to abuse; a role that gets more than the matrix intends.
- **low / info** — hygiene: stray masks that do not widen access in practice,
  inconsistent masks, missing defence in depth.

### Output
Write `<out-dir>/findings-<batch>.json`:
```json
{"batch": "<batch>", "reviewed": [{"sp": "...", "verdict": "ok|finding", "gate": "short description"}],
 "findings": [{"sp": "...", "severity": "...", "kind": "missing-gate|wrong-kennel|leak|mask|other",
   "summary": "one sentence", "evidence": "file:line and the lines that prove it",
   "precondition": "what an attacker needs", "fix": "the smallest correct fix"}]}
```
Every SP in the batch appears in `reviewed`. A finding must cite the lines;
"probably" is not a finding — say what you could not determine instead.
Reply with a 5-line summary only; the file is the result.
