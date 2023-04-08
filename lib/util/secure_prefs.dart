import 'package:harrier_central/imports.dart';

late SharedPreferences _sharedPreferences;

Future<void> initPrefs() async {
  _sharedPreferences = await SharedPreferences.getInstance();
}

Future<bool> clearPrefs() async {
  _sharedPreferences = await SharedPreferences.getInstance();
  return _sharedPreferences.clear();
}

// STRING

String? getStringPref(dynamic key) {
  return _sharedPreferences.getString(key.toString());
}

Future<bool> setStringPref(dynamic key, String? value) async {
  if ((key == null) || (value == null)) {
    return false;
  }
  return _sharedPreferences.setString(key.toString(), value);
}

// NUM

num? getNumPref(dynamic key) {
  return _sharedPreferences.getDouble(key.toString());
}

double? getDoublePref(dynamic key) {
  return _sharedPreferences.getDouble(key.toString());
}

Future<bool> setNumPref(dynamic key, num? value) async {
  if (key == null) {
    return false;
  }
  if (value == null) {
    return removePref(key);
  }

  return _sharedPreferences.setDouble(key.toString(), value.toDouble());
}

// INT

int? getIntPref(dynamic key) {
  return _sharedPreferences.getInt(key.toString());
}

Future<bool> setIntPref(dynamic key, int? value) async {
  if (key == null) {
    return false;
  }

  if (value == null) {
    return removePref(key);
  }
  return _sharedPreferences.setInt(key.toString(), value);
}

// DATE

Future<bool> setDatePref(dynamic key, DateTime? value) async {
  if (key == null) {
    return false;
  }

  if (value == null) {
    return removePref(key);
  }

  return _sharedPreferences.setInt(key.toString(), value.millisecondsSinceEpoch);
}

DateTime? getDatePref(dynamic key) {
  final int? ms = _sharedPreferences.getInt(key.toString());
  if (ms == null) {
    return null;
  }
  return DateTime.fromMillisecondsSinceEpoch(ms);
}

// BOOL

Future<bool> setBoolPref(dynamic key, bool? value) async {
  if (key == null) {
    return false;
  }

  if (value == null) {
    return removePref(key);
  }

  return _sharedPreferences.setInt(key.toString(), value == true ? 1 : 0);
}

bool getBoolPref(dynamic key) {
  return _sharedPreferences.getInt(key.toString()) == 1;
}

Future<bool> removePref(dynamic key) async {
  bool result = false;
  if (_sharedPreferences.containsKey(key.toString())) {
    result = await _sharedPreferences.remove(key.toString());
  }
  return result;
}
