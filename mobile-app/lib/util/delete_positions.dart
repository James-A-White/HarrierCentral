import 'package:harrier_central/imports.dart';

import 'package:http/http.dart' as http;

/// Thin client for the DeletePositions endpoint. Removes specific stored track
/// points for a single runner+event, identified by their caller timestamps.
///
/// The only current caller is the resume flow, which strips the On-Inn
/// terminator(s) left before a stopped/closed track so the continuation renders
/// as one line. The endpoint is guarded by the same `X-Api-Key` as GetPositions
/// and only ever deletes points matching the supplied `userId`, so it can never
/// touch another runner's track.
class DeletePositionsApi {
  DeletePositionsApi({http.Client? httpClient, Uri? baseUri})
    : _injectedClient = httpClient,
      _baseUri = baseUri ?? Uri.parse(DELETE_POSITIONS_URL);

  // No persistent client — see GetPositionsApi: keep-alive sockets go stale
  // across an iOS background/resume, so we POST one-shot via `http.post`. An
  // injected client is honoured for tests only.
  final http.Client? _injectedClient;
  final Uri _baseUri;

  /// Closes an injected test client if one was supplied. No-op on the
  /// production one-shot path.
  void dispose() {
    _injectedClient?.close();
  }

  /// Deletes the points at [timestampsMs] (epoch-ms, matched against each
  /// point's caller TimestampMs) for [userId] on [eventId]. Returns the number
  /// the server reported deleted, or 0 on any non-200 / empty input.
  Future<int> deletePoints({
    required String eventId,
    required String userId,
    required List<int> timestampsMs,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (timestampsMs.isEmpty) return 0;

    final requestBody = json.encode({
      'eventId': eventId,
      'userId': userId,
      // 19-digit zero-padded to match the stored RowKey caller segment.
      'timestamps': timestampsMs.map(pad19).toList(),
    });

    final client = _injectedClient;
    final headers = {
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json',
      'X-Api-Key': GET_POSITIONS_API_KEY,
    };
    final response = await (client != null
            ? client.post(_baseUri, headers: headers, body: requestBody)
            : http.post(_baseUri, headers: headers, body: requestBody))
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw HttpException(
        'DeletePositions failed: ${response.statusCode} ${response.reasonPhrase}',
        uri: _baseUri,
      );
    }

    final result = json.decode(utf8.decode(response.bodyBytes));
    if (result is Map && result['deleted'] is num) {
      return (result['deleted'] as num).toInt();
    }
    return 0;
  }
}
