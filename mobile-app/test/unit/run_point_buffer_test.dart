import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harrier_central/data/models/user_event_location/user_event_location.dart';
import 'package:harrier_central/services/location_service/run_point_buffer.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/get_storage.dart';

import '../golden/test_helpers.dart';

const String _url = 'https://example.invalid/api/StorePositions';
const String _eventId = 'e1111111-1111-1111-1111-111111111111';
const String _userId = 'u2222222-2222-2222-2222-222222222222';

UserEventLocation _point(int i) => UserEventLocation(
  ts: (1757000000000 + i).toString().padLeft(19, '0'),
  lat: 51.5 + i / 100000,
  lng: -0.12 + i / 100000,
  acc: 5.0,
  alt: 10.0,
);

/// A client that answers every request with [status], counting the calls.
class _CountingClient {
  _CountingClient(this.status);
  final int status;
  int calls = 0;

  MockClient get client => MockClient((http.Request req) async {
    calls++;
    return http.Response(status == 200 ? '{}' : 'nope', status);
  });
}

Map<String, dynamic> _outbox() {
  final String? raw = getStringPref(StringPrefsEnum.packTrackOutboxJson);
  if (raw == null) return <String, dynamic>{};
  return jsonDecode(raw) as Map<String, dynamic>;
}

Future<void> _seedOutbox({
  required String userId,
  required int savedAtMs,
  required int points,
}) async {
  await setStringPref(
    StringPrefsEnum.packTrackOutboxJson,
    jsonEncode(<String, dynamic>{
      'packtrack_outbox:$_eventId': <String, dynamic>{
        'userId': userId,
        'savedAtMs': savedAtMs,
        'points': List<Map<String, dynamic>>.generate(
          points,
          (i) => _point(i).toJson(),
        ),
      },
    }),
  );
}

RunPointBuffer _buffer(MockClient client) => RunPointBuffer(
  apiUrl: _url,
  eventId: _eventId,
  userId: _userId,
  httpClient: client,
);

void main() {
  setUp(() async => setupTestEnvironment());
  tearDown(() async => tearDownTestEnvironment());

  group('a send that fails', () {
    test('keeps its points and mirrors them to storage', () async {
      final server = _CountingClient(500);
      final buf = _buffer(server.client);
      for (int i = 0; i < 3; i++) {
        buf.enqueue(_point(i));
      }

      await buf.flush();

      // Five attempts, then the batch is held — not lost.
      expect(server.calls, 5);
      final entry =
          _outbox()['packtrack_outbox:$_eventId'] as Map<String, dynamic>;
      expect((entry['points'] as List<dynamic>).length, 3);
      expect(entry['userId'], _userId);

      buf.dispose();
    });

    test('sends the retained points on a later flush that succeeds', () async {
      final failing = _CountingClient(500);
      final buf = _buffer(failing.client);
      buf.enqueue(_point(1));
      await buf.flush();
      expect(_outbox(), isNotEmpty);
      buf.dispose();

      // Same run, a working link: the held point goes out and storage clears.
      final ok = _CountingClient(200);
      final buf2 = _buffer(ok.client);
      await buf2.restorePending();
      await buf2.flush();

      expect(ok.calls, 1);
      expect(_outbox(), isEmpty);
      buf2.dispose();
    });
  });

  group('restore across a process death', () {
    test('adopts points this user left behind for this event', () async {
      await _seedOutbox(
        userId: _userId,
        savedAtMs: DateTime.now().millisecondsSinceEpoch,
        points: 4,
      );

      final ok = _CountingClient(200);
      final buf = _buffer(ok.client);
      await buf.restorePending();
      await buf.flush();

      expect(ok.calls, 1, reason: 'the recovered points were sent');
      expect(_outbox(), isEmpty, reason: 'and storage was cleared after');
      buf.dispose();
    });

    test('restored points go out ahead of newly buffered ones', () async {
      await _seedOutbox(
        userId: _userId,
        savedAtMs: DateTime.now().millisecondsSinceEpoch,
        points: 2,
      );

      final List<String> sentTs = <String>[];
      final client = MockClient((http.Request req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        for (final dynamic p in body['positions'] as List<dynamic>) {
          sentTs.add((p as Map<String, dynamic>)['ts'] as String);
        }
        return http.Response('{}', 200);
      });

      final buf = _buffer(client);
      buf.enqueue(_point(50));
      await buf.flush();

      expect(sentTs.length, 3);
      // The two recovered points (ts for i=0,1) precede the live one (i=50).
      expect(sentTs.first, _point(0).ts);
      expect(sentTs.last, _point(50).ts);
      buf.dispose();
    });

    test('will not send another hasher points left on a shared device',
        () async {
      await _seedOutbox(
        userId: 'someone-else',
        savedAtMs: DateTime.now().millisecondsSinceEpoch,
        points: 5,
      );

      final ok = _CountingClient(200);
      final buf = _buffer(ok.client);
      await buf.restorePending();
      await buf.flush();

      expect(ok.calls, 0, reason: 'nothing of theirs was adopted');
      expect(_outbox(), isEmpty, reason: 'and it was cleared out');
      buf.dispose();
    });

    test('discards a queue older than the 48h keep window', () async {
      await _seedOutbox(
        userId: _userId,
        savedAtMs: DateTime.now()
            .subtract(const Duration(hours: 49))
            .millisecondsSinceEpoch,
        points: 5,
      );

      final ok = _CountingClient(200);
      final buf = _buffer(ok.client);
      await buf.restorePending();
      await buf.flush();

      expect(ok.calls, 0);
      expect(_outbox(), isEmpty);
      buf.dispose();
    });
  });

  test('a refused batch is discarded rather than retried for ever', () async {
    final refusing = _CountingClient(400);
    final buf = _buffer(refusing.client);
    buf.enqueue(_point(1));

    await buf.flush();

    // One attempt only — a non-retryable status is not worth five — and the
    // batch leaves the queue so it cannot wedge every later flush.
    expect(refusing.calls, 1);
    expect(_outbox(), isEmpty);

    // Nothing left to send.
    await buf.flush();
    expect(refusing.calls, 1);
    buf.dispose();
  });

  test('the queue is capped so a long outage cannot grow it without bound',
      () async {
    final failing = _CountingClient(500);
    final buf = _buffer(failing.client);
    for (int i = 0; i < 10050; i++) {
      buf.enqueue(_point(i));
    }

    await buf.flush();

    final entry =
        _outbox()['packtrack_outbox:$_eventId'] as Map<String, dynamic>;
    final List<dynamic> points = entry['points'] as List<dynamic>;
    expect(points.length, 10000);
    // The oldest were shed, so the newest point is still there.
    expect(
      (points.last as Map<String, dynamic>)['ts'],
      _point(10049).ts,
    );
    buf.dispose();
  });
}
