import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/imports.dart';

// ---------------------------------------------------------------------------
// Location reference data: Country -> Region -> City
//
// Powers the cascading location selector in the run editor. Each SP returns a
// simple {id, Name} rowset; we project it to an ordered Map<String,String> of
// {id: name} (UUIDs lower-cased) — the shape the dropdowns consume.
// ---------------------------------------------------------------------------

/// One clock representation of a city's time zone (Standard or Daylight).
class CityTimezone {
  const CityTimezone({
    required this.kind,
    required this.utcOffset,
    required this.iana,
    required this.windows,
    required this.observesDst,
  });

  /// 'Standard' or 'Daylight'.
  final String kind;

  /// Formatted offset, e.g. 'UTC+00:00'.
  final String utcOffset;

  /// IANA zone name, e.g. 'Europe/London' (may be empty).
  final String iana;

  /// Windows zone id, e.g. 'GMT Standard Time'.
  final String windows;

  /// Whether the zone observes daylight saving (same for both rows of a zone).
  final bool observesDst;
}

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
    // Also cache {id: NeighboringCountries} for the gazetteer country filter.
    final neighbors = <String, String>{};
    for (final r in rows) {
      final row = r as Map<String, dynamic>;
      final id = (row['id'] as String?)?.toLowerCase();
      final codes = row['NeighboringCountries'] as String?;
      if (id != null && codes != null) neighbors[id] = codes;
    }
    if (map.isNotEmpty) {
      await box.put(HIVE_COUNTRY_LIST, map);
      await box.put(HIVE_COUNTRY_NEIGHBORS, neighbors);
    }
    return map;
  } on Exception catch (e) {
    if (kDebugMode) debugPrint('queryCountries parse error: $e');
    return _cachedCountries();
  }
}

/// Cached neighbour-country codes for [countryId] (lower-cased UUID), e.g.
/// "GB,IE,FR". Empty string if unknown / not cached.
String countryNeighborCodesFor(String countryId) {
  final cached = box.get(HIVE_COUNTRY_NEIGHBORS);
  if (cached == null) return '';
  final map = Map<String, String>.from(cached as Map);
  return map[countryId.toLowerCase()] ?? '';
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

/// Returns the relevant timezone(s) — Standard, plus Daylight if the zone
/// observes DST — for a [cityId] (preferred) or a directly-chosen [timezoneId]
/// (the manual "Other"-location case). Empty list on error / no zone.
Future<List<CityTimezone>> queryCityTimezones({
  String? cityId,
  int? timezoneId,
}) async {
  final body = <String, String?>{
    'queryType': 'getCityTimezones',
    'deviceId': _deviceId(),
    'accessToken': _token('hcportal_getCityTimezones'),
    if (cityId != null) 'cityId': cityId,
    if (timezoneId != null) 'timezoneId': timezoneId.toString(),
  };

  final result = await ServiceCommon.sendHttpPostToHC6Api(body);
  if (kDebugMode) {
    debugPrint(result is ApiError
        ? 'SP [getCityTimezones] — FAILED'
        : 'SP [getCityTimezones] — success');
  }

  if (result is! ApiSuccess) return <CityTimezone>[];

  try {
    final rows = (json.decode(result.body) as List<dynamic>)[0] as List<dynamic>;
    return [
      for (final r in rows)
        if ((r as Map<String, dynamic>)['utcOffset'] != null)
          CityTimezone(
            kind: r['kind'] as String? ?? '',
            utcOffset: r['utcOffset'] as String? ?? '',
            iana: r['ianaTimeZone'] as String? ?? '',
            windows: r['windowsTimeZone'] as String? ?? '',
            observesDst: r['observesDst'] == true || r['observesDst'] == 1,
          ),
    ];
  } on Exception catch (e) {
    if (kDebugMode) debugPrint('queryCityTimezones parse error: $e');
    return <CityTimezone>[];
  }
}

/// Returns the timezones available for a geography as `{timezoneId: label}`,
/// for the manual picker used when a location is free-text ("Other"). Narrowed
/// to [regionId] when supplied. Empty map on error.
Future<Map<int, String>> queryTimezonesForGeography(
  String countryId, {
  String? regionId,
}) async {
  final body = <String, String?>{
    'queryType': 'getTimezonesForGeography',
    'deviceId': _deviceId(),
    'accessToken': _token('hcportal_getTimezonesForGeography'),
    'countryId': countryId,
    if (regionId != null) 'regionId': regionId,
  };

  final result = await ServiceCommon.sendHttpPostToHC6Api(body);
  if (kDebugMode) {
    debugPrint(result is ApiError
        ? 'SP [getTimezonesForGeography] — FAILED'
        : 'SP [getTimezonesForGeography] — success');
  }

  if (result is! ApiSuccess) return <int, String>{};

  try {
    final rows = (json.decode(result.body) as List<dynamic>)[0] as List<dynamic>;
    final map = <int, String>{};
    for (final r in rows) {
      final row = r as Map<String, dynamic>;
      final id = row['id'];
      if (id is! int) continue;
      final display = row['displayName'] as String? ?? '';
      final offset = row['utcOffset'] as String? ?? '';
      map[id] = offset.isEmpty ? display : '$display ($offset)';
    }
    return map;
  } on Exception catch (e) {
    if (kDebugMode) debugPrint('queryTimezonesForGeography parse error: $e');
    return <int, String>{};
  }
}
