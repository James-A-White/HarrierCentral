import 'dart:math' as math;

import 'package:harrier_central/imports.dart';
import 'package:latlong2/latlong.dart';

/// One of the hasher's own trails, ready to draw on the trails map.
class TrailOnMap {
  const TrailOnMap({
    required this.eventId,
    required this.eventName,
    required this.eventStartLocal,
    required this.kennelId,
    required this.kennelPinColor,
    required this.points,
    this.distanceMeters = 0,
    this.startMs,
    this.endMs,
  });

  final String eventId;
  final String eventName;
  final String eventStartLocal;
  final String kennelId;
  final int kennelPinColor;
  final List<LatLng> points;

  /// How far the trail actually is, measured once from the full archive.
  /// Not derived from [points] — those are simplified for drawing, and at a
  /// zoomed-out level they would under-report the distance badly.
  final double distanceMeters;

  /// First and last CAPTURE times, as synced onto the attendance row. Null
  /// on a trail whose archive carried no usable times.
  final int? startMs;
  final int? endMs;

  /// How long the trail took, or null when either end is missing. Negative
  /// or absurd spans are rejected rather than averaged in.
  Duration? get duration {
    final int? a = startMs;
    final int? b = endMs;
    if (a == null || b == null) return null;
    final int ms = b - a;
    if (ms <= 0 || ms > const Duration(hours: 24).inMilliseconds) return null;
    return Duration(milliseconds: ms);
  }
}

/// The local index over the hasher's own archived trails (E5.F7.S1).
///
/// The user sync lands each finished trail as `trackGzip` on the attendance
/// row. Drawing every trail in view would mean decoding every row, so this
/// keeps two local-only things per row, filled once and never synced: the
/// trail's bounding box (four REAL columns) and a Douglas-Peucker
/// simplification of about 150 points (JSON). The trails map is then one
/// bounding-box query and no decoding at all. A re-sync that replaces the
/// row wipes both; [ensureIndexed] fills them again on the next look.
///
/// Two levels of detail (James, 2026-09-12): the stored path is the overview.
/// From [detailFromZoom] up, the trails the box test selects are few, so
/// [trailsInBounds] decodes each one's archive instead and simplifies it to
/// about a screen pixel at that zoom ([toleranceDegForZoom]); the finer the
/// zoom, the more of the original points survive. Decoded paths are kept in
/// a small cache so panning at street level does not decode again.
class TrackIndex {
  TrackIndex._();

  /// Upper bound on points kept per simplified trail.
  static const int maxSimplifiedPoints = 150;

  /// From this zoom the overview path (about 150 points) is visibly angular
  /// on a long trail, and few enough trails are in view to decode each one.
  static const double detailFromZoom = 12;

  /// Simplification tolerance at detail zooms, in screen pixels. Under one
  /// pixel the extra points cannot be seen; the renderer drops them anyway.
  static const double detailTolerancePx = 0.7;

  /// Decoded full paths by attendance row, most recently used last.
  static final Map<String, List<LatLng>> _fullPaths = <String, List<LatLng>>{};
  static const int _fullPathCacheSize = 80;

  /// About five metres at the equator: the starting tolerance. Doubled until
  /// the trail fits [maxSimplifiedPoints].
  static const double _baseToleranceDeg = 0.00005;

  static bool _indexing = false;

  /// Index every own row that has a trail and is missing either its bounds
  /// or its measured distance — the second condition picks up trails indexed
  /// by an earlier build, before the distance was kept. Returns how many rows
  /// were indexed. Bounded per call so a first sync of a long
  /// history never blocks a map for long; called again on the next look.
  static Future<int> ensureIndexed({int limit = 100}) async {
    if (_indexing) return 0;
    _indexing = true;
    try {
      final h = tableModel.hasherEventMapTableHelper;
      final String table = EnumDataTables.hasherEventMap.commonTableName;
      final String userId = currentUserId;
      if (userId.isEmpty) return 0;
      final List<Map<String, dynamic>> rows = await database.rawQuery(
        '''
        SELECT ${h.colHemId} AS hemId, ${h.colTrackGzip} AS gz
          FROM $table
         WHERE ${h.colUserId} = ? AND ${h.colRemoved} = 0
           AND ${h.colTrackGzip} IS NOT NULL AND ${h.colTrackGzip} <> ''
           AND (${h.colTrackMinLat} IS NULL OR ${h.colTrackDistanceM} IS NULL)
         LIMIT ?
        ''',
        <Object?>[userId, limit],
      );
      int done = 0;
      for (final Map<String, dynamic> row in rows) {
        final String hemId = row['hemId'] as String;
        try {
          final List<LatLng> path = pathFromArchive(row['gz'] as String);
          if (path.isEmpty) {
            // Nothing to draw: mark it so it is not decoded again.
            await database.rawUpdate(
              'UPDATE $table SET ${h.colTrackMinLat} = 0, ${h.colTrackMinLng} = 0, '
              '${h.colTrackMaxLat} = 0, ${h.colTrackMaxLng} = 0, ${h.colTrackSimplified} = ?, '
              '${h.colTrackDistanceM} = 0 '
              'WHERE ${h.colHemId} = ?',
              <Object?>['[]', hemId],
            );
            continue;
          }
          double minLat = path.first.latitude, maxLat = minLat;
          double minLng = path.first.longitude, maxLng = minLng;
          for (final LatLng p in path) {
            if (p.latitude < minLat) minLat = p.latitude;
            if (p.latitude > maxLat) maxLat = p.latitude;
            if (p.longitude < minLng) minLng = p.longitude;
            if (p.longitude > maxLng) maxLng = p.longitude;
          }
          final List<LatLng> simplified = simplify(path, maxSimplifiedPoints);
          await database.rawUpdate(
            'UPDATE $table SET ${h.colTrackMinLat} = ?, ${h.colTrackMinLng} = ?, '
            '${h.colTrackMaxLat} = ?, ${h.colTrackMaxLng} = ?, ${h.colTrackSimplified} = ? '
            'WHERE ${h.colHemId} = ?',
            <Object?>[
              minLat,
              minLng,
              maxLat,
              maxLng,
              encodePath(simplified),
              hemId,
            ],
          );
          done++;
        } on TrackArchiveVersionException catch (e) {
          // A newer archive than this app reads: leave it unindexed and say so
          // once; the server still serves the run's replay.
          BootLogger.logBreadcrumb('TrackIndex: $hemId skipped ($e)');
        } catch (e, s) {
          BootLogger.logError('[TrackIndex.ensureIndexed] $hemId', e, s);
        }
      }
      return done;
    } finally {
      _indexing = false;
    }
  }

  /// The hasher's trails whose bounding box touches [bounds], with the run
  /// and the kennel's pin colour, newest first.
  ///
  /// With [detailToleranceDeg] null each trail is its stored overview path.
  /// Given a tolerance (see [toleranceDegForZoom]) each trail is decoded from
  /// its archive and simplified to that tolerance instead, so a zoomed-in
  /// map draws the trail as it was run. The box test is the same either way.
  static Future<List<TrailOnMap>> trailsInBounds(
    LatLngBounds bounds, {
    double? detailToleranceDeg,
    int limit = 300,
  }) async {
    final h = tableModel.hasherEventMapTableHelper;
    final e = tableModel.eventsTableHelper;
    final k = tableModel.kennelsTableHelper;
    final String userId = currentUserId;
    if (userId.isEmpty) return const <TrailOnMap>[];
    final bool detail = detailToleranceDeg != null;
    final List<Map<String, dynamic>> rows = await database.rawQuery(
      '''
      SELECT hem.${h.colHemId} AS hemId,
             hem.${h.colEventId} AS eventId,
             evt.${e.colEventName} AS eventName,
             evt.${e.colEventStartDatetime} AS eventStart,
             evt.${e.colKennelId} AS kennelId,
             COALESCE(k.${k.colKennelPinColor}, 0) AS pinColor,
             hem.${h.colTrackDistanceM} AS distanceM,
             hem.${h.colTrackFirstPointAt} AS firstAt,
             hem.${h.colTrackLastPointAt} AS lastAt,
             ${detail ? 'hem.${h.colTrackGzip} AS gz' : 'hem.${h.colTrackSimplified} AS path'}
        FROM ${EnumDataTables.hasherEventMap.commonTableName} hem
        JOIN ${EnumDataTables.events.commonTableName} evt
          ON evt.${e.colEventId} = hem.${h.colEventId}
        LEFT JOIN ${EnumDataTables.kennels.commonTableName} k
          ON k.${k.colKennelId} = evt.${e.colKennelId}
       WHERE hem.${h.colUserId} = ? AND hem.${h.colRemoved} = 0
         AND hem.${h.colTrackSimplified} IS NOT NULL
         AND hem.${h.colTrackMinLat} <= ? AND hem.${h.colTrackMaxLat} >= ?
         AND hem.${h.colTrackMinLng} <= ? AND hem.${h.colTrackMaxLng} >= ?
       ORDER BY evt.${e.colEventStartDatetime} DESC
       LIMIT ?
      ''',
      <Object?>[
        userId,
        bounds.north,
        bounds.south,
        bounds.east,
        bounds.west,
        limit,
      ],
    );
    final List<TrailOnMap> out = <TrailOnMap>[];
    for (final Map<String, dynamic> r in rows) {
      final List<LatLng> pts;
      if (detail) {
        final List<LatLng> full = _fullPath(
          r['hemId'] as String,
          r['gz'] as String?,
        );
        pts = simplifyTo(full, detailToleranceDeg);
      } else {
        pts = decodePath(r['path'] as String? ?? '[]');
      }
      if (pts.length < 2) continue;
      out.add(
        TrailOnMap(
          eventId: normalizeUuid(r['eventId'] as String),
          eventName: (r['eventName'] as String?) ?? '',
          eventStartLocal: (r['eventStart'] as String?) ?? '',
          kennelId: normalizeUuid((r['kennelId'] as String?) ?? ''),
          kennelPinColor: (r['pinColor'] as num?)?.toInt() ?? 0,
          points: pts,
          distanceMeters: (r['distanceM'] as num?)?.toDouble() ?? 0,
          startMs: sqlUtcMs(r['firstAt']),
          endMs: sqlUtcMs(r['lastAt']),
        ),
      );
    }
    return out;
  }

  // ── Full paths ──────────────────────────────────────────────────────────

  /// The drawable path in an archive blob: every point up to the On-Inn,
  /// in order. Empty when the blob has nothing to draw.
  static List<LatLng> pathFromArchive(String base64Gzip) {
    final List<ArchivedTrackPoint> pts = TrackArchiveCodec.decodeBase64(
      base64Gzip,
    );
    return pts
        .where((ArchivedTrackPoint p) => p.type == null || !_isOnInn(p.type!))
        .map((ArchivedTrackPoint p) => LatLng(p.lat, p.lng))
        .toList(growable: false);
  }

  /// The full path for an attendance row, decoded once and kept. Keyed by
  /// row and blob length so a re-archived trail is not served stale.
  static List<LatLng> _fullPath(String hemId, String? gz) {
    if (gz == null || gz.isEmpty) return const <LatLng>[];
    final String key = '$hemId:${gz.length}';
    final List<LatLng>? hit = _fullPaths.remove(key);
    if (hit != null) {
      _fullPaths[key] = hit; // most recently used last
      return hit;
    }
    List<LatLng> path;
    try {
      path = pathFromArchive(gz);
    } catch (e, s) {
      BootLogger.logError('[TrackIndex._fullPath] $hemId', e, s);
      path = const <LatLng>[];
    }
    _fullPaths[key] = path;
    while (_fullPaths.length > _fullPathCacheSize) {
      _fullPaths.remove(_fullPaths.keys.first);
    }
    return path;
  }

  /// Forget every decoded path (a sync replaced rows, or memory pressure).
  static void clearCache() => _fullPaths.clear();

  /// The simplification tolerance, in degrees of latitude, that equals
  /// [detailTolerancePx] screen pixels at [zoom] and latitude [latDeg] on a
  /// Web Mercator map with 256-pixel tiles. Null below [detailFromZoom]:
  /// the overview path is enough there.
  static double? toleranceDegForZoom(double zoom, double latDeg) {
    if (zoom < detailFromZoom) return null;
    final double metresPerPx =
        156543.03392 * math.cos(latDeg * math.pi / 180) / math.pow(2, zoom);
    return detailTolerancePx * metresPerPx / 111320;
  }

  /// A SQL datetime2 as written by the sync ("2026-09-12 07:23:19.992"),
  /// read as UTC. DATETIME2 carries no zone, and every capture time is
  /// stored on the UTC clock, so a missing suffix means UTC and not local.
  static int? sqlUtcMs(dynamic v) {
    if (v == null) return null;
    String t = '$v'.trim();
    if (t.isEmpty) return null;
    // Dart rejects more than six fractional digits; SQL can write seven.
    final int dot = t.indexOf('.');
    if (dot >= 0 && t.length - dot - 1 > 6) t = t.substring(0, dot + 7);
    if (!t.endsWith('Z') && !t.contains('+')) t = '${t}Z';
    return DateTime.tryParse(t)?.millisecondsSinceEpoch;
  }

  /// The length of a path in metres, by the haversine formula over every
  /// consecutive pair. Measured on the FULL path at index time and stored, so
  /// the number is the trail's own and not an artefact of the drawn detail.
  static double pathLengthMeters(List<LatLng> path) {
    if (path.length < 2) return 0;
    const double earthRadiusM = 6371008.8;
    double total = 0;
    for (int i = 1; i < path.length; i++) {
      final LatLng a = path[i - 1];
      final LatLng b = path[i];
      final double lat1 = a.latitude * math.pi / 180;
      final double lat2 = b.latitude * math.pi / 180;
      final double dLat = lat2 - lat1;
      final double dLng = (b.longitude - a.longitude) * math.pi / 180;
      final double h =
          math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(lat1) *
              math.cos(lat2) *
              math.sin(dLng / 2) *
              math.sin(dLng / 2);
      total += 2 * earthRadiusM * math.asin(math.min(1, math.sqrt(h)));
    }
    return total;
  }

  // ── Simplification ──────────────────────────────────────────────────────

  /// Douglas-Peucker, tolerance doubled until the result has at most
  /// [maxPoints]. Pure lat/lng degrees: at trail scale the distortion is
  /// irrelevant and it keeps the maths trivial.
  static List<LatLng> simplify(List<LatLng> path, int maxPoints) {
    if (path.length <= maxPoints) return path;
    double tol = _baseToleranceDeg;
    List<LatLng> out = path;
    for (int i = 0; i < 16 && out.length > maxPoints; i++) {
      out = _douglasPeucker(path, tol);
      tol *= 2;
    }
    if (out.length > maxPoints) {
      // Pathological (a dense straight line still over budget): thin evenly.
      final double step = (out.length - 1) / (maxPoints - 1);
      out = List<LatLng>.generate(
        maxPoints,
        (int i) => out[(i * step).round()],
      );
    }
    return out;
  }

  /// Douglas-Peucker at a fixed [toleranceDeg] — the detail tier, where the
  /// point budget is whatever the zoom can show.
  static List<LatLng> simplifyTo(List<LatLng> path, double toleranceDeg) =>
      path.length < 3 ? path : _douglasPeucker(path, toleranceDeg);

  static List<LatLng> _douglasPeucker(List<LatLng> pts, double tolerance) {
    if (pts.length < 3) return pts;
    final List<bool> keep = List<bool>.filled(pts.length, false);
    keep[0] = true;
    keep[pts.length - 1] = true;
    final List<List<int>> stack = <List<int>>[
      <int>[0, pts.length - 1],
    ];
    while (stack.isNotEmpty) {
      final List<int> seg = stack.removeLast();
      final int a = seg[0], b = seg[1];
      if (b - a < 2) continue;
      double maxD = -1;
      int idx = -1;
      for (int i = a + 1; i < b; i++) {
        final double d = _pointToSegment(pts[i], pts[a], pts[b]);
        if (d > maxD) {
          maxD = d;
          idx = i;
        }
      }
      if (maxD > tolerance && idx > 0) {
        keep[idx] = true;
        stack.add(<int>[a, idx]);
        stack.add(<int>[idx, b]);
      }
    }
    final List<LatLng> out = <LatLng>[];
    for (int i = 0; i < pts.length; i++) {
      if (keep[i]) out.add(pts[i]);
    }
    return out;
  }

  static double _pointToSegment(LatLng p, LatLng a, LatLng b) {
    final double x = p.longitude, y = p.latitude;
    final double x1 = a.longitude, y1 = a.latitude;
    final double x2 = b.longitude, y2 = b.latitude;
    final double dx = x2 - x1, dy = y2 - y1;
    if (dx == 0 && dy == 0) {
      return math.sqrt((x - x1) * (x - x1) + (y - y1) * (y - y1));
    }
    double t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy);
    t = t.clamp(0.0, 1.0);
    final double px = x1 + t * dx, py = y1 + t * dy;
    return math.sqrt((x - px) * (x - px) + (y - py) * (y - py));
  }

  // ── Storage form ────────────────────────────────────────────────────────

  static String encodePath(List<LatLng> pts) => jsonEncode(
    pts
        .map(
          (LatLng p) => <double>[
            double.parse(p.latitude.toStringAsFixed(5)),
            double.parse(p.longitude.toStringAsFixed(5)),
          ],
        )
        .toList(growable: false),
  );

  static List<LatLng> decodePath(String json) {
    try {
      final List<dynamic> raw = jsonDecode(json) as List<dynamic>;
      return raw
          .map(
            (dynamic p) =>
                LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()),
          )
          .toList(growable: false);
    } catch (_) {
      return const <LatLng>[];
    }
  }

  /// The legacy OIN key or any new-style mark whose action is endRun —
  /// mirrors the map's terminator test, so a trail ends where the run did.
  static bool _isOnInn(String type) {
    final List<String> parts = type.split('::');
    if (parts.first.trim() == 'OIN') return true;
    return parts.any((String p) => p.trim() == 'A=endRun');
  }
}
