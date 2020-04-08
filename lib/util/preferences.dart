import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

enum StringPrefsEnum {
  userId,
  qrCode,
  supportCode,
  resetCode,
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
  adminKennelId,
  customEmailBody,
  iosDownloadLink,
  androidDownloadLink,
  imageRootUrl,
}

enum NumPrefsEnum { latitude, longitude, homeKennelLat, homeKennelLon }

enum IntPrefsEnum {
  databaseVersion,
  hasherPreferences,
  //lastSuccessfulUserDataSyncInMs,
  hasLocationPermissions,
  dbCreated,
  mapCenterOption,
  mapShowSearchBar,
  mapShowKennels
}

enum DatePrefsEnum {
  lastSuccessfulUserDataSyncAsDate
}

SharedPreferences _sharedPreferences;

Future<void> initPrefs() async {
  _sharedPreferences ??= await SharedPreferences.getInstance();
}

Future<bool> clearPrefs() async {
  _sharedPreferences ??= await SharedPreferences.getInstance();
  return _sharedPreferences.clear();
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

num getNumPref(NumPrefsEnum key) {
  final String val = key.toString();
  return _sharedPreferences.getDouble(val);
}

Future<bool> setNumPref(NumPrefsEnum key, num value) async {
  return _sharedPreferences.setDouble(key.toString(), value);
}

num getIntPref(IntPrefsEnum key) {
  return _sharedPreferences.getInt(key.toString());
}

Future<bool> setIntPref(IntPrefsEnum key, int value) async {
  return _sharedPreferences.setInt(key.toString(), value);
}

Future<bool> setDatePref(DatePrefsEnum key, DateTime value) async {
  return _sharedPreferences.setInt(key.toString(), value.millisecondsSinceEpoch);
}

DateTime getDatePref(DatePrefsEnum key) {
  final int ms = _sharedPreferences.getInt(key.toString());
  if (ms == null) 
  {
    return null;
  }
  return DateTime.fromMillisecondsSinceEpoch(ms);
}

num getIntPrefStrKey(String key) {
  return _sharedPreferences.getInt(key);
}

Future<bool> setIntPrefStrKey(String key, int value) async {
  return _sharedPreferences.setInt(key, value);
}
