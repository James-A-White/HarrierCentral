import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/util/clock_offset.dart';

/// E1.F1.S7: the one-time notice is worded from the measured offset.
void main() {
  test('hours and minutes ahead', () {
    expect(
      ClockOffset.describe(const Duration(hours: 1, minutes: 36)),
      '1 hour and 36 minutes ahead',
    );
  });
  test('minutes behind, singular units', () {
    expect(
      ClockOffset.describe(const Duration(minutes: -4)),
      '4 minutes behind',
    );
    expect(ClockOffset.describe(const Duration(hours: 2)), '2 hours ahead');
    expect(
      ClockOffset.describe(const Duration(hours: -1, minutes: -1)),
      '1 hour and 1 minute behind',
    );
  });
  test('behind reads "behind Coordinated", never "behind of"', () {
    expect(
      ClockOffset.noticeFor(const Duration(minutes: -19)),
      startsWith(
        "Your phone's clock is 19 minutes behind Coordinated Universal Time.",
      ),
    );
  });
  test('the notice reads as James wrote it', () {
    expect(
      ClockOffset.noticeFor(const Duration(hours: 1, minutes: 36)),
      "Your phone's clock is 1 hour and 36 minutes ahead of Coordinated Universal Time. "
      'If you are experiencing problems with some of your apps, you may want to consider '
      'setting your phone to set the clock automatically from an internet time source.',
    );
  });
}
