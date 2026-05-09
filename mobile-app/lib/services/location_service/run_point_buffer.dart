import 'package:harrier_central/imports.dart';
import 'dart:collection';
import 'package:http/http.dart' as http;

typedef Json = Map<String, dynamic>;

class RunPointBuffer {
  RunPointBuffer({
    required this.apiUrl,
    required this.eventId,
    required this.userId,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String apiUrl;
  final String eventId;
  final String userId;
  final http.Client _http;

  final ListQueue<UserEventLocation> _q = ListQueue();
  bool _uploading = false;

  void enqueue(UserEventLocation p) {
    _q.addLast(p);
    //_ensureTimer();
  }

  Future<void> flush() async {
    if (_uploading) return;
    if (_q.isEmpty) return;

    // Snapshot current queue (so new points keep buffering)
    final batchSize = _q.length;
    final batch = List<UserEventLocation>.generate(
      batchSize,
      (i) => _q.elementAt(i),
      growable: false,
    );

    _uploading = true;
    try {
      final ok = await _sendBatch(batch);
      if (ok) {
        // Remove exactly what was sent
        for (var i = 0; i < batchSize; i++) {
          _q.removeFirst();
        }
      }
    } finally {
      _uploading = false;
    }
  }

  Future<bool> _sendBatch(List<UserEventLocation> batch) async {
    if (batch.isEmpty) return true;

    final body = jsonEncode(<String, dynamic>{
      'eventId': eventId,
      'userId': userId,
      'positions': batch.map((p) => p.toJson()).toList(),
    });

    // Simple retry with backoff for transient errors
    const maxAttempts = 5;
    var attempt = 0;
    while (true) {
      try {
        final resp = await _http.post(
          Uri.parse(apiUrl),
          headers: <String, String>{'content-type': 'application/json'},
          body: body,
        );
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          print(resp.body);
          return true;
        }
        // 429/5xx: retry; others: give up
        if (resp.statusCode == 429 ||
            (resp.statusCode >= 500 && resp.statusCode < 600)) {
          // fall through to retry
        } else {
          return false;
        }
      } catch (_) {
        // network error -> retry
      }
      attempt++;
      if (attempt >= maxAttempts) return false;
      final backoffMs = 200 * (1 << (attempt - 1));
      await Future.delayed(Duration(milliseconds: backoffMs));
    }
  }

  // void _ensureTimer() {
  //   _timer ??= Timer.periodic(flushInterval, (_) => flush());
  // }

  // Future<void> dispose({bool flushBeforeDispose = true}) async {
  //   _timer?.cancel();
  //   _timer = null;
  //   if (flushBeforeDispose) {
  //     await flush();
  //   }
  //   _http.close();
  // }
}
