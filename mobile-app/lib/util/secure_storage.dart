import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Keychain keys. Prefixed to avoid collisions with any other secure entries.
const _kResetCodeKey = 'hc_resetCode';
const _kQrSecretCodeKey = 'hc_qrSecretCode';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

// ── Generic helpers ──────────────────────────────────────────────────────────

/// Reads a value from secure storage. Returns null if not present or if the
/// platform throws (e.g. a locked keystore).
Future<String?> _readSecure(String key) async {
  try {
    return await _storage.read(key: key);
  } catch (_) {
    return null;
  }
}

/// Writes a value to secure storage. Retries once on failure. Returns true on
/// success.
Future<bool> _writeSecure(String key, String value) async {
  for (int attempt = 0; attempt < 2; attempt++) {
    try {
      await _storage.write(key: key, value: value);
      return true;
    } catch (_) {}
  }
  return false;
}

// ── Reset code (durable recovery key) ────────────────────────────────────────

Future<String?> readSecureResetCode() => _readSecure(_kResetCodeKey);
Future<bool> writeSecureResetCode(String resetCode) =>
    _writeSecure(_kResetCodeKey, resetCode);

// ── QR secret code ───────────────────────────────────────────────────────────

Future<String?> readSecureQrSecretCode() => _readSecure(_kQrSecretCodeKey);
Future<bool> writeSecureQrSecretCode(String code) =>
    _writeSecure(_kQrSecretCodeKey, code);

// ── Wipe ─────────────────────────────────────────────────────────────────────

/// Wipes all entries from secure storage. Swallows any platform exceptions.
Future<void> deleteAllSecure() async {
  try {
    await _storage.deleteAll();
  } catch (_) {}
}
