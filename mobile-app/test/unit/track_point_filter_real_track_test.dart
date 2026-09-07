import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/data/models/user_positions/user_positions.dart';
import 'package:harrier_central/util/track_point_filter.dart';

/// Opee's real GPS track from the GNH 2026 Sunday Hangover trail, 350 points
/// straight out of Azure Table Storage. Kept as a fixture because the
/// interesting failures — a photo mark planted 47m away at 25 m/s, a 4,298 m/s
/// teleport, and several minutes of standing still at the finish — are all
/// things nobody would think to write by hand.
List<TrackPoint> _loadOpee() {
  final File f = File('test/fixtures/opee_sunday.json');
  final List<dynamic> raw = jsonDecode(f.readAsStringSync()) as List<dynamic>;
  return raw
      .cast<Map<String, dynamic>>()
      .map(
        (Map<String, dynamic> m) => TrackPoint(
          lat: (m['lat'] as num).toDouble(),
          lng: (m['lng'] as num).toDouble(),
          acc: (m['acc'] as num).toDouble(),
          alt: (m['alt'] as num?)?.toDouble(),
          timestampMs: (m['timestampMs'] as num).toInt(),
          type: m['type'] as String?,
        ),
      )
      .toList();
}

double _metres(TrackPoint a, TrackPoint b) {
  const double r = 6371000.0;
  final double p1 = a.lat * math.pi / 180.0;
  final double p2 = b.lat * math.pi / 180.0;
  final double dp = p2 - p1;
  final double dl = (b.lng - a.lng) * math.pi / 180.0;
  final double h =
      math.sin(dp / 2) * math.sin(dp / 2) +
      math.cos(p1) * math.cos(p2) * math.sin(dl / 2) * math.sin(dl / 2);
  return 2 * r * math.asin(math.sqrt(h));
}

/// Track length over ordinary GPS fixes only — marks are not places the runner
/// went, so they never belong in a distance.
double _length(List<TrackPoint> pts) {
  final List<TrackPoint> gps = pts
      .where((TrackPoint p) => p.type == null || p.type!.isEmpty)
      .toList();
  double d = 0;
  for (int i = 0; i < gps.length - 1; i++) {
    d += _metres(gps[i], gps[i + 1]);
  }
  return d;
}

/// Fastest step anywhere in the track. A run cannot exceed a few m/s, so this
/// is the single number that says whether a teleport survived.
double _peakSpeed(List<TrackPoint> pts) {
  final List<TrackPoint> gps = pts
      .where((TrackPoint p) => p.type == null || p.type!.isEmpty)
      .toList();
  double worst = 0;
  for (int i = 0; i < gps.length - 1; i++) {
    final double dt =
        (gps[i + 1].timestampMs - gps[i].timestampMs) / 1000.0;
    if (dt <= 0) continue;
    final double v = _metres(gps[i], gps[i + 1]) / dt;
    if (v > worst) worst = v;
  }
  return worst;
}

void main() {
  test('Opee\'s Sunday track: the filter removes the teleport', () {
    final List<TrackPoint> raw = _loadOpee();
    final List<TrackPoint> out = TrackPointFilter().filterAndInterpolate(raw);

    // ignore: avoid_print
    print(
      'raw:      ${raw.length} pts, ${(_length(raw) / 1000).toStringAsFixed(3)} km, '
      'peak ${_peakSpeed(raw).toStringAsFixed(0)} m/s',
    );
    // ignore: avoid_print
    print(
      'filtered: ${out.length} pts, ${(_length(out) / 1000).toStringAsFixed(3)} km, '
      'peak ${_peakSpeed(out).toStringAsFixed(0)} m/s',
    );

    // 4,298 m/s is Mach 12. Whatever else the filter does, that must not survive.
    expect(
      _peakSpeed(out),
      lessThan(10.0),
      reason: 'a teleport survived the filter',
    );
  });

  test('marks are preserved and never moved', () {
    final List<TrackPoint> raw = _loadOpee();
    final List<TrackPoint> out = TrackPointFilter().filterAndInterpolate(raw);

    final List<TrackPoint> rawMarks = raw
        .where((TrackPoint p) => p.type != null && p.type!.isNotEmpty)
        .toList();
    final List<TrackPoint> outMarks = out
        .where((TrackPoint p) => p.type != null && p.type!.isNotEmpty)
        .toList();

    expect(
      outMarks.length,
      rawMarks.length,
      reason: 'a mark was dropped — CHK/PHO/OIN must all survive filtering',
    );
    for (final TrackPoint m in rawMarks) {
      final TrackPoint same = outMarks.firstWhere(
        (TrackPoint o) => o.timestampMs == m.timestampMs && o.type == m.type,
        orElse: () => m,
      );
      expect(
        _metres(m, same),
        lessThan(0.5),
        reason: 'a mark moved: ${m.type}',
      );
    }
  });

  test('standing still stops adding distance', () {
    final List<TrackPoint> raw = _loadOpee();
    final List<TrackPoint> out = TrackPointFilter().filterAndInterpolate(raw);

    // The collapse can only ever shorten a track: it replaces wander with a
    // held position. If this ever grows, the pass is inventing movement.
    expect(_length(out), lessThanOrEqualTo(_length(raw) + 1.0));
  });

  _packTests();
}

/// Every ordinary GPS track recorded on the GNH 2026 Sunday Hangover trail, as
/// returned by GetPositions. Fifteen people walking the same ground is the only
/// honest way to tell a filter change that cleans noise from one that quietly
/// eats real distance.
List<({String id, List<TrackPoint> points})> _loadSundayPack() {
  final Map<String, dynamic> raw =
      jsonDecode(File('test/fixtures/gnh_sunday_pack.json').readAsStringSync())
          as Map<String, dynamic>;
  return (raw['users'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map(
        (Map<String, dynamic> u) => (
          id: u['id'] as String,
          points: (u['positions'] as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map(
                (Map<String, dynamic> m) => TrackPoint(
                  lat: (m['lat'] as num).toDouble(),
                  lng: (m['lng'] as num).toDouble(),
                  acc: (m['acc'] as num).toDouble(),
                  alt: (m['alt'] as num?)?.toDouble(),
                  timestampMs: (m['timestampMs'] as num).toInt(),
                  type: m['type'] as String?,
                ),
              )
              .toList(),
        ),
      )
      .toList();
}

/// Counts places where the track leaves the line between its neighbours and
/// comes straight back — the shape of a spike, and of a stall the collapse
/// failed to recognise.
int _spikes(List<TrackPoint> pts, double thresholdMetres) {
  final List<TrackPoint> gps = pts
      .where((TrackPoint p) => p.type == null || p.type!.isEmpty)
      .toList();
  int n = 0;
  for (int i = 1; i < gps.length - 1; i++) {
    final double detour = _metres(gps[i - 1], gps[i]) +
        _metres(gps[i], gps[i + 1]) -
        _metres(gps[i - 1], gps[i + 1]);
    if (detour > thresholdMetres) n++;
  }
  return n;
}

void _packTests() {
  test('a stall on poor GPS is recognised as standing still', () {
    // f58ca3ae stood at a check for twenty minutes on fixes accurate to
    // 60-116m. The readings ping-ponged between two spots 37m apart — inside
    // their own error, but outside the old flat 25m radius, so the pause was
    // never collapsed and half a kilometre of standing still was counted as
    // running. The raw track has NO spike at all before filtering: this is a
    // regression the filter used to introduce, not noise it failed to remove.
    final track = _loadSundayPack().firstWhere(
      (t) => t.id.startsWith('f58ca3ae'),
    );
    final List<TrackPoint> out = TrackPointFilter().filterAndInterpolate(
      track.points,
    );

    expect(
      _spikes(out, 100.0),
      0,
      reason: 'filtering introduced an out-and-back that was not in the raw track',
    );
    expect(
      _length(out),
      lessThan(_length(track.points) - 400),
      reason: 'the twenty-minute stall is still being counted as distance',
    );
  });

  test('clean tracks are left alone', () {
    // The safety property that makes the accuracy-widened radius shippable:
    // on good GPS it must change nothing. These five walked the same ~1.8km
    // trail on 4-10m fixes; widening the radius from 25m to 90m moved not one
    // of their measured lengths.
    const List<String> cleanPrefixes = <String>[
      '0cdbb109',
      '395a59fe',
      'b51eed92',
      'd0b7ef01',
      'ff2b511a',
    ];
    for (final t in _loadSundayPack()) {
      if (!cleanPrefixes.any(t.id.startsWith)) continue;
      final double before = _length(t.points);
      final double after = _length(
        TrackPointFilter().filterAndInterpolate(t.points),
      );
      expect(
        after,
        greaterThan(before * 0.9),
        reason: '${t.id}: a clean track lost more than 10% of its distance',
      );
      expect(_spikes(TrackPointFilter().filterAndInterpolate(t.points), 100.0), 0);
    }
  });

  test('the pack agrees on how long the trail was', () {
    // Fifteen people, one trail. After filtering, no track may measure longer
    // than 2.5km: the raw data has one at 6.41km, made entirely of jitter.
    for (final t in _loadSundayPack()) {
      final double km =
          _length(TrackPointFilter().filterAndInterpolate(t.points)) / 1000;
      expect(km, lessThan(2.5), reason: '${t.id} measured ${km.toStringAsFixed(2)}km');
    }
  });
}
