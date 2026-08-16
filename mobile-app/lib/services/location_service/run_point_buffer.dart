import 'package:harrier_central/imports.dart';
import 'dart:collection';
import 'package:http/http.dart' as http;

typedef Json = Map<String, dynamic>;

class RunPointBuffer {
  RunPointBuffer({
    required this.apiUrl,
    required this.eventId,
    required this.userId,
    this.onRemoteTrackingEnded,
    http.Client? httpClient,
  }) : _injectedClient = httpClient;

  static const Duration _flushInterval = Duration(seconds: 30);
  static const Duration _sendTimeout = Duration(seconds: 15);

  final String apiUrl;
  final String eventId;
  final String userId;

  /// Fired when a StorePositions response carries the event-level
  /// "tracking ended" flag (an admin ended tracking for everyone via
  /// EndEventTracking). The argument is the server's 19-digit endedAt epoch-ms
  /// stamp. Only the LIVE tracking buffer wires this — one-shot buffers
  /// (boundary markers, out-of-band marks) must not react to it.
  final void Function(String endedAtMs)? onRemoteTrackingEnded;

  // No persistent client. This buffer flushes GPS batches every 30s *while the
  // app is backgrounded* during a run — precisely when iOS tears down sockets.
  // A pooled keep-alive connection would go stale ("Bad file descriptor"),
  // burn all 5 retries, and ABANDON the batch, silently dropping track points.
  // One-shot `http.post` opens a fresh socket per flush, so a resume can never
  // hand us a dead connection. An injected client is honoured for tests only.
  final http.Client? _injectedClient;

  final ListQueue<UserEventLocation> _q = ListQueue();
  bool _uploading = false;
  Timer? _flushTimer;

  // Set on resume (stop→restart of the same track): the next batch that
  // REACHES the server carries `resumed: true`, asking it to delete any prior
  // terminator (On Inn) rows for this user+event — a terminator followed by
  // later points is always a mistake. Kept pending across failed sends so a
  // bad-signal resume still cleans up on the first batch that gets through.
  bool _resumedCleanupPending = false;
  void markResumed() => _resumedCleanupPending = true;

  void enqueue(UserEventLocation p) {
    _q.addLast(p);
    _ensureTimer();
  }

  /// Removes a not-yet-uploaded point by its 19-digit timestamp. Undo path:
  /// the mark may still be queued (bad signal), and a server-side delete
  /// alone would let the queued copy re-upload afterwards. Returns true if a
  /// queued point was removed.
  bool removeByTs(String ts19) {
    final before = _q.length;
    _q.removeWhere((p) => p.ts == ts19);
    return _q.length != before;
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

  /// Surfaces the piggybacked "tracking ended" flag from a successful
  /// StorePositions response body. Best-effort: an unparseable body is an
  /// older server or a proxy page — never an error.
  void _checkRemoteTrackingEnded(String body) {
    final callback = onRemoteTrackingEnded;
    if (callback == null) return;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['trackingEnded'] == true) {
        callback(decoded['trackingEndedAtMs']?.toString() ?? '');
      }
    } catch (_) {
      // Not JSON — ignore.
    }
  }

  /// Sends [points] as their own batch RIGHT NOW, bypassing both the queue and
  /// the [flush] re-entrancy guard, and reports whether the server took them.
  ///
  /// [flush] deliberately returns early when a send is already in flight, which
  /// is correct for ordinary GPS points (they simply ride the next batch) but
  /// wrong for a distress mark: an in-flight batch on a bad link can hold the
  /// guard for over a minute (15s timeout x 5 retries), and an "I'm lost" mark
  /// must not sit in a queue behind it. Retry/backoff still applies, and the
  /// one-point payload gives the best odds on a marginal signal.
  Future<bool> sendNow(List<UserEventLocation> points) => _sendBatch(points);

  /// Stop the flush timer and release an injected test client, if any. The
  /// production one-shot path has no client to close.
  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _injectedClient?.close();
  }

  Future<bool> _sendBatch(List<UserEventLocation> batch) async {
    if (batch.isEmpty) return true;

    final bool carriesResumedFlag = _resumedCleanupPending;
    final body = jsonEncode(<String, dynamic>{
      'eventId': eventId,
      'userId': userId,
      'positions': batch.map((p) => p.toJson()).toList(),
      if (carriesResumedFlag) 'resumed': true,
    });

    // Simple retry with backoff for transient errors
    const maxAttempts = 5;
    var attempt = 0;
    while (true) {
      try {
        final client = _injectedClient;
        final uri = Uri.parse(apiUrl);
        const headers = <String, String>{'content-type': 'application/json'};
        final resp = await (client != null
                ? client.post(uri, headers: headers, body: body)
                : http.post(uri, headers: headers, body: body))
            .timeout(_sendTimeout);
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          if (carriesResumedFlag) _resumedCleanupPending = false;
          if (kDebugMode) {
            debugPrint(resp.body);
          }
          _checkRemoteTrackingEnded(resp.body);
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
