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

  static const Duration _flushInterval = Duration(seconds: 30);
  static const Duration _sendTimeout = Duration(seconds: 15);

  final String apiUrl;
  final String eventId;
  final String userId;
  final http.Client _http;

  final ListQueue<UserEventLocation> _q = ListQueue();
  bool _uploading = false;
  Timer? _flushTimer;

  void enqueue(UserEventLocation p) {
    _q.addLast(p);
    _ensureTimer();
  }

  void _ensureTimer() {
    _flushTimer ??= Timer.periodic(_flushInterval, (_) => unawaited(flush()));
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

    if (kDebugMode) {
      debugPrint('LocationService: Flushed run buffer.');
    }
  }

  /// Release the underlying HTTP client. Call this before discarding the buffer.
  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _http.close();
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
        final resp = await _http
            .post(
              Uri.parse(apiUrl),
              headers: <String, String>{'content-type': 'application/json'},
              body: body,
            )
            .timeout(_sendTimeout);
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          if (kDebugMode) {
            debugPrint(resp.body);
          }
          return true;
        }
        // 429/5xx: retry; others: give up
        if (resp.statusCode == 429 ||
            (resp.statusCode >= 500 && resp.statusCode < 600)) {
          // fall through to retry
        } else {
          BootLogger.logBreadcrumb(
            'PackTrack: upload batch DROPPED '
            '(non-retryable ${resp.statusCode}, ${batch.length} pts)',
          );
          return false;
        }
      } catch (_) {
        // network error -> retry
      }
      attempt++;
      if (attempt >= maxAttempts) {
        BootLogger.logBreadcrumb(
          'PackTrack: upload batch ABANDONED after $maxAttempts attempts '
          '(${batch.length} pts)',
        );
        return false;
      }
      final backoffMs = 200 * (1 << (attempt - 1));
      await Future.delayed(Duration(milliseconds: backoffMs));
    }
  }
}
