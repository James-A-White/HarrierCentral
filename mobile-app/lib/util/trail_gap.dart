import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// What a [TrailGap]'s trail distance was measured along.
enum TrailGapBasis {
  /// The hare's official trail (E5.F6.S6).
  officialTrail,

  /// The viewer's own track: the other hasher is somewhere the viewer has
  /// already been, so the viewer is ahead.
  myTrack,

  /// The other hasher's track: the viewer is somewhere they have already
  /// been, so they are ahead.
  theirTrack,

  /// Neither is on the other's path — a shortcut, a check, another trail.
  /// Only the straight line is known.
  none,
}

/// How far apart two hashers are: as the crow flies, and along the trail.
class TrailGap {
  const TrailGap({
    required this.crowMeters,
    required this.basis,
    this.trailMeters,
    this.meAhead,
    this.segment = const <LatLng>[],
  });

  final double crowMeters;
  final TrailGapBasis basis;

  /// Distance along the trail; null when [basis] is [TrailGapBasis.none].
  final double? trailMeters;

  /// True when the viewer is the one further along; null with no trail
  /// distance.
  final bool? meAhead;

  /// The stretch of trail between the two, follower → leader; empty with no
  /// trail distance.
  final List<LatLng> segment;

  bool get onSameTrail => basis != TrailGapBasis.none;
}

/// Works out a [TrailGap] (E5.F4.S10, James 2026-10-11).
///
/// The straight line is easy; the trail is the point, and a hash trail is not
/// a line — checks, false trails, checkbacks and shortcuts all put track where
/// the trail is not. In order:
///
/// 1. **The official trail**, where the run has one: each hasher's progress
///    along it, and the difference. False trails are not on it, so they cost
///    nothing.
/// 2. **The leader's own track.** If one hasher's position lies on the
///    other's track, the one whose track it is has been there, and is ahead
///    by the length of their track from that spot to where they are now —
///    measured the SHORTEST way along it, with points within [joinMeters]
///    joined, so an out-and-back at a check or down a false trail drops out
///    rather than being counted twice.
/// 3. **Neither** — the straight line only. Never an invented number.
///
/// A trail that passes the same spot twice (an A-to-A, an out-and-back along
/// one road) gives one position several matches. The one kept is the match
/// whose distance along the path is nearest the matched hasher's own distance
/// run — at 1 km out you are at the 1 km match, not the 9 km one on the way
/// home. A join is only taken across [maxExcursionMeters] of track, so the
/// way home along the road you went out on is never mistaken for a check.
class TrailGapCalculator {
  /// A position this close to a track is ON it.
  static const double onTrackMeters = 25.0;

  /// The official trail is a hare's recording, a scout or an imported file,
  /// and a runner may be on the other side of the road: a looser tolerance.
  static const double onOfficialMeters = 40.0;

  /// Track points this close together are the same place on the trail.
  static const double joinMeters = 20.0;

  /// The longest out-and-back a join may cut out, in metres of track: a
  /// long false trail or check is ~300 m each way. Geometry cannot tell a
  /// false trail from a real dead-end turnaround of the same size — both are
  /// out and back over the same ground — so this is kept tight: a longer
  /// one, and the loop at the far end of a lollipop trail, is the trail
  /// itself and is counted.
  static const double maxExcursionMeters = 600.0;

  /// The SHORTEST track a join may cut out. Without it a join clips every
  /// corner (two points 10 m either side of a right angle are 14 m apart),
  /// shaving ~6 m a corner off a twisty trail. A check or false trail goes
  /// out and back over far more than this. Switchbacks on a hill still come
  /// back within [joinMeters] over more track than this and are cut — the
  /// one shape this cannot tell from a check.
  static const double minExcursionMeters = 60.0;

  static const double _earthRadius = 6371008.8;

  static final Distance _distance = const Distance();

  /// [me] and [them] are each hasher's track up to the moment shown, oldest
  /// first, the last point being where they are. [officialLanes] are the
  /// run's official trails, best first (the viewer's own trail type).
  static TrailGap compute({
    required List<LatLng> me,
    required List<LatLng> them,
    List<List<LatLng>> officialLanes = const <List<LatLng>>[],
  }) {
    if (me.isEmpty || them.isEmpty) {
      return const TrailGap(crowMeters: 0, basis: TrailGapBasis.none);
    }
    final LatLng myPos = me.last;
    final LatLng theirPos = them.last;
    final double crow = _distance.as(LengthUnit.Meter, myPos, theirPos);
    final _Projection proj = _Projection(myPos);

    final _Path myPath = _Path(proj, me);
    final _Path theirPath = _Path(proj, them);

    // 1. The official trail.
    for (final List<LatLng> lane in officialLanes) {
      if (lane.length < 2) continue;
      final _Path trail = _Path(proj, lane);
      final _Match? mine = _bestMatch(
        trail,
        proj.xy(myPos),
        onOfficialMeters,
        myPath.length,
      );
      final _Match? theirs = _bestMatch(
        trail,
        proj.xy(theirPos),
        onOfficialMeters,
        theirPath.length,
      );
      if (mine == null || theirs == null) continue;
      final bool meAhead = mine.s >= theirs.s;
      final _Match from = meAhead ? theirs : mine;
      final _Match to = meAhead ? mine : theirs;
      return TrailGap(
        crowMeters: crow,
        basis: TrailGapBasis.officialTrail,
        trailMeters: to.s - from.s,
        meAhead: meAhead,
        segment: _tied(
          meAhead ? theirPos : myPos,
          trail.between(from, to),
          meAhead ? myPos : theirPos,
        ),
      );
    }

    // 2. The leader's own track. Both can match where the two have crossed
    // each other's path; whoever has run further is then the leader.
    final _Match? onMine = _bestMatch(
      myPath,
      proj.xy(theirPos),
      onTrackMeters,
      theirPath.length,
    );
    final _Match? onTheirs = _bestMatch(
      theirPath,
      proj.xy(myPos),
      onTrackMeters,
      myPath.length,
    );
    final bool useMine =
        onMine != null &&
        (onTheirs == null || myPath.length >= theirPath.length);
    if (useMine) {
      final _Walk w = myPath.shortestFrom(onMine);
      return TrailGap(
        crowMeters: crow,
        basis: TrailGapBasis.myTrack,
        trailMeters: w.meters,
        meAhead: true,
        segment: _tied(
          theirPos,
          w.points.map(proj.latLng).toList(growable: false),
          myPos,
        ),
      );
    }
    if (onTheirs != null) {
      final _Walk w = theirPath.shortestFrom(onTheirs);
      return TrailGap(
        crowMeters: crow,
        basis: TrailGapBasis.theirTrack,
        trailMeters: w.meters,
        meAhead: false,
        // Follower → leader: from the viewer to the other hasher.
        segment: _tied(
          myPos,
          w.points.map(proj.latLng).toList(growable: false),
          theirPos,
        ),
      );
    }

    // 3. Neither.
    return TrailGap(crowMeters: crow, basis: TrailGapBasis.none);
  }

  /// [segment] with its ends joined to the two hashers' dots. A segment runs
  /// between where each hasher MEETS the path — up to [onOfficialMeters]
  /// from where they stand — so without these legs the line drawn between
  /// you stopped short of both dots (James, 2026-10-11). The legs are drawn,
  /// never measured: the trail distance is along the path only.
  static List<LatLng> _tied(LatLng start, List<LatLng> segment, LatLng end) =>
      <LatLng>[
        if (segment.isEmpty || segment.first != start) start,
        ...segment,
        if (segment.isEmpty || segment.last != end) end,
      ];

  /// The match of [p] on [path] (within [tol]) whose distance along the path
  /// is nearest [expectedS]; null when [p] is nowhere near it.
  static _Match? _bestMatch(_Path path, _Xy p, double tol, double expectedS) {
    final List<_Match> found = path.matches(p, tol);
    if (found.isEmpty) return null;
    _Match best = found.first;
    for (final _Match m in found.skip(1)) {
      if ((m.s - expectedS).abs() < (best.s - expectedS).abs()) best = m;
    }
    return best;
  }
}

/// Metres east / north of an origin. Equirectangular about the viewer: under
/// 0.1% error across the few kilometres a run covers, and it makes every
/// projection and distance below plain arithmetic.
class _Projection {
  _Projection(LatLng origin)
    : _lat0 = origin.latitude,
      _lng0 = origin.longitude,
      _kx =
          math.cos(origin.latitude * math.pi / 180) *
          TrailGapCalculator._earthRadius *
          math.pi /
          180,
      _ky = TrailGapCalculator._earthRadius * math.pi / 180;

  final double _lat0, _lng0, _kx, _ky;

  _Xy xy(LatLng p) =>
      _Xy((p.longitude - _lng0) * _kx, (p.latitude - _lat0) * _ky);

  LatLng latLng(_Xy p) => LatLng(_lat0 + p.y / _ky, _lng0 + p.x / _kx);
}

class _Xy {
  const _Xy(this.x, this.y);
  final double x, y;

  double dist(_Xy o) {
    final double dx = x - o.x, dy = y - o.y;
    return math.sqrt(dx * dx + dy * dy);
  }
}

/// A position on a path: segment [seg] (from point seg to seg + 1), [t] of
/// the way along it, [s] metres from the path's start.
class _Match {
  const _Match(this.seg, this.t, this.s, this.at);
  final int seg;
  final double t;
  final double s;
  final _Xy at;
}

class _Walk {
  const _Walk(this.meters, this.points);
  final double meters;
  final List<_Xy> points;
}

class _Path {
  _Path(this.proj, List<LatLng> points)
    : pts = points.map(proj.xy).toList(growable: false) {
    cum = List<double>.filled(pts.length, 0);
    for (int i = 1; i < pts.length; i++) {
      cum[i] = cum[i - 1] + pts[i - 1].dist(pts[i]);
    }
  }

  final _Projection proj;
  final List<_Xy> pts;
  late final List<double> cum;

  double get length => pts.isEmpty ? 0 : cum.last;

  /// Every place [p] comes within [tol] of the path — one per pass, each the
  /// nearest point of that pass. A lone point (a path of one) is a pass of
  /// its own.
  List<_Match> matches(_Xy p, double tol) {
    final List<_Match> out = <_Match>[];
    if (pts.length == 1) {
      if (pts.first.dist(p) <= tol) out.add(_Match(0, 0, 0, pts.first));
      return out;
    }
    _Match? cur;
    double curD = double.infinity;
    for (int i = 0; i < pts.length - 1; i++) {
      final _Xy a = pts[i], b = pts[i + 1];
      final double dx = b.x - a.x, dy = b.y - a.y;
      final double len2 = dx * dx + dy * dy;
      final double t = len2 == 0
          ? 0
          : (((p.x - a.x) * dx + (p.y - a.y) * dy) / len2).clamp(0.0, 1.0);
      final _Xy at = _Xy(a.x + dx * t, a.y + dy * t);
      final double d = at.dist(p);
      if (d <= tol) {
        if (cur == null || d < curD) {
          cur = _Match(i, t, cum[i] + (cum[i + 1] - cum[i]) * t, at);
          curD = d;
        }
      } else if (cur != null) {
        out.add(cur);
        cur = null;
        curD = double.infinity;
      }
    }
    if (cur != null) out.add(cur);
    return out;
  }

  /// The path from [from] to [to] ([from] no further along than [to]).
  List<LatLng> between(_Match from, _Match to) => <_Xy>[
    from.at,
    for (int i = from.seg + 1; i <= to.seg; i++) pts[i],
    to.at,
  ].map(proj.latLng).toList(growable: false);

  /// The shortest way along the path from [m] to its end, a join allowed
  /// between any two points within [TrailGapCalculator.joinMeters] that are
  /// between [TrailGapCalculator.minExcursionMeters] and
  /// [TrailGapCalculator.maxExcursionMeters] of path apart.
  ///
  /// Forward only: every revisit of a place is a later point near an earlier
  /// one, so a forward join is all a loop or an out-and-back needs. Nearby
  /// earlier points are found through a grid of join-sized cells.
  _Walk shortestFrom(_Match m) {
    // Nodes: the match point, then every path point after it.
    final List<_Xy> nodes = <_Xy>[m.at];
    final List<double> s = <double>[m.s];
    for (int i = m.seg + 1; i < pts.length; i++) {
      nodes.add(pts[i]);
      s.add(cum[i]);
    }
    final int n = nodes.length;
    final List<double> best = List<double>.filled(n, double.infinity);
    final List<int> from = List<int>.filled(n, -1);
    best[0] = 0;
    const double cell = TrailGapCalculator.joinMeters;
    final Map<int, List<int>> grid = <int, List<int>>{};
    int key(int cx, int cy) => cx * 1000003 + cy;

    for (int k = 0; k < n; k++) {
      if (k > 0) {
        best[k] = best[k - 1] + nodes[k - 1].dist(nodes[k]);
        from[k] = k - 1;
        final int cx = (nodes[k].x / cell).floor();
        final int cy = (nodes[k].y / cell).floor();
        for (int ox = -1; ox <= 1; ox++) {
          for (int oy = -1; oy <= 1; oy++) {
            final List<int>? cands = grid[key(cx + ox, cy + oy)];
            if (cands == null) continue;
            for (final int i in cands) {
              if (i >= k - 1) continue;
              final double span = s[k] - s[i];
              if (span > TrailGapCalculator.maxExcursionMeters ||
                  span < TrailGapCalculator.minExcursionMeters) {
                continue;
              }
              final double d = nodes[i].dist(nodes[k]);
              if (d > TrailGapCalculator.joinMeters) continue;
              final double via = best[i] + d;
              if (via < best[k]) {
                best[k] = via;
                from[k] = i;
              }
            }
          }
        }
      }
      grid
          .putIfAbsent(
            key((nodes[k].x / cell).floor(), (nodes[k].y / cell).floor()),
            () => <int>[],
          )
          .add(k);
    }

    final List<_Xy> route = <_Xy>[];
    for (int k = n - 1; k >= 0; k = from[k]) {
      route.add(nodes[k]);
      if (k == 0) break;
    }
    return _Walk(best[n - 1], route.reversed.toList(growable: false));
  }
}
