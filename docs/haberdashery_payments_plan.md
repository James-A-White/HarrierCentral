# Haberdashery Sales + Product-Aware Payment Reports

Follow-on to docs/membership_payments_plan.md (James, 2026-08-08): use
productType 3 to collect haberdashery money, and make payment reports
distinguish non-run payments (memberships are ALREADY live and were
inflating run totals until this work).

## V1 — simple sale (this iteration)

- **Amount + free-text description + payment method.** No catalog yet.
- `hcapp_processPayment` productType 3:
  - Debit = sale price (`@specialRunPrice` override, else `@paymentAmount`);
    event pricing, extras and HKM discounts never apply. Credit-neutral by
    the same ledger identity as memberships; Hash Credit can pay.
  - New `@notes NVARCHAR(500)` param → `Payment.Notes` (the description;
    the report SP already returns Notes).
  - **Multiple sales per HEM co-exist** — pt 3 skips the cancel-existing
    logic entirely (someone buys a shirt AND a mug). This differs from
    events/memberships, which keep single-active-payment-per-HEM.
  - `paymentType = 1` (mark not paid) is REFUSED for pt 3 — with
    multiple live rows it is ambiguous. Individual sale cancellation is a
    future feature (the rows carry everything needed).
  - HEM is anchor-only (no attendance/RSVP marking; neutral auto-create),
    same as memberships.
- **Mobile**: "Sell haberdashery" action beside the membership action on
  the check-in PaymentSnackBar → HaberdasherySaleSheet (amount,
  description, method chips).

## Payment report product-awareness

- `hcapp_getPaymentReport`: `productType` appended as the LAST column of
  every UNION part (the Excel endpoint reads ordinals 8/14/15 — trailing
  append keeps them stable). Summary rows (part 3) now GROUP BY
  paymentType AND productType, so "Cash — runs", "Cash — memberships"
  and "Cash — haberdashery" total separately.
- **Mobile report page**: detail rows get a Membership/Haberdashery tag
  (+ notes already shown); summary lines labelled per product.
- **Excel email report** (`SendPaymentReport.cs`): new "Product" column
  reading the appended ordinal; ships with the next API deploy.

## Future — full product catalog (not in v1)

- Kennel-defined catalog (name, price, sizes/variants?, active flag) —
  likely `HC.KennelProduct` + portal management UI + app picker replacing
  the free-text box (which remains as an "other" fallback).
- Individual sale cancellation from the payment report.
- Stock tracking explicitly out of scope until someone actually asks.
