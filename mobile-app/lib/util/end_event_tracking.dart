import 'package:harrier_central/imports.dart';

import 'package:http/http.dart' as http;

/// Result of an EndEventTracking call: whether the event-level "tracking
/// ended" flag is set, and the server's 19-digit endedAt epoch-ms stamp when
/// it is.
typedef EndEventTrackingStatus = ({bool ended, String? endedAtMs});

/// Thin client for the EndEventTracking endpoint. Sets, clears, or reads the
/// event-level "tracking ended" flag; while set, every StorePositions response
/// carries it, so phones still uploading points stop their tracking loop
/// within one flush interval (docs/packtrack_auto_stop_plan.md).
///
/// Guarded by the same `X-Api-Key` as GetPositions/DeletePositions. The
/// calling UI is additionally gated on kennel-admin rights (the trim
/// overlay's `authCanManageRuns` guard).
class EndEventTrackingApi {
  EndEventTrackingApi({http.Client? httpClient, Uri? baseUri})
    : _injectedClient = httpClient,
      _baseUri = baseUri ?? Uri.parse(END_EVENT_TRACKING_URL);

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

  /// Sets ([ended] true), clears ([ended] false), or queries ([ended] null)
  /// the flag for [eventId]. Throws on any non-200 response.
  Future<EndEventTrackingStatus> setEnded({
    required String eventId,
    required bool? ended,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final requestBody = json.encode({'eventId': eventId, 'ended': ?ended});

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
        'EndEventTracking failed: ${response.statusCode}',
        uri: _baseUri,
      );
    }
    final decoded = json.decode(response.body) as Map<String, dynamic>;
    return (
      ended: decoded['ended'] == true,
      endedAtMs: decoded['trackingEndedAtMs']?.toString(),
    );
  }
}
