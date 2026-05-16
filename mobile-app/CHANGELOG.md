# Harrier Central Mobile App — Changelog

## 2.4.2+1108 (2026-05-16)

### Enhancements

- **Profile — distance preference auto-saves on selection**: Selecting a distance
  unit (Auto / Kilometers / Miles) in the profile settings now immediately saves the
  preference to the server without requiring the "Save Changes" button. A spinner
  appears next to the "Distance Preference" heading while the call is in-flight, and
  the radio group is non-interactive until the save completes.

### Bug fixes

- **Hash History — wrong table domain in hasher profile view**: Run history launched
  from a hasher's profile was reading from the kennel-domain tables instead of the
  common-domain tables, causing empty or incorrect history. Fixed to always use the
  common domain for all history views.
- **Hash History — missing table prefix in country history query**: The UNION branch
  of the country history query referenced `kennels` instead of `common_kennels`,
  causing a SQLite "no such table" error. Fixed.
- **Hash History — missing table alias in run history UNION query**: JOIN conditions
  in the UNION branch were missing the `hem.` alias, causing ambiguous column errors.
  Fixed.
- **Hash History — UUID not normalised in country stats**: `CountryStats.fromMap` was
  not normalising the `countryId` UUID, causing country drill-down navigation to fail
  silently when the server returned uppercase UUIDs. Fixed.
- **Kennel admin — past runs not loading**: Kennel admins who were not following a
  kennel saw an empty past runs calendar because `common_events` only holds 10 days
  of history for unfollowed kennels. The app now automatically follows the kennel and
  force-replicates all event history before entering admin screens.
- **Kennel admin — filter events GetX crash**: The `publishedRunCount` field was a
  plain `List`, causing the `Obx` widget that reads it to throw a GetX "improper use"
  error on load. Made it reactive (`RxList`).
- **Kennel admin — manual refresh skipped kennel domain sync**: Pull-to-refresh on
  the filter events page only re-synced events, leaving kennel-domain membership data
  stale. Now also refreshes `hasherKennelMap` via `syncKennelAdminService`.
- **Chat — access token always rejected**: `hcapp_getEventMessages` and
  `hcapp_sendEventMessage` were generating compound tokens (`deviceSecret + eventId`)
  but the SPs validated against `eventId` only. Token generation and SPs now both use
  the standard device-secret token.

## 2.4.1+1107 (2026-05-13)

7 bug fixes — see git log for details.

## 2.4.0+1106 (2026-05-10)

State management overhaul, 4 new GetX migrations, boot fix.
