import 'package:harrier_central/services/location_service/gps_health.dart';

/// What PackTrack recorded this session, for the `[METRICS]` line: the
/// tracking-quality tier the run was started on, how many GPS fixes went
/// onto the track, and how good they were.
///
/// Written so the portal's Device Health dialog can answer "was it the
/// phone or the setting?" for a runner whose trail came out sparse or
/// jagged (James, 2026-09-30): Power Saver on a 15-minute Android interval
/// gives 15 fixes in an hour; a poor signal gives hundreds at 30–100 m.
/// The two look the same on the map and nothing else told them apart.
///
/// Cumulative for the session, like every other `[METRICS]` figure. Only
/// untyped fixes count — marks, photo pins and boundary points are placed,
/// not measured, and a boundary point carries `acc=0`.
class TrackQualityLedger {
  TrackQualityLedger._();

  /// Fixes whose reported radius is wider than this are "poor" — the same
  /// threshold the signal light uses for amber.
  static const double poorAccuracyM = kSignalGreenAccuracyM;

  static int? _tier;
  static int _points = 0;
  static double _accuracySum = 0;
  static double _accuracyMax = 0;
  static int _poor = 0;

  /// True once a run was started this session — the line is written only
  /// then, so an ordinary day's metrics stay short.
  static bool get tracked => _tier != null;

  /// Stamped when tracking starts (a real start, not a resume from pause),
  /// with the `trackingQuality` tier: 0 Power Saver, 1 Balanced, 2 Best.
  /// A second run in the same session keeps counting on the same ledger;
  /// the tier shown is the latest.
  static void start(int tier) {
    _tier = tier;
  }

  /// One GPS fix accepted onto the track, with its reported radius in
  /// metres.
  static void record(double accuracyM) {
    _points++;
    _accuracySum += accuracyM;
    if (accuracyM > _accuracyMax) _accuracyMax = accuracyM;
    if (accuracyM > poorAccuracyM) _poor++;
  }

  /// `trk=saver pts=15 acc_avg=20.2m acc_max=45m acc_poor=4`, or empty when
  /// nothing was tracked this session.
  static String summary() {
    final int? tier = _tier;
    if (tier == null) return '';
    final String avg = _points == 0
        ? 'n/a'
        : '${(_accuracySum / _points).toStringAsFixed(1)}m';
    final String max = _points == 0 ? 'n/a' : '${_accuracyMax.round()}m';
    return 'trk=${tierKey(tier)} pts=$_points acc_avg=$avg acc_max=$max '
        'acc_poor=$_poor';
  }

  /// The tier as a short lower-case key for the log line; the portal maps it
  /// back to the name the app's setting shows.
  static String tierKey(int tier) {
    switch (tier) {
      case 0:
        return 'saver';
      case 1:
        return 'balanced';
      default:
        return 'best';
    }
  }

  /// The name the app's setting shows for a tier key, for the portal.
  static String tierNameForKey(String key) {
    switch (key) {
      case 'saver':
        return trackingTierName(0);
      case 'balanced':
        return trackingTierName(1);
      default:
        return trackingTierName(2);
    }
  }

  static void resetForTest() {
    _tier = null;
    _points = 0;
    _accuracySum = 0;
    _accuracyMax = 0;
    _poor = 0;
  }
}
