import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/services/location_service/track_quality_ledger.dart';

/// The `[METRICS]` GPS figures: tier, fix count and accuracy — so the portal
/// can tell a starved Power Saver track from a bad-signal one.
void main() {
  setUp(TrackQualityLedger.resetForTest);

  test('writes nothing until a run was tracked', () {
    expect(TrackQualityLedger.tracked, isFalse);
    expect(TrackQualityLedger.summary(), '');
    TrackQualityLedger.record(8);
    expect(TrackQualityLedger.summary(), '');
  });

  test('a started run with no fixes still says which tier it was on', () {
    TrackQualityLedger.start(0);
    expect(
      TrackQualityLedger.summary(),
      'trk=saver pts=0 acc_avg=n/a acc_max=n/a acc_poor=0',
    );
  });

  test('counts fixes, averages accuracy and flags the poor ones', () {
    TrackQualityLedger.start(2);
    for (final double acc in <double>[10, 20, 30, 45.5]) {
      TrackQualityLedger.record(acc);
    }
    expect(
      TrackQualityLedger.summary(),
      'trk=best pts=4 acc_avg=26.4m acc_max=46m acc_poor=2',
    );
  });

  test('tier keys round-trip to the names the setting shows', () {
    expect(TrackQualityLedger.tierNameForKey('saver'), 'Power Saver');
    expect(TrackQualityLedger.tierNameForKey('balanced'), 'Balanced');
    expect(TrackQualityLedger.tierNameForKey('best'), 'Best');
  });
}
