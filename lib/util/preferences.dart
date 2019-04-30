import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

enum StringPrefsEnum {
  userId,
  qrCode,
  supportCode,
  qrSecretCode,
  displayName,
  firstName,
  lastName,
  harrierCentralVersion,
  hashName,
  email,
  gender,
  profilePhotoUrl,
  facebookId,
  facebookAccessToken,
  facebookProfilePhoto,
  adminEventId,
}

enum DoublePrefsEnum { latitude, longitude }

enum IntPrefsEnum {
  lastUpdateAllHasherData,
  lastCacheClearAllHasherData,

  lastUpdateCitiesData,
  lastCacheClearCitiesData,
  lastUpdateRegionsData,
  lastCacheClearRegionsData,
  lastUpdateCountriesData,
  lastCacheClearCountriesData,
  lastUpdateKennelData,
  lastCacheClearKennelData,
  lastUpdateHashersData,
  lastCacheClearHashersData,
  lastUpdateNarrowEventsData,
  lastCacheClearNarrowEventsData,

  lastUpdatePaymentsData,
  lastCacheClearPaymentsData,

  lastUpdateReceiptsData,
  lastCacheClearReceiptsData,

  lastUpdateHasherKennelMaplData,
  lastCacheClearHasherKennelMapData,

  lastUpdateHasherEventMapData,
  lastCacheClearHasherEventMapData,

  lastUpdateAdminHasherEventMapData,
  lastCacheClearAdminHasherEventMapData,

  dbCreated,
}

SharedPreferences _sharedPreferences;

Future<void> initPrefs() async {
  _sharedPreferences ??= await SharedPreferences.getInstance();
}

String getStringPref(StringPrefsEnum key) {
  final String test = key.toString();
  return _sharedPreferences.getString(test);
}

Future<bool> clearAllPrefs() async {
  return _sharedPreferences.clear();
}

Future<bool> setStringPref(StringPrefsEnum key, String value) async {
  return _sharedPreferences.setString(key.toString(), value);
}

num getDoublePref(DoublePrefsEnum key) {
  final String test = key.toString();
  return _sharedPreferences.getDouble(test);
}

Future<bool> setDoublePref(DoublePrefsEnum key, double value) async {
  return _sharedPreferences.setDouble(key.toString(), value);
}

num getIntPref(IntPrefsEnum key) {
  final String test = key.toString();
  return _sharedPreferences.getInt(test);
}

Future<bool> setIntPref(IntPrefsEnum key, int value) async {
  return _sharedPreferences.setInt(key.toString(), value);
}
