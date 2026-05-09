import 'package:harrier_central/imports.dart';

Future<void> initPrefs() async {
  await GetStorage.init();
}

Future<void> clearPrefs() async {
  return GetStorage().erase();
}

// STRING

String? getStringPref(StringPrefsEnum key) {
  return GetStorage().read(key.toString());
}

Future<void> setStringPref(StringPrefsEnum key, String? value) async {
  return GetStorage().write(key.toString(), value);
}

// NUM

num? getNumPref(NumPrefsEnum key) {
  return GetStorage().read(key.toString());
}

double? getDoublePref(dynamic key) {
  return GetStorage().read(key.toString());
}

Future<void> setNumPref(NumPrefsEnum key, num? value) async {
  if (value == null) {
    return await GetStorage().remove(key.toString());
  }

  return await GetStorage().write(key.toString(), value.toDouble());
}

// INT

int? getIntPref(IntPrefsEnum key) {
  return GetStorage().read(key.toString());
}

Future<void> setIntPref(IntPrefsEnum key, int? value) async {
  if (value == null) {
    return await GetStorage().remove(key.toString());
  }
  return await GetStorage().write(key.toString(), value);
}

// DATE

Future<void> setDatePref(DatePrefsEnum key, DateTime? value) async {
  if (value == null) {
    return await GetStorage().remove(key.toString());
  }

  return await GetStorage().write(key.toString(), value.millisecondsSinceEpoch);
}

DateTime? getDatePref(DatePrefsEnum key) {
  final int? ms = GetStorage().read(key.toString());
  if (ms == null) {
    return null;
  }
  return DateTime.fromMillisecondsSinceEpoch(ms);
}

// BOOL

Future<void> setBoolPref(BoolPrefsEnum key, bool? value) async {
  if (value == null) {
    return await GetStorage().remove(key.toString());
  }

  return await GetStorage().write(key.toString(), value == true ? 1 : 0);
}

bool? getBoolPref(BoolPrefsEnum key) {
  final int? val = GetStorage().read(key.toString());
  if (val == null) {
    return null;
  }

  return val == 1 ? true : false;
}

// Map<String,int>

Future<void> setMapIntPref(dynamic key, Map<String, int>? value) async {
  if (key == null) {
    return;
  }

  if (value == null) {
    return await GetStorage().remove(key.toString());
  }

  final jsonString = jsonEncode(value);

  return await GetStorage().write(key.toString(), jsonString);
}

Map<String, int> getMapIntPref(dynamic key) {
  final jsonString = GetStorage().read(key.toString());
  if (jsonString != null) {
    final Map<String, dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((key, value) => MapEntry(key, value as int));
  }
  return {}; // Return an empty map if nothing found
}

Future<void> setMapDynamicPref(dynamic key, Map<String, dynamic>? value) async {
  if (key == null) {
    return;
  }

  if (value == null) {
    return await GetStorage().remove(key.toString());
  }

  final jsonString = jsonEncode(value);

  return await GetStorage().write(key.toString(), jsonString);
}

Map<String, dynamic>? getMapDynamicPref(dynamic key) {
  final jsonString = GetStorage().read(key.toString());
  if (jsonString != null) {
    final Map<String, dynamic> decoded = jsonDecode(jsonString);
    return decoded;
  }
  return null; // Return an empty map if nothing found
}

Future<void> removePref(dynamic key) async {
  return GetStorage().remove(key.toString());
}

// Legacy code here for 1.x to 2.x migration

Future<String?> getStringPrefLegacy(dynamic key) async {
  var sharedPreferences = await SharedPreferences.getInstance();
  return sharedPreferences.getString(key.toString());
}
