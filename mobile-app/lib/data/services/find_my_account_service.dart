import 'package:harrier_central/imports.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class HasherKennelMatch {
  HasherKennelMatch({
    required this.publicHasherId,
    required this.displayName,
    required this.hashName,
    required this.photo,
    required this.kennelId,
    required this.kennelName,
    required this.runCount,
  });

  final String publicHasherId;
  final String displayName;
  final String hashName;
  final String photo;
  final String kennelId;
  final String kennelName;
  final int runCount;
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class FindMyAccountService {
  /// Searches for hashers by hash name using the global shared token.
  /// Passes lat/lon for the 500-mile distance filter when available.
  /// Returns null on network error; empty list when no matches found.
  static Future<List<HasherKennelMatch>?> findHashersByHashName({
    required String searchTerm,
    double? lat,
    double? lon,
  }) async {
    if (Utilities.isNotConnected()) return null;

    final Map<String, dynamic> body = <String, dynamic>{
      'queryType': 'findHashersByHashName',
      'accessToken': Utilities.generateToken(
        GUID_EMPTY,
        'hcapp_findHashersByHashName',
      ),
      'searchTerm': searchTerm,
    };

    if (lat != null && lon != null) {
      body['lat'] = lat;
      body['lon'] = lon;
    }

    final String responseBody = await ServiceCommon.sendHttpPost(
      () => jsonEncode(body),
      noRetries: true,
    );

    if (responseBody.startsWith(ERROR_PREFIX)) return null;

    try {
      final List<dynamic> rowsets = jsonDecode(responseBody) as List<dynamic>;
      // rowset 0 = success envelope, rowset 1 = results
      if (rowsets.length < 2) return <HasherKennelMatch>[];

      final List<dynamic> rows = rowsets[1] as List<dynamic>;
      return rows.map((dynamic r) {
        final Map<String, dynamic> row = r as Map<String, dynamic>;
        return HasherKennelMatch(
          publicHasherId: row['publicHasherId'] as String? ?? '',
          displayName: row['displayName'] as String? ?? '',
          hashName: row['hashName'] as String? ?? '',
          photo: row['photo'] as String? ?? '',
          kennelId: row['kennelId'] as String? ?? '',
          kennelName: row['kennelName'] as String? ?? '',
          runCount: (row['runCount'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }

  /// Resolves lat/lon for the distance filter using the priority:
  ///   1. GPS (deviceInfo.deviceLat/deviceLon from boot)
  ///   2. IP geolocation ("loc" field from GetIpGeoInfo)
  ///   3. null (no filter)
  static Future<({double? lat, double? lon})> resolveLocation() async {
    // Priority 1: GPS
    if (deviceInfo.deviceLat != null && deviceInfo.deviceLon != null) {
      return (lat: deviceInfo.deviceLat, lon: deviceInfo.deviceLon);
    }

    // Priority 2: IP geolocation
    try {
      final Response response = await get(Uri.parse(IP_GEO_INFO_URL))
          .timeout(const Duration(milliseconds: 4000));
      if (response.statusCode == 200) {
        final Map<String, dynamic> json =
            jsonDecode(response.body) as Map<String, dynamic>;
        final String? loc = json['loc'] as String?;
        if (loc != null && loc.contains(',')) {
          final List<String> parts = loc.split(',');
          final double? lat = double.tryParse(parts[0].trim());
          final double? lon = double.tryParse(parts[1].trim());
          if (lat != null && lon != null) return (lat: lat, lon: lon);
        }
      }
    } catch (_) {}

    return (lat: null, lon: null);
  }

  /// Posts the selected hasher's publicHasherId to the EmailInviteCode
  /// endpoint. The server resolves their email address and sends the code —
  /// the email address is never returned to the client.
  static Future<bool> requestInviteCodeByPublicHasherId(
      String publicHasherId) async {
    try {
      final Response response = await post(
        Uri.parse(EMAIL_INVITE_CODE_API_URL),
        headers: <String, String>{'content-type': 'application/json'},
        body: jsonEncode(<String, String>{'publicHasherId': publicHasherId}),
      ).timeout(const Duration(seconds: 30));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
