# Store listing copy

The text that appears on the App Store and Google Play, kept in git so a change
is reviewable and the two stores can be compared side by side.

| File | Where it goes | Limit |
|---|---|---|
| `play_short.txt` | Play short description | **80** chars |
| `play_full.txt` | Play full description | 4000 chars |
| `play_notes.txt` | Play release notes, per release | **500** chars — the tight one |
| `apple_whatsnew.txt` | App Store "What's New in This Version" | 4000 chars |

The App Store *description* is not kept here: it is edited per version in App
Store Connect and was already current at 3.0.

## Pushing

**Play listing** (description + short description) can be pushed any time, and
unlike a release it commits straight to review — the
`changesNotSentForReview=True` dance that `tools/play_upload.py` needs does NOT
apply to a listing-only edit.

**Play release notes** are set on the release, by `tools/play_upload.py --notes`.

**App Store What's New** can only be set on a version in an editable state, so
it goes in when the next version is created — there is nothing to edit while the
live version sits at READY_FOR_SALE.

## Why these differ per store

Play drops the Apple Watch and iPad lines, which do not apply there. Play's
release notes carry the whole 3.0 story rather than the latest patch notes,
because Android went straight from 2.1.2 to 3.0 and its users have never been
told what 3.0 is — as of 2026-08-30 the live notes described only the 3.0.1
photo-picker fix.
