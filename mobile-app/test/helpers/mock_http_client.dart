import 'dart:convert';
import 'package:http/http.dart';
import 'package:http/testing.dart';

/// Creates a [MockClient] that serves fixture JSON responses for SP calls.
///
/// [fixtures] maps `queryType` strings to response payloads. Pass either a
/// JSON string or a List/Map — non-string values are encoded automatically.
/// Any unrecognised queryType returns a 404 empty-array response.
///
/// Usage in a widget test:
/// ```dart
/// final client = createMockHttpClient({
///   'hcapp_syncUserData': '[[ {"success":1} ], [...data...]]',
/// });
/// ServiceCommon.sendHttpPost(bodyFactory, client: client);
/// ```
MockClient createMockHttpClient(Map<String, dynamic> fixtures) {
  return MockClient((request) async {
    final Map<String, dynamic> body =
        jsonDecode(request.body) as Map<String, dynamic>;
    final String queryType = body['queryType'] as String? ?? '';
    final dynamic fixture = fixtures[queryType];
    if (fixture == null) {
      return Response('[]', 404);
    }
    final String responseBody =
        fixture is String ? fixture : jsonEncode(fixture);
    return Response(
      responseBody,
      200,
      headers: {'content-type': 'application/json'},
    );
  });
}
