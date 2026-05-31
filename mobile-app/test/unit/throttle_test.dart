import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/util/get_storage.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/utilities_null_safe.dart';
import '../golden/test_helpers.dart';

void main() {
  setUp(() async {
    await setupTestEnvironment();
  });

  tearDown(() async {
    await tearDownTestEnvironment();
  });

  group('isAtRunStart throttle', () {
    test('suppresses second call within 2 minutes', () async {
      // Simulate a check that happened 30 seconds ago (within the 2-min window).
      final recentCheck = DateTime.now().subtract(const Duration(seconds: 30));
      await setDatePref(DatePrefsEnum.lastRunStartCheck, recentCheck);

      // Should return early without updating the timestamp or querying the DB.
      await Utilities.isAtRunStart();

      // If throttled: timestamp stays at recentCheck (~30s ago).
      // If not throttled: setDatePref would have updated it to DateTime.now().
      final stored = getDatePref(DatePrefsEnum.lastRunStartCheck)!;
      final driftSeconds = stored.difference(recentCheck).inSeconds.abs();
      expect(driftSeconds, lessThan(2),
          reason: 'timestamp should not have been updated when throttled');
    });

    test('allows call when last check was more than 2 minutes ago', () async {
      // Simulate a check that happened 3 minutes ago (past the threshold).
      final oldCheck = DateTime.now().subtract(const Duration(minutes: 3));
      await setDatePref(DatePrefsEnum.lastRunStartCheck, oldCheck);

      // Should pass the throttle gate and update the timestamp.
      // The subsequent DB query will throw/return empty in the test environment
      // (caught internally by CommonQueries.isAtRunStart), so the call still
      // completes normally.
      await Utilities.isAtRunStart();

      // Timestamp should now be updated to approximately DateTime.now().
      final stored = getDatePref(DatePrefsEnum.lastRunStartCheck)!;
      final secondsSinceUpdate =
          DateTime.now().difference(stored).inSeconds.abs();
      expect(secondsSinceUpdate, lessThan(5),
          reason: 'timestamp should have been refreshed after throttle passed');
    });
  });
}
