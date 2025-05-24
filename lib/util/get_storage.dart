import 'package:harrier_central/imports.dart';

late GetStorage _box;

Future<void> initPrefs() async {
  await GetStorage.init();
  _box = GetStorage();
}

Future<void> clearPrefs() async {
  return _box.erase();
}

// STRING

String? getStringPref(StringPrefsEnum key) {
  return _box.read(key.toString());
}

Future<void> setStringPref(StringPrefsEnum key, String? value) async {
  return _box.write(key.toString(), value);
}

// NUM

num? getNumPref(NumPrefsEnum key) {
  return _box.read(key.toString());
}

double? getDoublePref(dynamic key) {
  return _box.read(key.toString());
}

Future<void> setNumPref(NumPrefsEnum key, num? value) async {
  if (value == null) {
    return await _box.remove(key.toString());
  }

  return await _box.write(key.toString(), value.toDouble());
}

// INT

int? getIntPref(IntPrefsEnum key) {
  return _box.read(key.toString());
}

Future<void> setIntPref(IntPrefsEnum key, int? value) async {
  if (value == null) {
    return await _box.remove(key.toString());
  }
  return await _box.write(key.toString(), value);
}

// DATE

Future<void> setDatePref(DatePrefsEnum key, DateTime? value) async {
  if (value == null) {
    return await _box.remove(key.toString());
  }

  return await _box.write(key.toString(), value.millisecondsSinceEpoch);
}

DateTime? getDatePref(DatePrefsEnum key) {
  final int? ms = _box.read(key.toString());
  if (ms == null) {
    return null;
  }
  return DateTime.fromMillisecondsSinceEpoch(ms);
}

// BOOL

Future<void> setBoolPref(BoolPrefsEnum key, bool? value) async {
  if (value == null) {
    return await _box.remove(key.toString());
  }

  return await _box.write(key.toString(), value == true ? 1 : 0);
}

bool getBoolPref(BoolPrefsEnum key) {
  return _box.read(key.toString()) == 1;
}

// Map<String,int>

Future<void> setMapIntPref(dynamic key, Map<String, int>? value) async {
  if (key == null) {
    return;
  }

  if (value == null) {
    return await _box.remove(key.toString());
  }

  final jsonString = jsonEncode(value);

  return await _box.write(key.toString(), jsonString);
}

Map<String, int> getMapIntPref(dynamic key) {
  final jsonString = _box.read(key.toString());
  if (jsonString != null) {
    final Map<String, dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((key, value) => MapEntry(key, value as int));
  }
  return {}; // Return an empty map if nothing found
}

Future<void> removePref(dynamic key) async {
  return _box.remove(key.toString());
}

// Legacy code here for 1.x to 2.x migration

Future<String?> getStringPrefLegacy(dynamic key) async {
  var sharedPreferences = await SharedPreferences.getInstance();
  return sharedPreferences.getString(key.toString());
}
