import 'package:harrier_central/imports.dart';

/// Prefs layer, backed by shared_preferences (platform-native
/// SharedPreferences XML / NSUserDefaults — atomic, backup-aware).
///
/// History: 2.x–3.0 betas stored prefs via the `get_storage` package (a
/// single JSON file, package unmaintained since 2023). On first boot after
/// this change, [_migrateFromGetStorageIfNeeded] copies that file's values
/// across, then deletes it. Every cohort crosses the same path: production
/// 2.1.2 upgraders and 3.0 beta testers were all uniformly on get_storage.
///
/// The 1.x-era SharedPreferences legacy reader was removed 2026-08-25 —
/// no users remain on pre-2.0 builds (James).
late SharedPreferences _prefs;

const String _migratedFlagKey = 'prefsMigratedFromGetStorage';

Future<void> initPrefs() async {
  _prefs = await SharedPreferences.getInstance();
  await _migrateFromGetStorageIfNeeded();
}

/// One-time copy of the legacy get_storage JSON file into shared_preferences.
/// Best-effort: on success the file is deleted and a flag is set (the flag
/// guards against a backup restore resurrecting the file and overwriting
/// newer values); on failure nothing is flagged so the next boot retries.
Future<void> _migrateFromGetStorageIfNeeded() async {
  if (_prefs.getBool(_migratedFlagKey) ?? false) return;
  try {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File legacyFile = File('${dir.path}/GetStorage.gs');
    if (await legacyFile.exists()) {
      final dynamic decoded = jsonDecode(await legacyFile.readAsString());
      if (decoded is Map<String, dynamic>) {
        for (final MapEntry<String, dynamic> e in decoded.entries) {
          final dynamic v = e.value;
          if (v == null) continue;
          if (v is bool) {
            await _prefs.setBool(e.key, v);
          } else if (v is int) {
            await _prefs.setInt(e.key, v);
          } else if (v is double) {
            await _prefs.setDouble(e.key, v);
          } else if (v is String) {
            await _prefs.setString(e.key, v);
          } else {
            await _prefs.setString(e.key, jsonEncode(v));
          }
        }
      }
      await legacyFile.delete();
    }
    await _prefs.setBool(_migratedFlagKey, true);
  } catch (_) {
    // Leave unflagged so the next boot retries; worst case the app runs
    // with first-run defaults.
  }
}

Future<void> clearPrefs() async {
  await _prefs.clear();
  // A cleared store must not re-import stale legacy data on next boot.
  await _prefs.setBool(_migratedFlagKey, true);
}

// STRING

String? getStringPref(StringPrefsEnum key) {
  return _prefs.get(key.toString()) as String?;
}

Future<void> setStringPref(StringPrefsEnum key, String? value) async {
  if (value == null) {
    await _prefs.remove(key.toString());
    return;
  }
  await _prefs.setString(key.toString(), value);
}

// NUM

num? getNumPref(NumPrefsEnum key) {
  return _prefs.get(key.toString()) as num?;
}

double? getDoublePref(dynamic key) {
  final Object? v = _prefs.get(key.toString());
  return v is num ? v.toDouble() : null;
}

Future<void> setNumPref(NumPrefsEnum key, num? value) async {
  if (value == null) {
    await _prefs.remove(key.toString());
    return;
  }
  await _prefs.setDouble(key.toString(), value.toDouble());
}

// INT

int? getIntPref(IntPrefsEnum key) {
  final Object? v = _prefs.get(key.toString());
  return v is num ? v.toInt() : null;
}

Future<void> setIntPref(IntPrefsEnum key, int? value) async {
  if (value == null) {
    await _prefs.remove(key.toString());
    return;
  }
  await _prefs.setInt(key.toString(), value);
}

// DATE

Future<void> setDatePref(DatePrefsEnum key, DateTime? value) async {
  if (value == null) {
    await _prefs.remove(key.toString());
    return;
  }
  await _prefs.setInt(key.toString(), value.millisecondsSinceEpoch);
}

DateTime? getDatePref(DatePrefsEnum key) {
  final Object? v = _prefs.get(key.toString());
  if (v is! num) return null;
  return DateTime.fromMillisecondsSinceEpoch(v.toInt());
}

// BOOL — historically stored as int 1/0 (get_storage era); keep that
// encoding so migrated values read back unchanged. Raw bools from very old
// writes are tolerated on read.

Future<void> setBoolPref(BoolPrefsEnum key, bool? value) async {
  if (value == null) {
    await _prefs.remove(key.toString());
    return;
  }
  await _prefs.setInt(key.toString(), value ? 1 : 0);
}

bool? getBoolPref(BoolPrefsEnum key) {
  final Object? v = _prefs.get(key.toString());
  if (v == null) return null;
  if (v is bool) return v;
  return v == 1;
}

// Map<String,int>

Future<void> setMapIntPref(dynamic key, Map<String, int>? value) async {
  if (key == null) return;
  if (value == null) {
    await _prefs.remove(key.toString());
    return;
  }
  await _prefs.setString(key.toString(), jsonEncode(value));
}

Map<String, int> getMapIntPref(dynamic key) {
  final Object? jsonString = _prefs.get(key.toString());
  if (jsonString is String) {
    final Map<String, dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((key, value) => MapEntry(key, value as int));
  }
  return {}; // Return an empty map if nothing found
}

Future<void> setMapDynamicPref(dynamic key, Map<String, dynamic>? value) async {
  if (key == null) return;
  if (value == null) {
    await _prefs.remove(key.toString());
    return;
  }
  await _prefs.setString(key.toString(), jsonEncode(value));
}

Map<String, dynamic>? getMapDynamicPref(dynamic key) {
  final Object? jsonString = _prefs.get(key.toString());
  if (jsonString is String) {
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
  return null;
}

// Raw string-key access (queue storage etc. that predates the enums).

String? getRawPref(String key) {
  return _prefs.get(key) as String?;
}

Future<void> setRawPref(String key, String? value) async {
  if (value == null) {
    await _prefs.remove(key);
    return;
  }
  await _prefs.setString(key, value);
}

Future<void> removePref(dynamic key) async {
  await _prefs.remove(key.toString());
}
