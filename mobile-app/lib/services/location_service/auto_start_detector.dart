import 'dart:math' as math;

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
/// Setting off means moving AWAY from the start, not merely being far from
/// it: the runner must also be more than [departFromClosestMeters] beyond the
/// closest a good fix has put them ([closestMeters]). Arriving is lenient, so
/// a vague fix on the walk in can count as arrived while the runner is still
/// hundreds of metres out — LH3 #2854 (2026-10-10) "arrived" coming off the
/// train 500 m away and auto start fired on the walk to the start. Walking IN
/// keeps lowering the closest distance, so it can never look like leaving.
///
/// On a start, [pointsFrom] gives the ring from [backfill] before the runner
/// first crossed out, so the track begins where they left, not a minute in.
/// Nothing earlier ever leaves the phone.
class AutoStartDetector {
  AutoStartDetector({
    latlng.LatLng? anchor,
    this.arriveMeters = 200,
    this.departMeters = 150,
    this.departFromClosestMeters = 100,
    this.sustain = const Duration(seconds: 60),
    this.backfill = const Duration(seconds: 60),
    this.ringDuration = const Duration(minutes: 15),
    this.maxAccuracyMeters = 60,
    this.maxArrivalAccuracyMeters = 300,
  }) : _anchor = anchor;

  final double arriveMeters;
  final double departMeters;

  /// How far beyond the closest approach counts as leaving (see the class doc).
  final double departFromClosestMeters;
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
  double? _closestMeters;
  double? _lastGoodMeters;
  final List<AutoStartFix> _ring = <AutoStartFix>[];

  static const latlng.Distance _distance = latlng.Distance();

  latlng.LatLng? get anchor => _anchor;
  bool get hasArrived => _arrived;
  bool get hasStarted => _startTsMs != null;

  /// The closest any good fix has put the runner to the start; null until a
  /// good fix with an anchor.
  double? get closestMeters => _closestMeters;

  /// The latest good fix's distance from the start; null as above.
  double? get lastGoodMeters => _lastGoodMeters;
  int? get startTsMs => _startTsMs;
  List<AutoStartFix> get ring => List<AutoStartFix>.unmodifiable(_ring);

  /// Adds a fix; returns the start time (epoch ms, backfill included) the
  /// first time the runner is judged to have set off, otherwise null.
  ///
  /// [blocked] (the hasher is in a vehicle, E5.F1.S15) keeps every fix in the
  /// ring but lets none count towards a departure — driving away from the
  /// start is not setting off.
  int? add(AutoStartFix fix, {bool blocked = false}) {
    _ring.add(fix);
    final int cutoff = fix.tsMs - ringDuration.inMilliseconds;
    _ring.removeWhere((AutoStartFix f) => f.tsMs < cutoff);

    if (_startTsMs != null) return null;

    final latlng.LatLng here = latlng.LatLng(fix.lat, fix.lng);

    // Every good fix updates the closest approach — before arriving too, so
    // the walk in is on record by the time arriving is decided.
    if (fix.acc <= maxAccuracyMeters) {
      _anchor ??= here;
      final double d = _distance(_anchor!, here);
      _lastGoodMeters = d;
      if (_closestMeters == null || d < _closestMeters!) _closestMeters = d;
    }

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
    final double d = _lastGoodMeters!;

    if (!_arrived) {
      if (d <= arriveMeters) _arrived = true;
      return null;
    }

    final double outside = math.max(
      departMeters,
      _closestMeters! + departFromClosestMeters,
    );
    if (blocked || d <= outside) {
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

/// The motion trigger for auto start (E5.F1.S15, James 2026-10-01). Pure — no
/// sensors, no clock — so it is unit-tested; the monitor feeds it activity
/// changes and asks it on every fix.
///
/// Hashers mill about the start, so being on foot there is not setting off.
/// After ARRIVING at the start:
///   * RUNNING sustained for [sustain] starts tracking — milling is walking —
///     unless the runner is not moving away from the start (less than
///     [runAwayMeters] beyond their closest approach): jogging IN late is
///     arriving, not setting off;
///   * WALKING / ON FOOT sustained for [sustain] starts tracking only when
///     more than [walkDepartMeters] beyond the closest the runner has been
///     to the start (walking to the car and back stays inside the GPS rule's
///     150 m and so does nothing; walking in from the station, LH3 #2854,
///     never gets further than its own closest point);
///   * IN A VEHICLE vetoes any start, this rule's and the GPS rule's, for
///     [vehicleVeto] after it was last seen.
/// Below [minConfidence] an activity is ignored (it does not reset either).
/// The start time handed back is when the qualifying motion began, less
/// [backfill], like the GPS rule's.
class MotionStartRule {
  MotionStartRule({
    this.sustain = const Duration(seconds: 20),
    this.walkDepartMeters = 100,
    this.runAwayMeters = 10,
    this.vehicleVeto = const Duration(minutes: 2),
    this.backfill = const Duration(seconds: 60),
    this.minConfidence = 50,
  });

  final Duration sustain;
  final double walkDepartMeters;
  final double runAwayMeters;
  final Duration vehicleVeto;
  final Duration backfill;
  final int minConfidence;

  bool _running = false;
  bool _onFoot = false;
  int? _sinceMs;
  int? _lastVehicleMs;

  /// A new reading from the phone.
  void onActivity(String kind, int confidence, int tsMs) {
    if (confidence < minConfidence) return;
    switch (kind) {
      case 'inVehicle':
        _lastVehicleMs = tsMs;
        _running = false;
        _onFoot = false;
        _sinceMs = null;
      case 'running':
        if (!_running) _sinceMs = tsMs;
        _running = true;
        _onFoot = true;
      case 'walking':
      case 'onFoot':
        // Running → walking keeps the clock going: still on the move.
        if (!_onFoot) _sinceMs = tsMs;
        _running = false;
        _onFoot = true;
      case 'still':
      case 'cycling':
        _running = false;
        _onFoot = false;
        _sinceMs = null;
      default:
        break; // unknown / tilting: no opinion
    }
  }

  /// In a vehicle within the last [vehicleVeto].
  bool vetoed(int nowMs) =>
      _lastVehicleMs != null &&
      nowMs - _lastVehicleMs! < vehicleVeto.inMilliseconds;

  /// The start time (epoch ms, backfill included) once the motion says the
  /// hasher has set off; null otherwise. [metersFromStart] (the latest good
  /// fix) and [closestMeters] (the closest good fix so far) are null when not
  /// known.
  int? check({
    required int nowMs,
    required bool arrived,
    required double? metersFromStart,
    required double? closestMeters,
  }) {
    if (!arrived || vetoed(nowMs) || !_onFoot || _sinceMs == null) return null;
    if (nowMs - _sinceMs! < sustain.inMilliseconds) return null;
    // How far the runner has come back out from their closest approach.
    final double? away = (metersFromStart == null || closestMeters == null)
        ? null
        : metersFromStart - closestMeters;
    if (_running) {
      // Unknown (no good fix yet, e.g. indoors) keeps the old behaviour.
      if (away != null && away < runAwayMeters) return null;
    } else if (away == null || away <= walkDepartMeters) {
      return null;
    }
    return _sinceMs! - backfill.inMilliseconds;
  }
}
