import 'package:harrier_central/imports.dart';

import 'package:http/http.dart' as http;

class GetPositionsApi {
  GetPositionsApi({http.Client? httpClient, Uri? baseUri})
    : _injectedClient = httpClient,
      _baseUri = baseUri ?? Uri.parse(GET_POSITIONS_URL);

  // No persistent client: a keep-alive pool's socket goes stale across an iOS
  // background/resume (the OS closes the fd → "Bad file descriptor" on the next
  // reuse). We POST one-shot via `http.post` — a fresh socket per request,
  // matching ServiceCommon. An injected client is honoured for tests only.
  final http.Client? _injectedClient;
  final Uri _baseUri;

  /// Closes an injected test client if one was supplied. No-op on the
  /// production one-shot path (each `http.post` closes its own client).
  void dispose() {
    _injectedClient?.close();
  }

  Future<http.Response> _post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
    required Duration timeout,
  }) {
    final client = _injectedClient;
    final request = client != null
        ? client.post(uri, headers: headers, body: body)
        : http.post(uri, headers: headers, body: body);
    return request.timeout(timeout);
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

    final response = await _post(
      uri,
      headers: {
        HttpHeaders.acceptEncodingHeader: 'gzip',
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.contentTypeHeader: 'application/json',
        'X-Api-Key': GET_POSITIONS_API_KEY,
      },
      body: requestBody,
      timeout: timeout,
    );

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
