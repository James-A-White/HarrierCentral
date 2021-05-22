import 'package:harrier_central/imports.dart';

class SecurePrefs {
  static FlutterSecureStorage storage;

  static const String HIVE_DEFAULT_BOX = 'hc_hive_default_box';
  static const String ENCRYPTION_KEY = 'secure_box_key';

  static Future<Uint8List> getEncryptionKey() async {
    Uint8List existing;
    final String existingFromStorage = await storage.read(key: ENCRYPTION_KEY);
    if (existingFromStorage != null) {
      existing = Uint8List.fromList(existingFromStorage.codeUnits);
    }
    existing ??= await initEncryptionKey();
    return existing;
  }

  static Future<Uint8List> initEncryptionKey() async {
    final List<int> hiveKey = Hive.generateSecureKey();
    await storage.write(key: ENCRYPTION_KEY, value: String.fromCharCodes(hiveKey));
    return hiveKey;
  }

  static Future<void> initPrefs() async {
    await Hive.initFlutter();
    storage = const FlutterSecureStorage();
  }

  static Future<void> clearPrefs() async {
    final Box<dynamic> hiveBox = await Hive.openBox<dynamic>(HIVE_DEFAULT_BOX, encryptionCipher: HiveAesCipher(await getEncryptionKey()));
    await hiveBox.clear();
  }

  //This Method Replaces: getStringPref, getNumPref, getIntPref, getDatePref, getBoolPref
  static Future<dynamic> getPref(dynamic key) async {
    final Box<dynamic> hiveBox = await Hive.openBox<dynamic>(HIVE_DEFAULT_BOX, encryptionCipher: HiveAesCipher(await getEncryptionKey()));
    final dynamic value = hiveBox.get(key.toString());
    return value;
  }

  static Future<DateTime> SecurePrefs.getDatePref(dynamic key) async {
    final dynamic rawVal = await getPref(key);
    return rawVal as DateTime;
  }

  static Future<String> getStringPref(dynamic key) async {
    final dynamic rawVal = await getPref(key);
    return rawVal as String;
  }

  static Future<int> getIntPref(dynamic key) async {
    final dynamic rawVal = await getPref(key);
    return rawVal as int;
  }

  static Future<bool> getBoolPref(dynamic key) async {
    final dynamic rawVal = await getPref(key);
    return rawVal as bool;
  }

  static Future<String> getUppercaseStringPref(dynamic key) async {
    final String val = await getPref(key);
    return val.toUpperCase();
  }

  static Future<List<String>> getStringListPref(dynamic key) async {
    final dynamic rawVal = await getPref(key);
    return rawVal as List<String> ?? [];
  }

  //This Method Replaces: await SecurePrefs.setPref, setNumPref, setIntPref, setPref, setBoolPref
  static Future<void> setPref(dynamic key, dynamic value) async {
    final Box<dynamic> hiveBox = await Hive.openBox<dynamic>(HIVE_DEFAULT_BOX, encryptionCipher: HiveAesCipher(await getEncryptionKey()));
    await hiveBox.put(key.toString(), value);
    return;
  }
}
