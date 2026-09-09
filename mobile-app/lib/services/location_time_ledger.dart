import 'package:harrier_central/imports.dart';

/// Cumulative time the shared location stream has spent in each cost tier
/// this session. GPS is the app's dominant battery cost, and the tier
/// transitions are already breadcrumbed by [LocationService]; this sums them
/// so the `[METRICS]` line can say `loc_track=48m loc_precise=3m loc_idle=2h`
/// instead of leaving the reader to add up `stream ->` lines.
///
/// Tiers, from most to least expensive:
///   `track`    navigation-grade stream during a tracked run
///   `paused`   the high-accuracy movement-detection stream while a run is paused
///   `precise`  best-accuracy viewer stream while a map holds a precise boost
///   `idle`     the low-power 100–250 m stream the app runs when nothing is on
///   `off`      no stream (before boot finishes, or permission denied)
class LocationTimeLedger {
  LocationTimeLedger._();

  static const List<String> tiers = <String>[
    'track', 'paused', 'precise', 'idle', 'off',
  ];
  static final Map<String, Duration> _totals = <String, Duration>{
    for (final String t in tiers) t: Duration.zero,
  };
  static String _current = 'off';
  static DateTime _since = DateTime.now();

  /// Records a transition. Unknown tiers are folded into `idle` so a renamed
  /// mode string can never silently drop time.
  static void setTier(String tier) {
    _roll();
    _current = tiers.contains(tier) ? tier : 'idle';
  }

  /// Maps a [LocationService] stream-mode label to a tier.
  static String tierForMode(String mode) {
    if (mode.startsWith('PRECISE')) return 'precise';
    if (mode.startsWith('idle')) return 'idle';
    return 'idle';
  }

  static void _roll() {
    final DateTime now = DateTime.now();
    _totals[_current] = _totals[_current]! + now.difference(_since);
    _since = now;
  }

  /// `loc_track=48m loc_precise=3m loc_idle=2h01m` — tiers with no time are
  /// omitted except `idle`, so the line stays short on an ordinary day.
  static String summary() {
    _roll();
    final StringBuffer b = StringBuffer();
    for (final String t in tiers) {
      final Duration d = _totals[t]!;
      if (d == Duration.zero && t != 'idle') continue;
      if (b.isNotEmpty) b.write(' ');
      b.write('loc_$t=${formatDuration(d)}');
    }
    return b.toString();
  }

  static String formatDuration(Duration d) {
    final int h = d.inHours;
    final int m = d.inMinutes % 60;
    final int s = d.inSeconds % 60;
    if (h > 0) return '${h}h${m.toString().padLeft(2, '0')}m';
    if (m > 0) return '${m}m${s.toString().padLeft(2, '0')}s';
    return '${s}s';
  }
}
