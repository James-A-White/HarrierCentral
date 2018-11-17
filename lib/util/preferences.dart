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
  facebookId
}

enum IntPrefsEnum {
  mainViewCurrentTab,
  qrCodeViewCurrentTab
}

class Preferences {
  static SharedPreferences _sharedPreferences;

  static Future<void> initPrefs() async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
  }

  static String getStringPref(StringPrefsEnum key) {
    final String test = key.toString();
    return _sharedPreferences.getString(test);
  }

  static Future<bool> setStringPref(StringPrefsEnum key, String value) async {
    return _sharedPreferences.setString(key.toString(), value);
  }

  static int getIntPref(IntPrefsEnum key) {
    final String test = key.toString();
    return _sharedPreferences.getInt(test);
  }

  static Future<bool> setIntPref(IntPrefsEnum key, int value) async {
    return _sharedPreferences.setInt(key.toString(), value);
  }
}
