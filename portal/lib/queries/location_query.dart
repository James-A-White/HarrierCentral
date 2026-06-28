import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/imports.dart';

// ---------------------------------------------------------------------------
// Location reference data: Country -> Region -> City
//
// Powers the cascading location selector in the run editor. Each SP returns a
// simple {id, Name} rowset; we project it to an ordered Map<String,String> of
// {id: name} (UUIDs lower-cased) — the shape the dropdowns consume.
// ---------------------------------------------------------------------------

String _deviceId() => box.get(HIVE_DEVICE_ID) as String;
String _deviceSecret() => (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';

String _token(String procName) =>
    Utilities.generateToken(_deviceId(), procName, paramString: _deviceSecret());

/// Projects a `[{id, <nameField>}]` rowset into an ordered {id: name} map,
/// lower-casing the UUID keys (SQL Server returns them upper-case).
Map<String, String> _toIdNameMap(List<dynamic> rows, String nameField) {
  final map = <String, String>{};
  for (final r in rows) {
    final row = r as Map<String, dynamic>;
    final id = (row['id'] as String?)?.toLowerCase();
    final name = row[nameField] as String?;
    if (id != null && name != null) {
      map[id] = name;
    }
  }
  return map;
}

/// Returns all countries as {id: name}. Caches the result in
/// [HIVE_COUNTRY_LIST] (countries are small and effectively static). On any
/// error, falls back to the cached copy if present, otherwise an empty map.
Future<Map<String, String>> queryCountries() async {
  final body = <String, String?>{
    'queryType': 'getCountries',
    'deviceId': _deviceId(),
    'accessToken': _token('hcportal_getCountries'),
  };

  final result = await ServiceCommon.sendHttpPostToHC6Api(body);
  if (kDebugMode) {
    debugPrint(result is ApiError
        ? 'SP [getCountries] — FAILED'
        : 'SP [getCountries] — success');
  }

  if (result is! ApiSuccess) return _cachedCountries();

  try {
    final rows = (json.decode(result.body) as List<dynamic>)[0] as List<dynamic>;
    final map = _toIdNameMap(rows, 'CountryName');
    if (map.isNotEmpty) {
      await box.put(HIVE_COUNTRY_LIST, map);
    }
    return map;
  } on Exception catch (e) {
    if (kDebugMode) debugPrint('queryCountries parse error: $e');
    return _cachedCountries();
  }
}

Map<String, String> _cachedCountries() {
  final cached = box.get(HIVE_COUNTRY_LIST);
  if (cached == null) return <String, String>{};
  return Map<String, String>.from(cached as Map);
}

/// Returns the regions for [countryId] as {id: name}. Empty map on error.
Future<Map<String, String>> queryRegions(String countryId) async {
  final body = <String, String?>{
    'queryType': 'getRegions',
    'deviceId': _deviceId(),
    'accessToken': _token('hcportal_getRegions'),
    'countryId': countryId,
  };

  final result = await ServiceCommon.sendHttpPostToHC6Api(body);
  if (kDebugMode) {
    debugPrint(result is ApiError
        ? 'SP [getRegions] — FAILED'
        : 'SP [getRegions] — success');
  }

  if (result is! ApiSuccess) return <String, String>{};

  try {
    final rows = (json.decode(result.body) as List<dynamic>)[0] as List<dynamic>;
    return _toIdNameMap(rows, 'RegionName');
  } on Exception catch (e) {
    if (kDebugMode) debugPrint('queryRegions parse error: $e');
    return <String, String>{};
  }
}

/// Returns the cities for [regionId] as {id: name}. Empty map on error.
Future<Map<String, String>> queryCities(String regionId) async {
  final body = <String, String?>{
    'queryType': 'getCities',
    'deviceId': _deviceId(),
    'accessToken': _token('hcportal_getCities'),
    'regionId': regionId,
  };

  final result = await ServiceCommon.sendHttpPostToHC6Api(body);
  if (kDebugMode) {
    debugPrint(result is ApiError
        ? 'SP [getCities] — FAILED'
        : 'SP [getCities] — success');
  }

  if (result is! ApiSuccess) return <String, String>{};

  try {
    final rows = (json.decode(result.body) as List<dynamic>)[0] as List<dynamic>;
    return _toIdNameMap(rows, 'CityName');
  } on Exception catch (e) {
    if (kDebugMode) debugPrint('queryCities parse error: $e');
    return <String, String>{};
  }
}
