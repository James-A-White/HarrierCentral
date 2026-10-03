import 'dart:math' as math;

import 'package:harrier_central/imports.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlng;

/// One lane of a run's official (hare's) trail (E5.F6.S6, James
/// 2026-10-03): its trail type (1 Walkers, 2 Short, 3 Normal, 4 Long,
/// 5 Ballbreaker, >= 100 the kennel's own) and its points. [times], when
/// present, is ms after the lane's first point for each point; replay places
/// that first point at the first pack track's start ("auto-align"). A lane
/// without times (an untimed GPX, the Chichester imports) is drawn whole.
class OfficialTrailLane {
  const OfficialTrailLane({
    required this.type,
    required this.points,
    this.times,
    this.distanceM,
    this.source,
  });

  final int type;
  final List<latlng.LatLng> points;
  final List<int>? times;
  final int? distanceM;

  /// How it was set: 'scout', 'promote', 'file' or 'import'.
  final String? source;

  bool get timed => times != null && times!.length == points.length;

  /// The lane's length, ms, or 0 when untimed.
  int get durationMs => timed ? times!.last : 0;

  /// The position [elapsedMs] after the lane's first point (interpolated),
  /// or null before its start or for an untimed lane. After its end, the
  /// last point.
  latlng.LatLng? positionAt(int elapsedMs) {
    if (!timed || elapsedMs < 0) return null;
    final List<int> t = times!;
    if (elapsedMs >= t.last) return points.last;
    int lo = 0, hi = t.length - 1;
    while (hi - lo > 1) {
      final int mid = (lo + hi) >> 1;
      if (t[mid] <= elapsedMs) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final int span = t[hi] - t[lo];
    final double f = span <= 0 ? 0 : (elapsedMs - t[lo]) / span;
    final latlng.LatLng a = points[lo], b = points[hi];
    return latlng.LatLng(
      a.latitude + (b.latitude - a.latitude) * f,
      a.longitude + (b.longitude - a.longitude) * f,
    );
  }

  /// The points up to [elapsedMs] — the part of the trail "run so far".
  List<latlng.LatLng> pointsUpTo(int elapsedMs) {
    if (!timed) return points;
    final List<latlng.LatLng> out = <latlng.LatLng>[];
    for (int i = 0; i < points.length; i++) {
      if (times![i] > elapsedMs) break;
      out.add(points[i]);
    }
    final latlng.LatLng? here = positionAt(elapsedMs);
    if (here != null && out.isNotEmpty) out.add(here);
    return out;
  }

  /// The app's built-in trail-type colours, as on the website.
  static Color colorOf(int type) => switch (type) {
    1 => const Color(0xFF16A34A),
    2 => const Color(0xFFF59E0B),
    4 => const Color(0xFF7C3AED),
    5 => const Color(0xFF0F172A),
    _ => const Color(0xFFDC2626),
  };

  static String labelOf(int type) => switch (type) {
    1 => 'Walkers',
    2 => 'Short',
    3 => 'Normal',
    4 => 'Long',
    5 => 'Ballbreaker',
    _ => 'Trail',
  };

  /// Lanes from the trail JSON `{"lanes":[{"type":3,"points":[[lat,lon,t?],...]}]}`
  /// plus the info JSON's distances. Tolerant: a lane that will not parse is
  /// left out.
  static List<OfficialTrailLane> parseLanes(Object? trailJson, Object? infoJson) {
    Map<String, dynamic> trail = <String, dynamic>{};
    Map<String, dynamic> info = <String, dynamic>{};
    try {
      trail = jsonDecode('${trailJson ?? '{}'}') as Map<String, dynamic>;
    } catch (_) {}
    try {
      info = jsonDecode('${infoJson ?? '{}'}') as Map<String, dynamic>;
    } catch (_) {}
    final Map<int, int> distances = <int, int>{
      for (final dynamic l in (info['lanes'] as List<dynamic>? ?? <dynamic>[]))
        if (l is Map && l['type'] is num && l['distanceM'] is num)
          (l['type'] as num).toInt(): (l['distanceM'] as num).toInt(),
    };
    final Map<int, String> sources = <int, String>{
      for (final dynamic l in (info['lanes'] as List<dynamic>? ?? <dynamic>[]))
        if (l is Map && l['type'] is num && l['source'] is String)
          (l['type'] as num).toInt(): l['source'] as String,
    };
    final List<OfficialTrailLane> lanes = <OfficialTrailLane>[];
    for (final dynamic l in (trail['lanes'] as List<dynamic>? ?? <dynamic>[])) {
      if (l is! Map) continue;
      final int type = (l['type'] as num?)?.toInt() ?? 3;
      final List<latlng.LatLng> pts = <latlng.LatLng>[];
      final List<int> ts = <int>[];
      bool allTimed = true;
      for (final dynamic p in (l['points'] as List<dynamic>? ?? <dynamic>[])) {
        if (p is! List || p.length < 2 || p[0] is! num || p[1] is! num) continue;
        pts.add(latlng.LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()));
        if (p.length >= 3 && p[2] is num) {
          ts.add((p[2] as num).toInt());
        } else {
          allTimed = false;
        }
      }
      if (pts.length >= 2) {
        lanes.add(
          OfficialTrailLane(
            type: type,
            points: pts,
            times: allTimed && ts.length == pts.length ? ts : null,
            distanceM: distances[type],
            source: sources[type],
          ),
        );
      }
    }
    return lanes;
  }

  /// Metres along [pts].
  static double lengthOf(List<latlng.LatLng> pts) {
    const latlng.Distance d = latlng.Distance();
    double m = 0;
    for (int i = 1; i < pts.length; i++) {
      m += d.as(latlng.LengthUnit.Meter, pts[i - 1], pts[i]);
    }
    return m;
  }
}

/// A run's official trail as the app sees it.
class RunOfficialTrail {
  const RunOfficialTrail({
    required this.available,
    required this.canEdit,
    required this.lanes,
  });

  /// False when there is none, or it is not yet visible to this hasher.
  final bool available;

  /// The run's hares and kennel admins: may set or replace a lane.
  final bool canEdit;
  final List<OfficialTrailLane> lanes;

  static const RunOfficialTrail none = RunOfficialTrail(
    available: false,
    canEdit: false,
    lanes: <OfficialTrailLane>[],
  );
}

/// A run's official trail as the kennel trail map shows it.
class KennelRunTrail {
  const KennelRunTrail({
    required this.eventId,
    required this.eventNumber,
    required this.eventName,
    required this.lanes,
    this.startLocal,
  });

  final HcId eventId;
  final int eventNumber;
  final String eventName;
  final DateTime? startLocal;
  final List<OfficialTrailLane> lanes;

  /// The main lane's length (Normal if there is one), metres.
  int? get distanceM {
    if (lanes.isEmpty) return null;
    final OfficialTrailLane main = lanes.firstWhere(
      (OfficialTrailLane l) => l.type == 3,
      orElse: () => lanes.first,
    );
    return main.distanceM;
  }

  /// Rows of hcapp_getKennelOfficialTrails. A run whose trail will not
  /// parse is left out rather than failing the map.
  static KennelRunTrail? fromRow(Map<String, dynamic> j) {
    try {
      final List<OfficialTrailLane> lanes = OfficialTrailLane.parseLanes(
        j['OfficialTrail'],
        j['OfficialTrailInfo'],
      );
      if (lanes.isEmpty) return null;
      return KennelRunTrail(
        eventId: HcId('${j['EventId'] ?? ''}'),
        eventNumber: (j['EventNumber'] as num?)?.toInt() ?? 0,
        eventName: '${j['EventName'] ?? ''}',
        startLocal: DateTime.tryParse(
          '${j['EventStartLocal'] ?? ''}'.replaceAll(
            RegExp(r'[Zz]$|[+-]\d{2}:\d{2}$'),
            '',
          ),
        ),
        lanes: lanes,
      );
    } catch (_) {
      return null;
    }
  }
}

/// A file the server read: its points ([lat, lon] or [lat, lon, t]).
class ParsedTrackFile {
  const ParsedTrackFile({
    required this.name,
    required this.timed,
    required this.distanceM,
    required this.points,
  });
  final String name;
  final bool timed;
  final int distanceM;
  final List<List<num>> points;
}

class OfficialTrailService {
  const OfficialTrailService._();

  static ({String userId, String deviceId, String secret})? _creds() {
    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String secret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';
    if (userId.isEmpty || deviceId.isEmpty || secret.isEmpty) return null;
    return (userId: userId, deviceId: deviceId, secret: secret);
  }

  /// A run's official trail, if this hasher may see it now: always for its
  /// hares and kennel admins; for a LOST runner ([lost]) during the run;
  /// for everyone once it has ended. Null when the call failed.
  static Future<RunOfficialTrail?> fetchRunTrail(
    HcId eventId, {
    bool lost = false,
  }) async {
    final c = _creds();
    if (c == null) return null;
    final String result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'getOfficialTrail',
        'deviceId': c.deviceId,
        'accessToken': Utilities.generateToken(
          c.userId,
          'hcapp_getOfficialTrail',
          paramString: c.secret,
        ),
        'eventId': eventId,
        'lost': lost ? 1 : 0,
      }),
      errorCallback: (_) async => true,
    );
    if (result.startsWith(ERROR_PREFIX)) return null;
    try {
      final List<dynamic> outer = jsonDecode(result) as List<dynamic>;
      final Map<String, dynamic>? row = outer.isEmpty
          ? null
          : firstRow(outer[0] as List<dynamic>?);
      if (row == null) return RunOfficialTrail.none;
      final bool available = (row['Available'] as num?)?.toInt() == 1;
      return RunOfficialTrail(
        available: available,
        canEdit: (row['CanEdit'] as num?)?.toInt() == 1,
        lanes: available
            ? OfficialTrailLane.parseLanes(row['OfficialTrail'], row['OfficialTrailInfo'])
            : const <OfficialTrailLane>[],
      );
    } catch (e, s) {
      BootLogger.logError('[ERROR][TRAILS]', 'run trail unreadable: $e', s);
      return null;
    }
  }

  /// Sets (or, with no points, removes) one lane of the run's official
  /// trail. Returns null on success, or a message to show.
  static Future<String?> setLane(
    HcId eventId, {
    required int trailType,
    required List<List<num>>? points,
    int? distanceM,
    required String source,
    String? sourceRef,
  }) async {
    final c = _creds();
    if (c == null) return 'Please sign in again.';
    String? refusal;
    final String result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'setOfficialTrail',
        'deviceId': c.deviceId,
        'accessToken': Utilities.generateToken(
          c.userId,
          'hcapp_setOfficialTrail',
          paramString: c.secret,
        ),
        'eventId': eventId,
        'trailType': trailType,
        'points': points == null ? '' : jsonEncode(points),
        'distanceM': distanceM,
        'source': source,
        'sourceRef': sourceRef,
      }),
      errorCallback: (DbErrorModel e) async {
        refusal = e.errorUserMessage;
        return true;
      },
    );
    if (result.startsWith(ERROR_PREFIX)) {
      return refusal ?? "The trail couldn't be saved. Please try again.";
    }
    try {
      final List<dynamic> outer = jsonDecode(result) as List<dynamic>;
      final Map<String, dynamic>? env = outer.isEmpty
          ? null
          : firstRow(outer[0] as List<dynamic>?);
      return env != null && env['success'] == 1
          ? null
          : (refusal ?? "The trail couldn't be saved. Please try again.");
    } catch (_) {
      return "The trail couldn't be saved. Please try again.";
    }
  }

  /// A GPX / TCX / FIT file read by the server's own parsers (Strava,
  /// Garmin and Fitbit exports included). Nothing is stored. Throws a
  /// message string on failure.
  static Future<ParsedTrackFile> parseFile(String fileName, List<int> bytes) async {
    final c = _creds();
    if (c == null) throw 'Please sign in again.';
    final http.Response resp = await http
        .post(
          Uri.parse(PARSE_TRACK_FILE_URL),
          headers: const <String, String>{'content-type': 'application/json'},
          body: jsonEncode(<String, dynamic>{
            'deviceId': c.deviceId,
            'accessToken': Utilities.generateToken(
              c.userId,
              'hcapp_authorizeTrackFile',
              paramString: c.secret,
            ),
            'fileName': fileName,
            'fileBase64': base64Encode(bytes),
          }),
        )
        .timeout(const Duration(seconds: 60));
    if (resp.statusCode != 200) {
      throw "That file couldn't be read (${resp.statusCode}). Please try again.";
    }
    final Map<String, dynamic> j = jsonDecode(resp.body) as Map<String, dynamic>;
    if (j['success'] != true) {
      throw '${j['errorUserMessage'] ?? "That file has no track Harrier Central can read."}';
    }
    final List<List<num>> pts = <List<num>>[
      for (final dynamic p in (j['points'] as List<dynamic>? ?? <dynamic>[]))
        if (p is List) <num>[for (final dynamic v in p) if (v is num) v],
    ];
    return ParsedTrackFile(
      name: '${j['name'] ?? fileName}',
      timed: j['timed'] == true,
      distanceM: (j['distanceM'] as num?)?.toInt() ?? 0,
      points: pts,
    );
  }

  /// A recorded track (the scout's session, or a runner's PackTrack) as lane
  /// points: [lat, lon, t] with t = ms after the first point, thinned to one
  /// point per 5 m so a long trail stays small, and its length.
  static ({List<List<num>> points, int distanceM}) lanePointsFrom(
    List<TrackPoint> track,
  ) {
    final List<TrackPoint> plain = track
        .where((TrackPoint p) => p.type == null)
        .toList()
      ..sort((TrackPoint a, TrackPoint b) => a.timestampMs.compareTo(b.timestampMs));
    if (plain.length < 2) return (points: <List<num>>[], distanceM: 0);
    const latlng.Distance d = latlng.Distance();
    final int t0 = plain.first.timestampMs;
    final List<List<num>> out = <List<num>>[];
    latlng.LatLng? last;
    double meters = 0;
    for (int i = 0; i < plain.length; i++) {
      final TrackPoint p = plain[i];
      final latlng.LatLng here = latlng.LatLng(p.lat, p.lng);
      final bool isLast = i == plain.length - 1;
      if (last != null) {
        final double step = d.as(latlng.LengthUnit.Meter, last, here);
        if (step < 5 && !isLast) continue;
        meters += step;
      }
      out.add(<num>[
        (p.lat * 100000).round() / 100000,
        (p.lng * 100000).round() / 100000,
        math.max(0, p.timestampMs - t0),
      ]);
      last = here;
    }
    return (points: out, distanceM: meters.round());
  }

  /// Every official trail of the kennel's ended runs, newest first. Null when
  /// the call failed; an empty list is the ordinary answer for most kennels.
  static Future<List<KennelRunTrail>?> fetchKennelTrails(HcId kennelId) async {
    final c = _creds();
    if (c == null) return null;
    final String result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'getKennelOfficialTrails',
        'deviceId': c.deviceId,
        'accessToken': Utilities.generateToken(
          c.userId,
          'hcapp_getKennelOfficialTrails',
          paramString: c.secret,
        ),
        'kennelId': kennelId,
      }),
      errorCallback: (_) async => true,
    );
    if (result.startsWith(ERROR_PREFIX)) return null;
    try {
      final List<dynamic> outer = jsonDecode(result) as List<dynamic>;
      if (outer.isEmpty || outer[0] is! List) return <KennelRunTrail>[];
      return (outer[0] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(KennelRunTrail.fromRow)
          .whereType<KennelRunTrail>()
          .toList(growable: false);
    } catch (e, s) {
      BootLogger.logError('[ERROR][TRAILS]', 'kennel trails unreadable: $e', s);
      return null;
    }
  }
}
