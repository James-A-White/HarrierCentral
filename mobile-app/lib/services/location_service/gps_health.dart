import 'package:harrier_central/data/models/user_positions/user_positions.dart';

/// PackTrack GPS health (E5.F1.S13, James 2026-09-30). City H3 #1941: of
/// five tracked runners one was on Power Saver (15 fixes in an hour), one
/// iPhone had Location set to While Using (a 27-minute hole with the app in
/// the background) — and nobody was told anything until they looked at the
/// map afterwards. These are the pure parts: a signal light from the age and
/// accuracy of the last fix, and the one-line track-health verdict on the
/// run summary. Tracks in, words out, so they are tested.

/// What the Live Run page's signal light shows.
enum SignalLight { green, amber, red }

/// Silence this long is a lost phone, not a slow one: red, one buzz.
const Duration kSignalRedAfter = Duration(seconds: 120);

/// A fix younger than this with a tight accuracy is green.
const Duration kSignalGreenWithin = Duration(seconds: 30);
const double kSignalGreenAccuracyM = 25;

/// [age] is how long since the last fix (or since tracking began, when there
/// has not been one yet). [accuracyM] is that fix's radius, null when there
/// is no fix. Green needs both a recent fix and a tight one; anything not
/// green and not two minutes silent is amber.
SignalLight classifySignal({required Duration age, required double? accuracyM}) {
  if (age >= kSignalRedAfter) return SignalLight.red;
  if (accuracyM != null &&
      age < kSignalGreenWithin &&
      accuracyM <= kSignalGreenAccuracyM) {
    return SignalLight.green;
  }
  return SignalLight.amber;
}

/// The words beside the light: `GPS 8 s ago · 6 m`, `No GPS fix for 2 min`,
/// `Waiting for GPS…`. [stationary] is set when a probe has just answered —
/// the stream is quiet because the phone has not moved, not because it is
/// deaf.
String signalText({
  required Duration age,
  required double? accuracyM,
  bool stationary = false,
}) {
  if (accuracyM == null) {
    return age >= kSignalRedAfter
        ? 'No GPS fix for ${_shortAge(age)}'
        : 'Waiting for GPS…';
  }
  if (stationary) return 'GPS fine · standing still';
  if (age >= kSignalRedAfter) return 'No GPS fix for ${_shortAge(age)}';
  return 'GPS ${_shortAge(age)} ago · ${accuracyM.round()} m';
}

String _shortAge(Duration d) {
  if (d.inSeconds < 60) return '${d.inSeconds} s';
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  return '${d.inHours} h ${(d.inMinutes % 60).toString().padLeft(2, '0')}';
}

/// The tracking-quality tier's name (`IntPrefsEnum.trackingQuality`:
/// 0 Power Saver, 1 Balanced, 2 Best — the default when unset).
String trackingTierName(int? tier) {
  switch (tier) {
    case 0:
      return 'Power Saver';
    case 1:
      return 'Balanced';
    default:
      return 'Best';
  }
}

/// The track-health line on the run summary: `412 fixes · longest gap 1 min
/// · Best`, or, when the pre-flight found something the runner started
/// anyway with, `92 fixes · a 27-minute gap · Location was While Using`.
class TrackHealth {
  const TrackHealth({
    required this.fixCount,
    required this.longestGap,
    required this.tier,
    this.problem,
  });

  /// GPS fixes this session (typed marks are not fixes).
  final int fixCount;

  /// Longest silence between consecutive fixes.
  final Duration longestGap;

  /// The tracking-quality tier the session ran on. Null when it is not
  /// known — a past run read back from the server — and the line then ends
  /// at the gap.
  final int? tier;

  /// What the pre-flight found and the runner started with regardless, e.g.
  /// `Location was While Using`. Null when the start was clean.
  final String? problem;

  /// A gap this long is the story of the run, and is said as such.
  static const Duration notableGap = Duration(minutes: 5);

  /// [points] is the session's own points in any order; marks are skipped.
  static TrackHealth compute({
    required Iterable<TrackPoint> points,
    required int? tier,
    String? problem,
  }) {
    final List<int> ts = points
        .where((TrackPoint p) => (p.type ?? '').isEmpty)
        .map((TrackPoint p) => p.timestampMs)
        .toList()
      ..sort();
    int longest = 0;
    for (int i = 1; i < ts.length; i++) {
      final int gap = ts[i] - ts[i - 1];
      if (gap > longest) longest = gap;
    }
    return TrackHealth(
      fixCount: ts.length,
      longestGap: Duration(milliseconds: longest),
      tier: tier,
      problem: problem,
    );
  }

  String get line {
    final String? tail = problem ?? (tier == null ? null : trackingTierName(tier));
    if (fixCount == 0) {
      return tail == null
          ? 'No GPS fixes were recorded'
          : 'No GPS fixes were recorded · $tail';
    }
    final StringBuffer b = StringBuffer();
    b.write('$fixCount fix${fixCount == 1 ? '' : 'es'}');
    if (fixCount > 1) b.write(' · ${_gapText(longestGap)}');
    if (tail != null) b.write(' · $tail');
    return b.toString();
  }

  static String _gapText(Duration gap) {
    final int minutes = (gap.inSeconds / 60).round();
    if (gap >= notableGap) return 'a $minutes-minute gap';
    if (gap.inSeconds < 60) return 'longest gap ${gap.inSeconds} s';
    return 'longest gap $minutes min';
  }
}
