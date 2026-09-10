import 'package:harrier_central/imports.dart';
import 'package:harrier_central/services/location_service/run_point_buffer.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:xml/xml.dart';

/// Why a GPX file could not be imported. The message is written for the
/// user and shown as-is.
class GpxImportException implements Exception {
  const GpxImportException(this.message);
  final String message;
  @override
  String toString() => message;
}

class GpxTrackPoint {
  const GpxTrackPoint({
    required this.timestampMs,
    required this.lat,
    required this.lng,
    this.ele,
    this.hdop,
    this.accuracy,
  });
  final int timestampMs;
  final double lat;
  final double lng;
  final double? ele;
  final double? hdop;

  /// Our own export writes the fix accuracy as a track-point extension, so a
  /// Harrier Central file round-trips its real accuracies.
  final double? accuracy;
}

class GpxWaypoint {
  const GpxWaypoint({
    required this.timestampMs,
    required this.lat,
    required this.lng,
    this.ele,
    this.name,
    this.typeLabel,
  });
  final int timestampMs;
  final double lat;
  final double lng;
  final double? ele;
  final String? name;
  final String? typeLabel;
}

class ParsedGpx {
  const ParsedGpx({required this.points, required this.waypoints});
  final List<GpxTrackPoint> points; // ascending by time
  final List<GpxWaypoint> waypoints;
  int get firstTimestampMs => points.first.timestampMs;
  int get lastTimestampMs => points.last.timestampMs;
}

/// A run the server thinks the track might belong to (hcapp_findRunForTrack).
class RunCandidate {
  const RunCandidate({
    required this.eventId,
    required this.eventName,
    required this.kennelName,
    required this.kennelId,
    required this.startGmt,
    required this.startLocal,
    required this.hasLocation,
    required this.distanceMeters,
    required this.existingTrackPoints,
    required this.attendenceState,
  });

  factory RunCandidate.fromJson(Map<String, dynamic> j) => RunCandidate(
    eventId: normalizeUuid(j['eventId'] as String),
    eventName: (j['eventName'] as String?) ?? 'Run',
    kennelName: (j['kennelName'] as String?) ?? '',
    kennelId: normalizeUuid(j['kennelId'] as String),
    startGmt: DateTime.parse(j['eventStartGmt'] as String).toUtc(),
    startLocal: DateTime.tryParse((j['eventStartLocal'] as String?) ?? ''),
    hasLocation: (j['hasLocation'] as num?)?.toInt() == 1,
    distanceMeters: (j['distanceMeters'] as num?)?.toInt(),
    existingTrackPoints: (j['existingTrackPoints'] as num?)?.toInt() ?? 0,
    attendenceState: (j['attendenceState'] as num?)?.toInt() ?? 0,
  );

  final String eventId;
  final String eventName;
  final String kennelName;
  final String kennelId;
  final DateTime startGmt;
  final DateTime? startLocal;
  final bool hasLocation;
  final int? distanceMeters;
  final int existingTrackPoints;
  final int attendenceState;

  /// The rule: a run with a recorded start must be within a mile of the
  /// track's first point; a run with none is accepted on time alone (the
  /// user confirms the named run).
  bool get passesDistance =>
      !hasLocation ||
      (distanceMeters != null &&
          distanceMeters! <= GpxImportService.oneMileMeters);

  bool get hasExistingTrack => existingTrackPoints > 0;
}

/// Imports a GPX file as the user's own PackTrack trail for a run
/// (E5.F5.S6). The run is found server-side from the first point's time and
/// position; the points go through StorePositions exactly as a phone's do,
/// so replay, the nightly archive and the run-card count need nothing new.
class GpxImportService {
  const GpxImportService();

  static const int oneMileMeters = 1609;

  /// Thinning: a watch exports a point a second; the app tracks at ~5 m.
  /// Keep a point when it is this far from the last kept one, or this long
  /// after it, so a standstill still shows time passing.
  static const double thinDistanceMeters = 5.0;
  static const int thinIntervalMs = 15000;

  /// GPX carries no fix accuracy. hdop × 5 m is the usual rule of thumb;
  /// without hdop, 8 m keeps the point inside the noise filter's 15 m gate.
  static const double defaultAccuracyMeters = 8.0;
  static const double minAccuracyMeters = 3.0;
  static const double maxAccuracyMeters = 30.0;

  static const int maxPoints = 20000;
  static const int uploadChunk = 500;

  static const String _onInnKey = 'OIN';
  static const String _photoKey = 'PHO';

  // ── Parse ─────────────────────────────────────────────────────────────────

  ParsedGpx parse(String xml) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(xml);
    } catch (_) {
      throw const GpxImportException('That file is not a readable GPX file.');
    }
    if (doc.findAllElements('gpx').isEmpty) {
      throw const GpxImportException('That file is not a GPX file.');
    }

    final points = <GpxTrackPoint>[];
    int untimed = 0;
    for (final XmlElement el in doc.findAllElements('trkpt')) {
      final double? lat = double.tryParse(el.getAttribute('lat') ?? '');
      final double? lon = double.tryParse(el.getAttribute('lon') ?? '');
      if (lat == null || lon == null) continue;
      final int? ts = _parseTime(_childText(el, 'time'));
      if (ts == null) {
        untimed++;
        continue;
      }
      points.add(
        GpxTrackPoint(
          timestampMs: ts,
          lat: lat,
          lng: lon,
          ele: double.tryParse(_childText(el, 'ele') ?? ''),
          hdop: double.tryParse(_childText(el, 'hdop') ?? ''),
          accuracy: double.tryParse(_childText(el, 'Accuracy') ?? ''),
        ),
      );
    }
    if (points.isEmpty) {
      throw GpxImportException(
        untimed > 0
            ? 'This file has no timestamps on its track points, so it cannot '
                  'be matched to a run. Export it again with times included.'
            : 'This file has no track points.',
      );
    }
    if (points.length > maxPoints) {
      throw GpxImportException(
        'This file has ${points.length} points, more than the $maxPoints '
        'the import accepts.',
      );
    }
    points.sort((a, b) => a.timestampMs.compareTo(b.timestampMs));

    final waypoints = <GpxWaypoint>[];
    for (final XmlElement el in doc.findAllElements('wpt')) {
      final double? lat = double.tryParse(el.getAttribute('lat') ?? '');
      final double? lon = double.tryParse(el.getAttribute('lon') ?? '');
      final int? ts = _parseTime(_childText(el, 'time'));
      if (lat == null || lon == null || ts == null) continue;
      waypoints.add(
        GpxWaypoint(
          timestampMs: ts,
          lat: lat,
          lng: lon,
          ele: double.tryParse(_childText(el, 'ele') ?? ''),
          name: _childText(el, 'name'),
          typeLabel: _childText(el, 'type'),
        ),
      );
    }
    return ParsedGpx(points: points, waypoints: waypoints);
  }

  static String? _childText(XmlElement el, String localName) {
    for (final XmlElement c in el.descendantElements) {
      if (c.name.local == localName) {
        final String t = c.innerText.trim();
        return t.isEmpty ? null : t;
      }
    }
    return null;
  }

  /// GPX times are UTC per the spec, but some exports omit the zone. A time
  /// with no zone is read as UTC, not as this phone's local time — the phone
  /// importing may well be in a different zone from the run.
  static int? _parseTime(String? raw) {
    if (raw == null) return null;
    String s = raw.trim();
    final bool zoned =
        s.endsWith('Z') || RegExp(r'[+-]\d\d:?\d\d$').hasMatch(s);
    if (!zoned) s = '${s}Z';
    final DateTime? dt = DateTime.tryParse(s);
    return dt?.toUtc().millisecondsSinceEpoch;
  }

  // ── Build the upload ──────────────────────────────────────────────────────

  /// The points StorePositions will receive: the track thinned to the app's
  /// own cadence, our own waypoints turned back into marks, and an On Inn at
  /// the end so distance and replay treat it like a phone track.
  List<UserEventLocation> buildPoints(ParsedGpx gpx) {
    const latlng.Distance distance = latlng.Distance();
    final List<UserEventLocation> out = [];

    GpxTrackPoint? lastKept;
    for (int i = 0; i < gpx.points.length; i++) {
      final GpxTrackPoint p = gpx.points[i];
      final bool isLast = i == gpx.points.length - 1;
      if (lastKept != null && !isLast) {
        final double metres = distance.as(
          latlng.LengthUnit.Meter,
          latlng.LatLng(lastKept.lat, lastKept.lng),
          latlng.LatLng(p.lat, p.lng),
        );
        final int elapsed = p.timestampMs - lastKept.timestampMs;
        if (metres < thinDistanceMeters && elapsed < thinIntervalMs) continue;
      }
      out.add(_toLocation(p));
      lastKept = p;
    }

    // Our export writes each mark as a `<wpt>` whose `<type>` is the mark's
    // label and whose `<name>` is the label or the custom text. Anything whose
    // type is not one of ours is somebody else's waypoint and is left out.
    bool hasOnInn = false;
    for (final GpxWaypoint w in gpx.waypoints) {
      final String? typeString = _markTypeFor(w);
      if (typeString == null) continue;
      if (typeString.startsWith(_onInnKey)) hasOnInn = true;
      out.add(
        UserEventLocation(
          ts: pad19(w.timestampMs),
          lat: _round5(w.lat),
          lng: _round5(w.lng),
          acc: defaultAccuracyMeters,
          alt: _round2(w.ele ?? 0.0),
          type: typeString,
        ),
      );
    }

    if (!hasOnInn) {
      final GpxTrackPoint end = gpx.points.last;
      out.add(
        UserEventLocation(
          ts: pad19(end.timestampMs + 1000),
          lat: _round5(end.lat),
          lng: _round5(end.lng),
          acc: defaultAccuracyMeters,
          alt: _round2(end.ele ?? 0.0),
          type: _onInnKey,
        ),
      );
    }

    out.sort((a, b) => a.ts.compareTo(b.ts));
    return out;
  }

  UserEventLocation _toLocation(GpxTrackPoint p) {
    double acc = p.accuracy ?? (p.hdop != null ? p.hdop! * 5.0 : defaultAccuracyMeters);
    acc = acc.clamp(minAccuracyMeters, maxAccuracyMeters);
    return UserEventLocation(
      ts: pad19(p.timestampMs),
      lat: _round5(p.lat),
      lng: _round5(p.lng),
      acc: _round2(acc),
      alt: _round2(p.ele ?? 0.0),
      type: null,
    );
  }

  /// Inverts the export's waypoint mapping: `<type>` is `HashRunPointTypes.label`,
  /// `<name>` is the custom label when there is one. Photos are rows now, never
  /// track points, so a PHO waypoint is dropped.
  String? _markTypeFor(GpxWaypoint w) {
    final String? label = w.typeLabel;
    if (label == null) return null;
    // Labels carry emoji ("⭕️ Check ⭕️"); another app re-saving the file may
    // strip them, so compare the words only, and accept the key as well.
    final String wanted = _plain(label);
    HashRunPointTypes? type;
    for (final HashRunPointTypes t in HashRunPointTypes.values) {
      if (_plain(t.label) == wanted || t.key.toLowerCase() == wanted) {
        type = t;
        break;
      }
    }
    if (type == null || type.key == _photoKey) return null;
    final String? name = w.name;
    final bool custom =
        name != null && name.isNotEmpty && _plain(name) != _plain(type.label);
    return custom ? '${type.key}::$name' : type.key;
  }

  /// Letters, digits and single spaces, lower-cased — what survives a trip
  /// through another app's XML writer.
  static String _plain(String s) => s
      .replaceAll(RegExp(r'[^A-Za-z0-9 ]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toLowerCase();

  static double _round5(double v) => double.parse(v.toStringAsFixed(5));
  static double _round2(double v) => double.parse(v.toStringAsFixed(2));

  // ── Match ─────────────────────────────────────────────────────────────────

  /// Asks the server which runs started around the track, nearest first.
  /// Every candidate is returned — the caller decides with [RunCandidate.passesDistance].
  Future<List<RunCandidate>> findRuns(ParsedGpx gpx) async {
    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';
    final GpxTrackPoint first = gpx.points.first;

    final body = <String, dynamic>{
      'queryType': 'findRunForTrack',
      'deviceId': deviceId,
      'firstPointUtc': DateTime.fromMillisecondsSinceEpoch(
        gpx.firstTimestampMs,
        isUtc: true,
      ).toIso8601String(),
      'lastPointUtc': DateTime.fromMillisecondsSinceEpoch(
        gpx.lastTimestampMs,
        isUtc: true,
      ).toIso8601String(),
      'latitude': first.lat,
      'longitude': first.lng,
    };

    final String raw = await ServiceCommon.sendHttpPost(() {
      body['accessToken'] = Utilities.generateToken(
        userId,
        'hcapp_findRunForTrack',
        paramString: deviceSecret,
      );
      return jsonEncode(body);
    });
    if (raw.startsWith(ERROR_PREFIX)) {
      throw const GpxImportException(
        'Could not reach the server to look up the run. Please try again.',
      );
    }
    final List<dynamic> rowsets = jsonDecode(raw) as List<dynamic>;
    if (rowsets.isEmpty) return const <RunCandidate>[];
    return (rowsets[0] as List<dynamic>)
        .map((dynamic r) => RunCandidate.fromJson(r as Map<String, dynamic>))
        .toList(growable: false);
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Removes every point the user already has on the run, so a replaced
  /// import does not interleave with the old track. Returns how many went.
  Future<int> deleteExistingTrack(String eventId) async {
    final String userId = currentUserId;
    final GetPositionsApi api = GetPositionsApi();
    final UserPositionsPayload payload;
    try {
      payload = await api.fetchPositions(
        eventId: normalizeUuid(eventId),
        latestClientTimestampMs: '0000000000000000000',
        userId: userId,
        includeTrimmed: true,
      );
    } finally {
      api.dispose();
    }
    final List<int> timestamps = [
      for (final UserTrack t in payload.users)
        if (normalizeUuid(t.id) == normalizeUuid(userId))
          for (final TrackPoint p in t.positions) p.timestampMs,
    ];
    if (timestamps.isEmpty) return 0;
    final DeletePositionsApi del = DeletePositionsApi();
    int deleted = 0;
    try {
      for (int i = 0; i < timestamps.length; i += uploadChunk) {
        final List<int> chunk = timestamps.sublist(
          i,
          (i + uploadChunk).clamp(0, timestamps.length),
        );
        deleted += await del.deletePoints(
          eventId: normalizeUuid(eventId),
          userId: userId,
          timestampsMs: chunk,
        );
      }
    } finally {
      del.dispose();
    }
    return deleted;
  }

  /// Sends the points through StorePositions in chunks and checks the user in
  /// as At Hash, exactly as starting to track does. Throws if any chunk is
  /// refused; a re-run re-sends the same rows harmlessly (same capture
  /// times, upserts over themselves).
  Future<int> importTrack({
    required String eventId,
    required List<UserEventLocation> points,
  }) async {
    final String userId = currentUserId;
    final RunPointBuffer buf = RunPointBuffer(
      apiUrl: STORE_POSITIONS_URL,
      eventId: normalizeUuid(eventId),
      userId: userId,
    );
    int sent = 0;
    try {
      for (int i = 0; i < points.length; i += uploadChunk) {
        final List<UserEventLocation> chunk = points.sublist(
          i,
          (i + uploadChunk).clamp(0, points.length),
        );
        final bool ok = await buf.sendNow(chunk);
        if (!ok) {
          throw GpxImportException(
            'The server did not accept the track after $sent of '
            '${points.length} points. Please try again — nothing already '
            'sent is lost.',
          );
        }
        sent += chunk.length;
      }
    } finally {
      buf.dispose();
    }
    BootLogger.logBreadcrumb(
      'PackTrack: imported GPX — $sent point(s) onto eventId=$eventId',
    );

    // They were there. Best-effort, as at tracking start.
    try {
      await tableModel.hasherEventMapService.setEventAttendence(
        normalizeUuid(eventId),
        userId,
        AppDomainType.user,
        attendenceAtHash.value,
      );
    } catch (e, s) {
      BootLogger.logError('[GpxImportService.importTrack] check-in', e, s);
    }
    return sent;
  }
}
