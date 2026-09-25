import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// Which unit a distance is shown in. Two encodings meet here: the hasher's
/// preference (3 miles, 2 km, 0 Auto) and the kennel's (1 miles, 0 km).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> hasherPref(int unit) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await initPrefs();
    // Keep the other bits the emulator's hasher had (270) apart from unit.
    await setIntPref(IntPrefsEnum.hasherPreferences, (270 & ~0x03) | unit);
  }

  test('an explicit km choice wins over a miles kennel', () async {
    // The screen that showed "5369 miles" and "8644 km" side by side.
    await hasherPref(2);
    expect(Utilities.prefersImperial(kennelDistanceUnitsPref: 1), isFalse);
    expect(Utilities.prefersImperial(kennelDistanceUnitsPref: 0), isFalse);
  });

  test('an explicit miles choice wins over a km kennel', () async {
    await hasherPref(3);
    expect(Utilities.prefersImperial(kennelDistanceUnitsPref: 0), isTrue);
  });

  test('Auto follows the kennel in the KENNEL encoding (1 = miles)', () async {
    await hasherPref(0);
    // Was compared with 3, which no kennel holds: Auto never gave miles.
    expect(Utilities.prefersImperial(kennelDistanceUnitsPref: 1), isTrue);
    expect(Utilities.prefersImperial(kennelDistanceUnitsPref: 0), isFalse);
  });
}
