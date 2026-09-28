import 'package:latlong2/latlong.dart' as latlng;

/// One GPS fix held while PackTrack auto-start is armed.
class AutoStartFix {
  const AutoStartFix({
    required this.lat,
    required this.lng,
    required this.acc,
    required this.alt,
    required this.tsMs,
  });

  final double lat;
  final double lng;
  final double acc;
  final double alt;
  final int tsMs;
}

/// Decides when an armed runner has set off, from the fixes alone (James,
/// 2026-09-27). Pure — no GPS, no clock — so it is unit-tested.
///
/// A ring holds the last [ringDuration] of fixes. With an [anchor] (the run's
/// start point) the runner must first ARRIVE — a fix within [arriveMeters] —
/// and has set off once every fix for [sustain] is more than [departMeters]
/// from it. Hashers mill about the start for ten minutes; walking to the car
/// and back does not trip it, setting off does. Without an anchor (a run with
/// no start point) the first usable fix becomes the anchor.
///
/// On a start, [pointsFrom] gives the ring from [backfill] before the runner
/// first crossed out, so the track begins where they left, not a minute in.
/// Nothing earlier ever leaves the phone.
class AutoStartDetector {
  AutoStartDetector({
    latlng.LatLng? anchor,
    this.arriveMeters = 200,
    this.departMeters = 150,
    this.sustain = const Duration(seconds: 60),
    this.backfill = const Duration(seconds: 60),
    this.ringDuration = const Duration(minutes: 15),
    this.maxAccuracyMeters = 60,
    this.maxArrivalAccuracyMeters = 300,
  }) : _anchor = anchor;

  final double arriveMeters;
  final double departMeters;
  final Duration sustain;
  final Duration backfill;
  final Duration ringDuration;

  /// Fixes worse than this are kept in the ring and never decide a DEPARTURE.
  final double maxAccuracyMeters;

  /// Fixes worse than this cannot even count as arriving (a cell-tower fix
  /// kilometres wide would "arrive" from anywhere).
  final double maxArrivalAccuracyMeters;

  latlng.LatLng? _anchor;
  bool _arrived = false;
  int? _outsideSinceMs;
  int? _startTsMs;
  final List<AutoStartFix> _ring = <AutoStartFix>[];

  static const latlng.Distance _distance = latlng.Distance();

  latlng.LatLng? get anchor => _anchor;
  bool get hasArrived => _arrived;
  bool get hasStarted => _startTsMs != null;
  int? get startTsMs => _startTsMs;
  List<AutoStartFix> get ring => List<AutoStartFix>.unmodifiable(_ring);

  /// Adds a fix; returns the start time (epoch ms, backfill included) the
  /// first time the runner is judged to have set off, otherwise null.
  int? add(AutoStartFix fix) {
    _ring.add(fix);
    final int cutoff = fix.tsMs - ringDuration.inMilliseconds;
    _ring.removeWhere((AutoStartFix f) => f.tsMs < cutoff);

    if (_startTsMs != null) return null;

    final latlng.LatLng here = latlng.LatLng(fix.lat, fix.lng);

    // Arrival is LENIENT: a fix counts when its accuracy circle could include
    // the start. A pack waits indoors — Black Death #200 (2026-09-27) met in
    // a pub, where fixes are commonly 60-150 m — and a strict test ignored
    // every one, so the runner never "arrived" and auto start switched itself
    // off. Arriving decides nothing by itself; setting off below still needs
    // good fixes.
    if (!_arrived && _anchor != null && fix.acc <= maxArrivalAccuracyMeters) {
      final double d = _distance(_anchor!, here);
      if (d - fix.acc <= arriveMeters) _arrived = true;
      return null;
    }

    if (fix.acc > maxAccuracyMeters) return null;
    _anchor ??= here;
    final double d = _distance(_anchor!, here);

    if (!_arrived) {
      if (d <= arriveMeters) _arrived = true;
      return null;
    }

    if (d <= departMeters) {
      _outsideSinceMs = null;
      return null;
    }
    _outsideSinceMs ??= fix.tsMs;
    if (fix.tsMs - _outsideSinceMs! >= sustain.inMilliseconds) {
      _startTsMs = _outsideSinceMs! - backfill.inMilliseconds;
      return _startTsMs;
    }
    return null;
  }

  /// The ring's fixes at or after [tsMs], oldest first.
  List<AutoStartFix> pointsFrom(int tsMs) =>
      _ring.where((AutoStartFix f) => f.tsMs >= tsMs).toList();
}
