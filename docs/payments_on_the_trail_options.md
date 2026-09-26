# Taking money on the trail — card and free options

Research and recommendation, 2026-09-26. Stories: `E8.F7.S1`–`S10` in
`docs/backlog.md`. Card fees and country lists change; re-check the sources
before building.

## Recommendation

1. **Keep the E8.F7 model.** The kennel holds the merchant relationship, the
   app hands off, and every payment is accounted for in Harrier Central.
2. **Build "pay the club directly" first** (`E8.F7.S5`–`S8`). It is free, needs
   no contract or partner approval, reuses the payment ledger and the
   statement import, and reaches the countries card providers miss (Singapore,
   Hong Kong, India).
3. **SumUp as the card provider**, after one test: does Payment Switch work
   with Tap to Pay on the phone (`E8.F7.S9`)?
4. **Zettle adds no country SumUp lacks.** It was chosen alongside SumUp on
   2026-09-22; whether to keep it is James's decision (noted on `E8.F7.S2`).
5. **Stripe only if New Zealand or Asia ask** — the widest card coverage, but
   each club needs its own connected Stripe account.
6. **Wero** is shown as a phone number or email for now (`E8.F7.S10`), and
   becomes a proper QR entry if Wero publishes an open request format.

## Card: who covers which country

**Zettle** (now "PayPal Point of Sale"): 12 countries — UK, DE, FR, IT, ES,
NL, SE, NO, DK, FI, BR, MX. SumUp is in all 12.

**SumUp:** 38 countries — most of the EU, UK, IE, CH, NO, US, CA, AU, BR, CL,
CO, PE, MX. Tap to Pay on iPhone is not listed for the US, Canada, Greece or
Mexico, so clubs there need SumUp's card reader. UK fee 1.69%, or 0.99% on a
£16/month plan.

**Neither:** New Zealand, Singapore, Hong Kong, Malaysia, Japan, South
Africa, India, most of Asia and Africa. Tap to Pay on iPhone there comes from
Stripe (NZ, SG, MY, JP), Windcave or Adyen (NZ), Square (JP), Yoco (ZA), and
Adyen, Global Payments or SoéPay (HK).

**Integration:**

| Provider | How our app starts a payment | Caveat |
|---|---|---|
| SumUp | Payment Switch URL scheme; result returned to a callback URL | SumUp calls it legacy; Tap to Pay support not documented. Native SDK is the fallback; the Android Tap to Pay SDK needs SumUp's approval |
| Zettle | Native Payments SDKs only; merchant OAuth | No app switch, no first-party Flutter plugin, Tap to Pay in the SDK unconfirmed |
| Stripe | Terminal SDK in our app | Each club needs a connected Stripe account; community Flutter plugins only |
| Square | Point of Sale API app switch | Mobile Payments SDK is US, CA and AU only |

No card option is free. The cheapest are about 1–1.7% in the UK and EU, and
about 2.6–2.7% plus 15¢ in the US.

## Free: pay the club directly

Transfers between accounts cost the payer and the club nothing on personal
and most club accounts. **The app cannot see the money arrive**, so a direct
payment is recorded as "hasher says paid" and confirmed by the Hash Cash, or
matched from the club's bank statement.

| Rail | Countries | App can build it with the amount filled in? |
|---|---|---|
| EPC / SEPA QR ("GiroCode") | DE, AT, NL, BE, FI | Yes, open payload: IBAN, name, amount, reference |
| PIX | Brazil | Yes, static BR Code (EMV) from the club's PIX key |
| PayNow | Singapore | Yes, SGQR/EMV from a phone number or company id |
| FPS | Hong Kong | Yes, HKMA EMV QR |
| UPI | India | Yes, `upi://pay?pa=…&am=…&tn=…` |
| Swish | Sweden | Yes, public QR API with the amount locked; per-payment bank fee on a business number |
| Payment links | PayPal.me, Monzo.me | Yes, the amount goes in the URL |
| UK bank transfer | UK | No UK QR standard: show sort code, account number and reference |
| Zelle, Interac e-Transfer, PayID | US, CA, AU | No: show the club's address or id |
| Wero | DE, FR, BE now; LU 2026; NL from Q4 2026 | Not yet: no open format found — show the club's phone or email |

## Wero

Person-to-person payments are live in Germany, France and Belgium.
Luxembourg joins in 2026. In the Netherlands Wero replaces iDEAL: banks due
ready in Q4 2026, full migration targeted for 2027. Businesses and
associations can be paid by QR code, payment request, or phone number or
email; the business version is reported at about 0.7%. No open QR or request
format or third-party API was found: businesses reach it through payment
providers (Mollie, Stripe) or Wero's own app.

## Sources

- Zettle countries: https://www.zettle.com/gb/help/articles/1084553-which-countries-is-zettle-available-in
- Zettle SDK: https://developer.zettle.com/docs/payment-integrations/android-sdk
- SumUp countries: https://developer.sumup.com/tools/glossary/countries-and-currencies
- SumUp Payment Switch: https://developer.sumup.com/terminal-payments/payment-switch
- SumUp Android Tap to Pay SDK: https://developer.sumup.com/terminal-payments/sdks/android-ttp
- SumUp UK fees: https://www.sumup.com/en-gb/tap-to-pay-on-android/
- Apple Tap to Pay providers by region: https://developer.apple.com/tap-to-pay/regions/
- Stripe Tap to Pay: https://stripe.com/terminal/tap-to-pay
- Square POS API: https://developer.squareup.com/docs/pos-api/what-it-does
- Swish QR API: https://developer.getswish.se/qr-api-manual/4-create-qr-codes-using-swish-qr-code-generator-apis/
- Wero 2025/2026: https://banking.vision/en/development-wero-2025-2026/
- Wero for professionals: https://wero-wallet.eu/payment-for-professionals
- Wero via Mollie: https://www.mollie.com/payments/wero
- Wero for businesses (Stripe): https://stripe.com/resources/more/wero-how-europes-unified-digital-wallet-is-changing-payments
