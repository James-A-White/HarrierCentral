import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/get_storage.dart';
import 'package:harrier_central/util/secure_storage.dart';

/// Single source of truth for the device's **sensitive credentials** — values
/// that must live in the keychain (encrypted at rest), not plain GetStorage.
///
/// Covered here: the device **reset code** (the durable recovery key, the one
/// thing that survives a reset) and the **qrSecretCode**. Each helper reads
/// keychain-first and falls back to a legacy GetStorage copy (pre-2.11 installs);
/// each write promotes to the keychain and removes the GetStorage copy. Always go
/// through these — never read/write these values via the prefs/keychain directly.
///
/// NOTE: the **device secret** is a planned addition. It stays in GetStorage for
/// now (it's read on every API call and needs a sync RAM cache to avoid keychain
/// latency — a focused 2.11.x follow-up). It is still wiped & regenerated on
/// every reset, so recovery is unaffected.

// ── Reset code ───────────────────────────────────────────────────────────────

/// Reads the reset code, keychain-first, GetStorage fallback. Null if neither
/// holds a non-empty value.
Future<String?> getResetCode() async {
  final String? secure = await readSecureResetCode();
  if (secure != null && secure.isNotEmpty) return secure;
  final String? legacy = getStringPref(StringPrefsEnum.resetCode);
  return (legacy != null && legacy.isNotEmpty) ? legacy : null;
}

/// Persists the reset code to the keychain (removing any legacy GetStorage copy)
/// and records the storage-type indicator. Falls back to GetStorage if the
/// keychain is unavailable. Returns true if it ended up encrypted.
Future<bool> saveResetCode(String? code) async {
  if (code == null || code.isEmpty) {
    await setStringPref(StringPrefsEnum.resetCode, code);
    await setStringPref(StringPrefsEnum.storageType, 'legacy');
    return false;
  }
  if (await writeSecureResetCode(code)) {
    await removePref(StringPrefsEnum.resetCode);
    await setStringPref(StringPrefsEnum.storageType, 'encrypted');
    return true;
  }
  await setStringPref(StringPrefsEnum.resetCode, code);
  await setStringPref(StringPrefsEnum.storageType, 'legacy');
  return false;
}

// ── QR secret code ───────────────────────────────────────────────────────────

/// Reads the qrSecretCode, keychain-first, GetStorage fallback.
Future<String?> getQrSecretCode() async {
  final String? secure = await readSecureQrSecretCode();
  if (secure != null && secure.isNotEmpty) return secure;
  final String? legacy = getStringPref(StringPrefsEnum.qrSecretCode);
  return (legacy != null && legacy.isNotEmpty) ? legacy : null;
}

/// Persists the qrSecretCode to the keychain (removing any legacy GetStorage
/// copy). Falls back to GetStorage if the keychain is unavailable.
Future<bool> saveQrSecretCode(String? code) async {
  if (code == null || code.isEmpty) {
    await setStringPref(StringPrefsEnum.qrSecretCode, code);
    return false;
  }
  if (await writeSecureQrSecretCode(code)) {
    await removePref(StringPrefsEnum.qrSecretCode);
    return true;
  }
  await setStringPref(StringPrefsEnum.qrSecretCode, code);
  return false;
}

// ── Boot promotion ───────────────────────────────────────────────────────────

/// Promotes any legacy GetStorage copies of the sensitive credentials into the
/// keychain and records the storage-type indicator. Idempotent — safe to call on
/// every normal boot. Handles a pre-2.11 install whose values are still in
/// GetStorage. Each promotion writes to the keychain BEFORE removing the
/// GetStorage copy, so a failure never loses the value.
Future<void> ensureCredentialsEncrypted() async {
  // Reset code — also drives the storage-type indicator.
  final String? secureReset = await readSecureResetCode();
  if (secureReset != null && secureReset.isNotEmpty) {
    await setStringPref(StringPrefsEnum.storageType, 'encrypted');
  } else {
    final String? legacyReset = getStringPref(StringPrefsEnum.resetCode);
    if (legacyReset != null && legacyReset.isNotEmpty) {
      await saveResetCode(legacyReset); // promotes + sets the indicator
    }
  }

  // QR secret code.
  final String? secureQr = await readSecureQrSecretCode();
  if (secureQr == null || secureQr.isEmpty) {
    final String? legacyQr = getStringPref(StringPrefsEnum.qrSecretCode);
    if (legacyQr != null && legacyQr.isNotEmpty) {
      await saveQrSecretCode(legacyQr);
    }
  }
}

/// Discards the stored reset code and QR secret from BOTH the keychain and the
/// legacy plain-prefs location.
///
/// Call this only when the server has positively told us the code can never
/// work again (see [isDeadInviteCode]). On iOS the keychain survives an app
/// uninstall, so a dead code left in place is retried on every launch forever
/// and reinstalling cannot clear it.
Future<void> clearStoredResetCode() async {
  try {
    await deleteAllSecure();
  } catch (_) {
    // Keep going: clearing the legacy plain copy still breaks the retry loop
    // for anyone whose code never made it into the keychain.
  }
  await removePref(StringPrefsEnum.resetCode);
  await removePref(StringPrefsEnum.qrSecretCode);
}
