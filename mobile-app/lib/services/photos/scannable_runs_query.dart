import 'package:harrier_central/imports.dart';
import 'package:harrier_central/services/photos/camera_roll_scan_service.dart';
import 'package:latlong2/latlong.dart';

/// Builds the runs a camera-roll sweep should look at, from the phone's own
/// database (E6.F2.S5). No server call: the attendance rows, the run details
/// and the hasher's own trails are all synced already.
class ScannableRunsQuery {
  const ScannableRunsQuery._();

  /// Runs the hasher actually attended, newest first. Restricting to these
  /// removes most false matches before geography is even consulted — a photo
  /// taken near a run somebody else did is not theirs to file.
  ///
  /// [kennelId] narrows to one kennel (the kennel-level sweep); [eventId]
  /// narrows to a single run (the button on the run).
  static Future<List<ScannableRun>> attended({
    String? kennelId,
    String? eventId,
    int limit = 200,
  }) async {
    final h = tableModel.hasherEventMapTableHelper;
    final e = tableModel.eventsTableHelper;
    final k = tableModel.kennelsTableHelper;
    final String userId = currentUserId;
    if (userId.isEmpty) return const <ScannableRun>[];

    final List<Object?> args = <Object?>[userId, attendenceAtHash.value];
    final StringBuffer where = StringBuffer(
      'hem.${h.colUserId} = ? AND hem.${h.colRemoved} = 0 '
      'AND hem.${h.colAttendenceState} >= ?',
    );
    if (kennelId != null && kennelId.isNotEmpty) {
      where.write(' AND evt.${e.colKennelId} = ?');
      args.add(kennelId);
    }
    if (eventId != null && eventId.isNotEmpty) {
      where.write(' AND hem.${h.colEventId} = ?');
      args.add(eventId);
    }
    args.add(limit);

    final List<Map<String, dynamic>> rows = await database.rawQuery('''
      SELECT hem.${h.colEventId}        AS eventId,
             hem.${h.colTrackGzip}      AS gz,
             evt.${e.colEventName}      AS eventName,
             evt.${e.colEventNumber}    AS eventNumber,
             evt.${e.colKennelId}       AS kennelId,
             evt.${e.colEventStartDatetimeGmt} AS startGmt,
             evt.${e.colHcLatitude}     AS lat,
             evt.${e.colHcLongitude}    AS lng,
             k.${k.colKennelUniqueShortName} AS slug
        FROM ${EnumDataTables.hasherEventMap.commonTableName} hem
        JOIN ${EnumDataTables.events.commonTableName} evt
          ON evt.${e.colEventId} = hem.${h.colEventId}
        LEFT JOIN ${EnumDataTables.kennels.commonTableName} k
          ON k.${k.colKennelId} = evt.${e.colKennelId}
       WHERE ${where.toString()}
       ORDER BY evt.${e.colEventStartDatetimeGmt} DESC
       LIMIT ?
      ''', args);

    final List<ScannableRun> out = <ScannableRun>[];
    for (final Map<String, dynamic> r in rows) {
      final DateTime? start = _utc(r['startGmt']);
      if (start == null) continue;

      // The hasher's own trail, decoded from the archive on the row. When
      // they tracked the run this is the geofence; the start is the fallback.
      List<LatLng> trail = const <LatLng>[];
      final String? gz = r['gz'] as String?;
      if (gz != null && gz.isNotEmpty) {
        try {
          trail = TrackIndex.pathFromArchive(gz);
        } catch (_) {
          trail = const <LatLng>[];
        }
      }

      out.add(
        ScannableRun(
          eventId: normalizeUuid(r['eventId'] as String),
          eventName: (r['eventName'] as String?) ?? 'Run',
          eventNumber: (r['eventNumber'] as num?)?.toInt() ?? 0,
          kennelId: normalizeUuid((r['kennelId'] as String?) ?? ''),
          kennelSlug: (r['slug'] as String?) ?? '',
          startUtc: start,
          startLat: (r['lat'] as num?)?.toDouble(),
          startLng: (r['lng'] as num?)?.toDouble(),
          trail: trail,
        ),
      );
    }
    return out;
  }

  /// The stored start is the run's true instant, written without a zone.
  static DateTime? _utc(dynamic v) {
    if (v == null) return null;
    final String t = '$v'.trim();
    if (t.isEmpty) return null;
    final int ms = TrackIndex.sqlUtcMs(t) ?? -1;
    if (ms < 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }
}
