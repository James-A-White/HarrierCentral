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
    List<Map<String, dynamic>> users = const [],
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = _baseUri;

    var body = <String, dynamic>{'eventId': eventId, 'users': users};

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
