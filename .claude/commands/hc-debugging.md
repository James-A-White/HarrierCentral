# HC — On-Device Debug Logging & Harvest

> **Load this skill whenever you touch on-device error logging, the debug-harvest
> flag, log upload, the "Copy Boot Log" feature, or need to read a tester's logs.**
> Logging is a per-user, server-controlled feature that is silent when off and
> ships logs one boot LATE — both facts trip people up.

The mobile app can capture a rolling session error log on a tester's device and
ship it to the server. It's gated per-user by a server flag, so it's off for
everyone by default and enabled only for named testers.

---

## Enabling / disabling (per user, server-controlled)

The switch is **`HC.Hasher.Preferences` bit `0x100`** (`hasherPref_debugHarvestEnabled`,
`mobile-app/lib/util/constants.dart`).

- It is returned in the login response (`hcapp_approveLogin` → `h.Preferences`) and
  read by `AppBootService` into the local pref `BoolPrefsEnum.debugHarvestEnabled`
  (`_setPrefsFromLogin`, ~line 631). **This is the ONLY place the local flag is set —
  there is NO in-app toggle.** So a device has logging on iff its user's server bit is on.
- **Enable:** `UPDATE HC.Hasher SET Preferences = Preferences | 256 WHERE ...` (256 = 0x100).
  **Disable:** `& ~256`. Takes effect on the user's **next login/boot** that hits approveLogin.
- **No deploy needed** — it's purely a DB flag; the infra already ships in the app.

### Who are the beta testers?
- **`HC.Hasher.IsBetaTester = 1` is USELESS** — set on ~500 users (a broad legacy default).
- The **curated cohort is `HC.Hasher.BetaFeaturesEnabled` non-empty** (value `'RunTracker'`,
  the PackTrack beta) — ~6 users. That is the real "iOS beta testers" list.
- Beware duplicate DisplayNames (e.g. two "Rack of Lamb"); scope by the RunTracker flag,
  not the name.

---

## The flow (capture → persist → upload)

1. **Capture:** `BootLogger.logError(tag, error, stack)` (`lib/util/boot_logger.dart`),
   called from ~23 sites (HTTP errors in `service_common`, boot, etc.). Before the harvest
   callback is wired it buffers in memory; after, it persists.
2. **Persist:** when harvest is on, `AppBootService._startErrorPersistence` wires the
   callback and each entry is appended to the pref `StringPrefsEnum.lastSessionErrorLog`
   (`_persistErrorEntry`), capped at ~100 000 chars. When harvest is OFF, the buffer is
   discarded — nothing is stored.
3. **Upload (one boot LATE):** on the NEXT boot, `_sendPreviousSessionErrors()` reads
   `lastSessionErrorLog`, clears it, and uploads via `ServiceCommon.recordClientErrorLog`
   → SP **`hcapp_logClientErrors`** → row in **`HC.ClientErrorLog(DeviceId, ErrorLog)`**.
   ⇒ **A session's logs arrive server-side only after the tester relaunches the app.** Not
   real-time. Certain critical errors (e.g. device-not-registered) upload immediately.
4. **Manual copy:** the **"Copy Boot Log"** button in the Hasher Profile page
   (`hasher_profile_page.dart`, UI-element flag `0x800`) copies the CURRENT
   `lastSessionErrorLog` to the clipboard. It is shown **only when
   `debugHarvestEnabled == true`** (`drawer_menu.dart` gates the profile flag on it).

### ⚠️ The "I have the button so it's on for everyone" trap
The Copy-Boot-Log button being visible means **that user's** harvest flag is on — it says
nothing about other users. Each tester is enabled independently via their own
`Preferences` bit. Seeing the button ≠ logging enabled globally.

---

## Reading a tester's logs

Uploaded logs live in **`HC.ClientErrorLog`** (DeviceId, ErrorLog, timestamp). To read a
hasher's logs, resolve their device(s) and join:

```sql
SELECT cel.*
FROM HC.ClientErrorLog cel
JOIN HC.Device d ON d.id = cel.DeviceId          -- (confirm the Device PK/column name)
JOIN HC.Hasher h ON h.id = d.UserId              -- (confirm the Device→user column)
WHERE h.DisplayName = '...';
```

Remember: the newest session's log only appears after the tester has **relaunched** since
it was captured.

---

## Key symbols / files

- Flag bit: `hasherPref_debugHarvestEnabled = 0x100` (constants.dart)
- Capture: `BootLogger` (`lib/util/boot_logger.dart`)
- Persist/upload/enable: `AppBootService._startErrorPersistence`, `_persistErrorEntry`,
  `_sendPreviousSessionErrors`, `_setPrefsFromLogin` (`lib/data/services/app_boot_service.dart`)
- Upload transport: `ServiceCommon.recordClientErrorLog` (`service_common.dart`) →
  `HC6.hcapp_logClientErrors` → `HC.ClientErrorLog`
- Manual copy: `hasher_profile_page.dart` (`flagUiElement_copyBootLog = 0x800`,
  `_copyBootLogToClipboard`)
- Local pref: `BoolPrefsEnum.debugHarvestEnabled`; log store `StringPrefsEnum.lastSessionErrorLog`

Related: [[reference_device_log_harvest]] (the enable mechanism + beta cohort).
