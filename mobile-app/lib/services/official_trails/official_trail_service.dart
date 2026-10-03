import 'package:harrier_central/imports.dart';
import 'package:latlong2/latlong.dart' as latlng;

/// One lane of a run's official (hare's) trail (E5.F6.S6): its trail type
/// (1 Walkers, 2 Short, 3 Normal, 4 Long, 5 Ballbreaker, >= 100 kennel's own)
/// and its points.
class OfficialTrailLane {
  const OfficialTrailLane({
    required this.type,
    required this.points,
    this.distanceM,
  });

  final int type;
  final List<latlng.LatLng> points;
  final int? distanceM;

  /// The app's built-in trail-type colours, as on the website.
  static Color colorOf(int type) => switch (type) {
    1 => const Color(0xFF16A34A),
    2 => const Color(0xFFF59E0B),
    4 => const Color(0xFF7C3AED),
    5 => const Color(0xFF0F172A),
    _ => const Color(0xFFDC2626),
  };
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

  /// Rows of hcapp_getKennelOfficialTrails. Tolerant: a run whose trail
  /// will not parse is left out rather than failing the map.
  static KennelRunTrail? fromRow(Map<String, dynamic> j) {
    try {
      final Map<String, dynamic> trail =
          jsonDecode('${j['OfficialTrail'] ?? '{}'}') as Map<String, dynamic>;
      Map<String, dynamic> info = <String, dynamic>{};
      try {
        info =
            jsonDecode('${j['OfficialTrailInfo'] ?? '{}'}')
                as Map<String, dynamic>;
      } catch (_) {}
      final Map<int, int> distances = <int, int>{
        for (final dynamic l
            in (info['lanes'] as List<dynamic>? ?? <dynamic>[]))
          if (l is Map && l['type'] is num && l['distanceM'] is num)
            (l['type'] as num).toInt(): (l['distanceM'] as num).toInt(),
      };
      final List<OfficialTrailLane> lanes = <OfficialTrailLane>[];
      for (final dynamic l
          in (trail['lanes'] as List<dynamic>? ?? <dynamic>[])) {
        if (l is! Map) continue;
        final int type = (l['type'] as num?)?.toInt() ?? 3;
        final List<latlng.LatLng> pts = <latlng.LatLng>[
          for (final dynamic p
              in (l['points'] as List<dynamic>? ?? <dynamic>[]))
            if (p is List && p.length >= 2 && p[0] is num && p[1] is num)
              latlng.LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()),
        ];
        if (pts.length >= 2) {
          lanes.add(
            OfficialTrailLane(
              type: type,
              points: pts,
              distanceM: distances[type],
            ),
          );
        }
      }
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

class OfficialTrailService {
  const OfficialTrailService._();

  /// Every official trail of the kennel's ended runs, newest first. Null when
  /// the call failed; an empty list is the ordinary answer for most kennels.
  static Future<List<KennelRunTrail>?> fetchKennelTrails(HcId kennelId) async {
    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';
    if (userId.isEmpty || deviceId.isEmpty || deviceSecret.isEmpty) return null;

    final String result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'getKennelOfficialTrails',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_getKennelOfficialTrails',
          paramString: deviceSecret,
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
