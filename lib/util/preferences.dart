import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

enum StringPrefsEnum {
  userId,
  qrCode,
  qrSecretCode,
  displayName,
  firstName,
  lastName,
  hashName,
  email,
  gender,
  profilePhotoUrl,
  facebookId,
  facebookAccessToken,
  facebookProfilePhoto,
}

enum NumPrefsEnum { latitude, longitude }

SharedPreferences _sharedPreferences;

Future<void> initPrefs() async {
  _sharedPreferences ??= await SharedPreferences.getInstance();
}

String getStringPref(StringPrefsEnum key) {
  final String test = key.toString();
  return _sharedPreferences.getString(test);
}

Future<bool> setStringPref(StringPrefsEnum key, String value) async {
  return _sharedPreferences.setString(key.toString(), value);
}

num getNumPref(NumPrefsEnum key) {
  final String test = key.toString();
  return _sharedPreferences.getDouble(test);
}

Future<bool> setNumPref(NumPrefsEnum key, num value) async {
  return _sharedPreferences.setDouble(key.toString(), value);
}
