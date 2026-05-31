import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Key used to persist the device reset code in the secure enclave.
// Prefixed to avoid collisions with any future secure-storage entries.
const _kResetCodeKey = 'hc_resetCode';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

/// Reads the reset code from secure storage.
/// Returns null if not present or if the platform throws (e.g. locked keystore).
Future<String?> readSecureResetCode() async {
  try {
    return await _storage.read(key: _kResetCodeKey);
  } catch (_) {
    return null;
  }
}

/// Writes the reset code to secure storage.
/// Retries once on failure. Returns true if the write succeeded.
Future<bool> writeSecureResetCode(String resetCode) async {
  for (int attempt = 0; attempt < 2; attempt++) {
    try {
      await _storage.write(key: _kResetCodeKey, value: resetCode);
      return true;
    } catch (_) {}
  }
  return false;
}

/// Wipes all entries from secure storage. Swallows any platform exceptions.
Future<void> deleteAllSecure() async {
  try {
    await _storage.deleteAll();
  } catch (_) {}
}
