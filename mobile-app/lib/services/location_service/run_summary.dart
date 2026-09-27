import 'package:harrier_central/data/models/user_positions/user_positions.dart';
import 'package:latlong2/latlong.dart' as latlng;

/// What a runner is told when they stop tracking (James, 2026-09-27): how far,
/// how long, how many checks they went through, how many drink stops, and how
/// long they spent at them. Pure — tracks in, numbers out — so it is tested.
class RunSummary {
  const RunSummary({
    required this.checksReached,
    required this.checksOnTrail,
    required this.drinkStopsReached,
    required this.drinkStopTime,
  });

  /// Checks (anyone's check marks, merged where several people marked the
  /// same one) the runner's track came within [reachMeters] of.
  final int checksReached;

  /// Every distinct check marked on the run, reached or not.
  final int checksOnTrail;

  final int drinkStopsReached;

  /// Time the runner's track spent within [drinkStopStayMeters] of a drink
  /// stop they reached.
  final Duration drinkStopTime;

  /// The map's "who got here" radius (RunTrackerMapController), so a check
  /// the summary counts is one the map would list them at.
  static const double reachMeters = 20;

  /// Several runners mark the same check; marks of one kind this close are
  /// one mark. Same as the map's de-duplication.
  static const double mergeMeters = 25;

  /// A drink stop is a pub, a car boot or a table, and people wander about it.
  static const double drinkStopStayMeters = 40;

  static const latlng.Distance _distance = latlng.Distance();

  /// [ownTrack] is the runner's points, oldest first (marks included or not —
  /// typed points are skipped). [allPoints] is every runner's points on the
  /// run, the runner's own included: the marks are read from it.
  static RunSummary compute({
    required List<TrackPoint> ownTrack,
    required Iterable<TrackPoint> allPoints,
  }) {
    final List<TrackPoint> gps = ownTrack
        .where((TrackPoint p) => (p.type ?? '').isEmpty)
        .toList()
      ..sort((a, b) => a.timestampMs.compareTo(b.timestampMs));

    final List<latlng.LatLng> checks = <latlng.LatLng>[];
    final List<latlng.LatLng> drinks = <latlng.LatLng>[];
    for (final TrackPoint p in allPoints) {
      switch (classifyMark(p.type)) {
        case SummaryMarkKind.check:
          _addDistinct(checks, latlng.LatLng(p.lat, p.lng));
        case SummaryMarkKind.drinkStop:
          _addDistinct(drinks, latlng.LatLng(p.lat, p.lng));
        case null:
          break;
      }
    }

    // A mark the runner put down themselves proves they were there, even if
    // their GPS was poor at that moment.
    final Set<int> ownMarkChecks = <int>{};
    final Set<int> ownMarkDrinks = <int>{};
    for (final TrackPoint p in ownTrack) {
      final SummaryMarkKind? kind = classifyMark(p.type);
      if (kind == null) continue;
      final latlng.LatLng at = latlng.LatLng(p.lat, p.lng);
      final List<latlng.LatLng> list =
          kind == SummaryMarkKind.check ? checks : drinks;
      for (int i = 0; i < list.length; i++) {
        if (_metres(list[i], at) <= mergeMeters) {
          (kind == SummaryMarkKind.check ? ownMarkChecks : ownMarkDrinks).add(i);
        }
      }
    }

    int checksReached = 0;
    for (int i = 0; i < checks.length; i++) {
      if (ownMarkChecks.contains(i) || _passes(gps, checks[i], reachMeters)) {
        checksReached++;
      }
    }

    int drinksReached = 0;
    int stayMs = 0;
    for (int i = 0; i < drinks.length; i++) {
      final bool reached =
          ownMarkDrinks.contains(i) || _passes(gps, drinks[i], reachMeters);
      if (!reached) continue;
      drinksReached++;
      stayMs += _timeWithin(gps, drinks[i], drinkStopStayMeters);
    }

    return RunSummary(
      checksReached: checksReached,
      checksOnTrail: checks.length,
      drinkStopsReached: drinksReached,
      drinkStopTime: Duration(milliseconds: stayMs),
    );
  }

  static void _addDistinct(List<latlng.LatLng> list, latlng.LatLng at) {
    for (final latlng.LatLng m in list) {
      if (_metres(m, at) <= mergeMeters) return;
    }
    list.add(at);
  }

  static bool _passes(List<TrackPoint> gps, latlng.LatLng mark, double r) {
    for (final TrackPoint p in gps) {
      if (_metres(mark, latlng.LatLng(p.lat, p.lng)) <= r) return true;
    }
    return false;
  }

  /// Sum of the gaps between consecutive fixes that are BOTH inside [r].
  /// Standing still produces few fixes (the stream has a distance filter), so
  /// one long inside-to-inside gap is exactly the time spent there.
  static int _timeWithin(List<TrackPoint> gps, latlng.LatLng mark, double r) {
    int total = 0;
    bool prevInside = false;
    int prevTs = 0;
    for (final TrackPoint p in gps) {
      final bool inside = _metres(mark, latlng.LatLng(p.lat, p.lng)) <= r;
      if (inside && prevInside) total += p.timestampMs - prevTs;
      prevInside = inside;
      prevTs = p.timestampMs;
    }
    return total;
  }

  static double _metres(latlng.LatLng a, latlng.LatLng b) =>
      _distance.as(latlng.LengthUnit.Meter, a, b);
}

enum SummaryMarkKind { check, drinkStop }

/// Reads a track point's type as a check or a drink stop, across every mark
/// scheme still in the data: `GLY::check` / `GLY::drinkstop` (current),
/// `TXT::DS` / `TXT::BS` (drink / beer stop text tiles), legacy `I-NNN.png`
/// slot icons (1–4 check, 450–452 drink stop), and the legacy `CHK` / `DRK`
/// keys. Anything else — plain GPS, photos, labels, On Inn — is null.
SummaryMarkKind? classifyMark(String? type) {
  final String value = (type ?? '').trim();
  if (value.isEmpty) return null;
  final List<String> parts = value.split('::');
  final String key = parts.first.trim();
  final String primary =
      parts.length > 1 ? parts[1].trim().toLowerCase() : '';

  if (key == 'GLY') {
    if (primary == 'check') return SummaryMarkKind.check;
    if (primary == 'drinkstop') return SummaryMarkKind.drinkStop;
    return null;
  }
  if (key == 'TXT') {
    if (primary == 'ds' || primary == 'bs') return SummaryMarkKind.drinkStop;
    return null;
  }
  if (key == 'CHK') return SummaryMarkKind.check;
  if (key == 'DRK') return SummaryMarkKind.drinkStop;
  if (key.startsWith('I-')) {
    final int dot = key.indexOf('.');
    final int n = int.tryParse(key.substring(2, dot < 0 ? key.length : dot)) ?? -1;
    if (n >= 1 && n <= 4) return SummaryMarkKind.check;
    if (n >= 450 && n <= 452) return SummaryMarkKind.drinkStop;
  }
  return null;
}
