import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/util/run_pack_off.dart';

/// RunPackOff is the one place the app decides when the pack leaves
/// (E3.F1.S6): COALESCE(run, kennel, 0) minutes after the gather, the same
/// rule as the SPs. The run card, the run page and auto start all read it.
void main() {
  group('effectiveMinutes', () {
    test('no run override and no kennel default = at the gather', () {
      expect(RunPackOff.effectiveMinutes(), 0);
      expect(
        RunPackOff.effectiveMinutes(runMinutes: null, kennelMinutes: null),
        0,
      );
    });

    test('kennel default only', () {
      expect(RunPackOff.effectiveMinutes(kennelMinutes: 30), 30);
    });

    test('the run override wins over the kennel default', () {
      expect(
        RunPackOff.effectiveMinutes(runMinutes: 45, kennelMinutes: 30),
        45,
      );
    });

    test('an override of 0 means at the gather, beating the kennel', () {
      expect(RunPackOff.effectiveMinutes(runMinutes: 0, kennelMinutes: 30), 0);
    });

    test('a negative stored value never moves the pack earlier', () {
      expect(RunPackOff.effectiveMinutes(runMinutes: -5), 0);
    });
  });

  group('packOffAt', () {
    final DateTime gather = DateTime(2026, 10, 18, 12, 0);

    test('null at the gather, so callers show nothing extra', () {
      expect(RunPackOff.packOffAt(gather, 0), isNull);
    });

    test('gather plus the minutes', () {
      expect(RunPackOff.packOffAt(gather, 30), DateTime(2026, 10, 18, 12, 30));
    });

    test('runs past midnight', () {
      expect(
        RunPackOff.packOffAt(DateTime(2026, 10, 18, 23, 45), 30),
        DateTime(2026, 10, 19, 0, 15),
      );
    });
  });

  test('describeMinutes', () {
    expect(RunPackOff.describeMinutes(0), 'at the gather');
    expect(RunPackOff.describeMinutes(30), '30 min after the gather');
    expect(RunPackOff.describeMinutes(60), '1 h after the gather');
    expect(RunPackOff.describeMinutes(90), '1 h 30 min after the gather');
  });

  group('overrideFor', () {
    test('the gather time with no kennel default follows the kennel', () {
      expect(RunPackOff.overrideFor(0, null), isNull);
    });
    test('the kennel default time follows the kennel', () {
      expect(RunPackOff.overrideFor(30, 30), isNull);
    });
    test('the gather time when the kennel sets off later is the run\'s own 0', () {
      expect(RunPackOff.overrideFor(0, 30), 0);
    });
    test('any other time is the run\'s own', () {
      expect(RunPackOff.overrideFor(45, 30), 45);
      expect(RunPackOff.overrideFor(15, null), 15);
    });
  });
}
