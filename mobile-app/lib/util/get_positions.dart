import 'package:harrier_central/imports.dart';

import 'package:http/http.dart' as http;

class GetPositionsApi {
  GetPositionsApi({http.Client? httpClient, Uri? baseUri})
    : _client = httpClient ?? http.Client(),
      _baseUri = baseUri ?? Uri.parse(GET_POSITIONS_URL);

  final http.Client _client;
  final Uri _baseUri;

  /// Release the underlying HTTP client.
  void dispose() {
    _client.close();
  }

  Future<UserPositionsPayload> fetchPositions({
    required String eventId,
    required String latestClientTimestampMs,
    String? userId,
    bool includeTrimmed = false,
    List<Map<String, dynamic>> users = const [],
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = _baseUri;

    var body = <String, dynamic>{'eventId': eventId, 'users': users};

    // Optional server-side filter to a single runner (used by the resume seed
    // to fetch only the caller's own track).
    if (userId != null && userId.isNotEmpty) {
      body['userId'] = userId;
    }

    // Admin-only: ask the server to return the FULL track (points outside the
    // trim window included) plus the current window, so the trim editor can
    // show everything and drag the handles back outward. Normal viewers omit
    // this and receive the trimmed track.
    if (includeTrimmed) {
      body['includeTrimmed'] = true;
    }

    if (latestClientTimestampMs.isNotEmpty) {
      body['AfterTimestamp'] = latestClientTimestampMs;
    }

    final requestBody = json.encode(body);

    final response = await _client
        .post(
          uri,
          headers: {
            HttpHeaders.acceptEncodingHeader: 'gzip',
            HttpHeaders.acceptHeader: 'application/json',
            HttpHeaders.contentTypeHeader: 'application/json',
            'X-Api-Key': GET_POSITIONS_API_KEY,
          },
          body: requestBody,
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw HttpException(
        'GetPositions failed: ${response.statusCode} ${response.reasonPhrase}',
        uri: uri,
      );
    }

    var resultStr = utf8.decode(response.bodyBytes);

    var result = json.decode(resultStr);

    final payload = UserPositionsPayload.fromJson(
      result as Map<String, dynamic>,
    );

    //lastPositionTimestamp = result['latestServerTimestampMs'] ?? '';

    return payload;
  }
}
