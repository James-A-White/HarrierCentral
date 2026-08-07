# Annual Membership Payments — Implementation Plan

Core 3.0 feature (decided 2026-08-07). Kennels charge hashers for annual
memberships through the app: the payment is recorded but is credit-neutral
(no Hash Credit created), and the member's expiration date advances by the
kennel's rules.

## Decisions (James, 2026-08-07)

| Decision | Choice |
|---|---|
| Expiry rule | Per-kennel `MembershipRenewalMode`: 1=Rolling, 2=Fixed year, 3=Lifetime |
| Fee source | `Kennel.MembershipPrice` default, admin can override per charge |
| UI surfaces | Check-in pack page AND kennel-admin members list |
| Hash Credit | May be used to pay membership (ledger drains it naturally) |

### Renewal modes

1. **Rolling**: new expiry = `DATEADD(MONTH, MembershipDurationInMonths,
   max(current expiry, today))`. Early renewal stacks; lapsed restarts today.
2. **Fixed year**: kennel stores `MembershipPeriodStartDate`/`EndDate`;
   every payment sets expiry = period end. Charging while the period end is
   in the past is refused with "update your membership year in kennel
   settings" (errorType 2).
3. **Lifetime**: expiry set to the documented constant `2999-12-31`
   (deliberate sentinel — every existing `MembershipExpirationDate >
   GETDATE()` check, including member run-pricing in processPayment, works
   unchanged; flagged in the contract). Charging an existing lifetime member
   is refused, not double-charged.

## Why the ledger needs no special-casing

Credit balance = running `SUM(CreditAmount − DebitAmount)`
(`nonApi_updateKennelCreditByUser` — deliberately NO ProductType filter):

- Membership paid with money: credit = amount paid, debit = fee → net 0 →
  **no Hash Credit created** (requirement 1).
- Membership paid FROM Hash Credit (paymentType 6): credit 0, debit fee →
  net −fee → drains credit correctly.
- Overpayment (pays 25 for a 20 fee): net +5 → becomes credit, same as runs.

## Schema (Phase 0 — run-once script, JAMES runs it)

`db/hc6/membership_columns_ALTER.sql` — both tables are mobile-synced, so
the script disables each `updatedAt` trigger, ALTERs, re-enables (per the
standing rule; running it with triggers live would re-stamp every row and
force a full re-sync for all users). Archive the script after running.

- `HC.Kennel` + `MembershipRenewalMode SMALLINT NOT NULL DEFAULT 1`,
  `MembershipPeriodStartDate DATE NULL`, `MembershipPeriodEndDate DATE NULL`,
  `MembershipPrice DECIMAL(10,4) NOT NULL DEFAULT 0`
- `HC.Payment` + `PreviousMembershipExpiry DATETIMEOFFSET(7) NULL` — the
  unwind anchor: what the member's expiry was BEFORE this payment applied.

## Phase 1 — SP work (one SP per commit, contracts first)

**`hcapp_processPayment`** (the bulk of it):
- productType=2 path: `@debitAmount` = the charged fee (kennel default or
  override param) so net follows the table above; no event-price logic.
- The duplicate-payment guard (`@paymentExists` per HEM) must scope to
  ProductType — TODAY a membership charge on a check-in HEM would CANCEL
  the run payment on the same HEM. Guard becomes per (HEM, ProductType
  bucket: event vs membership).
- On pt=2 success: stamp `PreviousMembershipExpiry` = expiry-as-was, then
  write the new expiry per the kennel's mode (validations above).
- On pt=2 replace (double-tap/retry cancels old + inserts new): FIRST
  restore expiry from the cancelled payment's `PreviousMembershipExpiry`,
  then apply fresh — idempotent under replays, correct across mode changes.

**`hcapp_syncUserData` / `hcapp_syncKennelAdminData`**:
- Kennel rowsets + the 4 new kennel columns.
- HKM rowsets + raw `MembershipExpirationDate` (currently only the computed
  `isMember` flag is synced; admin UI needs the date for "who's due").

**Portal SP** (Phase 3): kennel-settings update SP gains the 4 kennel
columns so kennels can self-serve the config.

## Phase 2 — Mobile app

- Local DB: new columns on kennels + hasherKennelMap table helpers, Freezed
  models (`KennelsModel`, HKM model), local migration.
- **Check-in pack page**: "Annual membership" action beside the payment
  actions — pre-filled fee (editable), payment method picker including Hash
  Credit, calls processPayment with productType 2 + the HEM at hand.
  Confirmation shows the NEW expiry date.
- **Kennel-admin members list**: same charge dialog from a member row;
  event anchor = the kennel's most recent event (Payment.EventId is NOT
  NULL) — anchored via a small lookup in the charge flow.
- Expiry display: member row + check-in card show expiry (red when lapsed,
  ∞ for lifetime).
- Gating: same permission as processPayment (permissions v2).

## Phase 3 — Portal + polish

- Kennel settings page: renewal mode picker, price, period dates.
- Kennel members grid: expiry column already partially present via
  updateHasherField — verify display + edit still coherent.
- Consider an 8th 3.0 splash slide for memberships.

## Explicitly out of scope for 3.0

- Self-service renewal by the member (needs payment provider flow).
- Pro-rata pricing for fixed-year mode.
- Membership cancellation/refund UI (the PreviousMembershipExpiry anchor
  makes a future cancel SP straightforward).
