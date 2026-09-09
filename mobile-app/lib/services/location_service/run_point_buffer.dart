import 'package:harrier_central/imports.dart';
import 'dart:collection';
import 'package:http/http.dart' as http;

typedef Json = Map<String, dynamic>;

/// What happened to one attempt at sending a batch.
enum _SendOutcome {
  /// The server took the points. Remove them from the queue.
  accepted,

  /// Could not be delivered this time (no signal, timeout, 429, 5xx). The
  /// points stay queued and ride the next flush — this is NOT data loss.
  retryLater,

  /// The server actively refused this payload (a non-retryable status). Every
  /// resend would be refused identically, so the batch is discarded rather
  /// than left to wedge the queue and grow it without bound.
  refused,
}

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

  /// Hard ceiling on the unsent queue. A run in a signal hole accumulates
  /// points indefinitely — 461 was the worst seen over the GNH 2026 weekend and
  /// it was still climbing when the log was cut. This is a safety valve, not an
  /// expected path: ~10k points is several hours of tracking at the Best tier,
  /// and past it the oldest points are shed so a long outage cannot grow the
  /// queue without bound.
  static const int _maxQueuedPoints = 10000;

  /// Persisted queues older than this are discarded on load. A track that has
  /// been sitting unsent for two days is not going to be useful live, and the
  /// durable archive of finished runs is a separate concern (todos/app.md).
  static const Duration _outboxMaxAge = Duration(hours: 48);

  final ListQueue<UserEventLocation> _q = ListQueue();
  bool _uploading = false;
  Timer? _flushTimer;

  /// True once [restorePending] has run, so a persist can never write an empty
  /// queue over points still waiting to be read back.
  bool _restored = false;

  // Set on resume (stop→restart of the same track): the next batch that
  // REACHES the server carries `resumed: true`, asking it to delete any prior
  // terminator (On Inn) rows for this user+event — a terminator followed by
  // later points is always a mistake. Kept pending across failed sends so a
  // bad-signal resume still cleans up on the first batch that gets through.
  bool _resumedCleanupPending = false;
  void markResumed() => _resumedCleanupPending = true;

  void enqueue(UserEventLocation p) {
    _q.addLast(p);
    if (_q.length > _maxQueuedPoints) {
      final int shed = _q.length - _maxQueuedPoints;
      for (int i = 0; i < shed; i++) {
        _q.removeFirst();
      }
      BootLogger.logBreadcrumb(
        'PackTrack: unsent queue hit $_maxQueuedPoints points — shed $shed '
        'oldest (eventId=$eventId)',
      );
    }
    _ensureTimer();
  }

  // ---------------------------------------------------------------------
  // Durable queue
  //
  // The queue used to live only in RAM. A failed send keeps its points (they
  // ride the next flush), so a bad-signal stretch is survivable — but the
  // process dying is not, and during a run this app is a background GPS
  // consumer holding 400MB+, which is exactly what iOS kills first. Everything
  // not yet acknowledged went with it, silently.
  //
  // So the queue is mirrored to storage whenever it changes materially: after
  // a send (success or failure) and on the way to the background. It is keyed
  // by event so two runs can never adopt each other's points, and it is read
  // back before the first flush of a new buffer for that event.
  // ---------------------------------------------------------------------

  String get _outboxKeyPrefix => 'packtrack_outbox:';

  /// Reads back any points this device failed to send for this event before it
  /// was last killed, and puts them at the FRONT of the queue so the track
  /// stays in time order.
  Future<void> restorePending() async {
    if (_restored) return;
    _restored = true;
    try {
      final Map<String, dynamic> all = _readOutbox();
      final dynamic entry = all['$_outboxKeyPrefix$eventId'];
      if (entry is! Map) return;

      final int savedAtMs = (entry['savedAtMs'] as num?)?.toInt() ?? 0;
      final bool stale =
          DateTime.now().millisecondsSinceEpoch - savedAtMs >
          _outboxMaxAge.inMilliseconds;
      // Points belonging to a different hasher on a shared device are not ours
      // to send — the server would attribute someone else's track to us.
      final bool mine = entry['userId'] == userId;

      if (stale || !mine) {
        await _clearPersisted();
        return;
      }

      final List<dynamic> raw = (entry['points'] as List<dynamic>?) ?? const [];
      if (raw.isEmpty) return;

      final restored = raw
          .whereType<Map<String, dynamic>>()
          .map(UserEventLocation.fromJson)
          .toList(growable: false);

      // Front, not back: these are older than anything buffered since launch.
      for (final p in restored.reversed) {
        _q.addFirst(p);
      }
      BootLogger.logBreadcrumb(
        'PackTrack: recovered ${restored.length} unsent points from the '
        'previous session (eventId=$eventId)',
      );
      _ensureTimer();
    } catch (e, s) {
      BootLogger.logError('[RunPointBuffer.restorePending]', e, s);
    }
  }

  Map<String, dynamic> _readOutbox() {
    final String? raw = getStringPref(StringPrefsEnum.packTrackOutboxJson);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Mirrors the current queue to storage. Cheap enough to call on every flush:
  /// the queue is normally empty or a handful of points, and the write only
  /// happens while a run is being tracked.
  Future<void> persistPending() async {
    if (!_restored) return;
    try {
      final Map<String, dynamic> all = _readOutbox();
      final String key = '$_outboxKeyPrefix$eventId';

      if (_q.isEmpty) {
        if (!all.containsKey(key)) return;
        all.remove(key);
      } else {
        all[key] = <String, dynamic>{
          'userId': userId,
          'savedAtMs': DateTime.now().millisecondsSinceEpoch,
          'points': _q.map((p) => p.toJson()).toList(growable: false),
        };
      }

      // Drop other events' stale leftovers while we are here, so an abandoned
      // run cannot keep its points in storage for ever.
      final int nowMs = DateTime.now().millisecondsSinceEpoch;
      all.removeWhere((k, v) {
        if (k == key) return false;
        if (v is! Map) return true;
        final int saved = (v['savedAtMs'] as num?)?.toInt() ?? 0;
        return nowMs - saved > _outboxMaxAge.inMilliseconds;
      });

      await setStringPref(
        StringPrefsEnum.packTrackOutboxJson,
        all.isEmpty ? null : jsonEncode(all),
      );
    } catch (e, s) {
      BootLogger.logError('[RunPointBuffer.persistPending]', e, s);
    }
  }

  Future<void> _clearPersisted() async {
    final Map<String, dynamic> all = _readOutbox();
    all.remove('$_outboxKeyPrefix$eventId');
    await setStringPref(
      StringPrefsEnum.packTrackOutboxJson,
      all.isEmpty ? null : jsonEncode(all),
    );
  }

  void _ensureTimer() {
    _flushTimer ??= Timer.periodic(_flushInterval, (_) => unawaited(flush()));
  }

  Future<void> flush() async {
    if (_uploading) return;
    // Pick up anything the previous session could not send before flushing, so
    // the recovered points go out with (and ahead of) the current ones.
    if (!_restored) await restorePending();
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
      final outcome = await _sendBatch(batch);
      // Accepted: gone to the server. Refused: the server will never take it,
      // so holding it only wedges the queue. Either way the points leave.
      if (outcome != _SendOutcome.retryLater) {
        for (var i = 0; i < batchSize; i++) {
          _q.removeFirst();
        }
      }
    } finally {
      _uploading = false;
    }

    // Whichever way it went, storage should match the queue: emptied on a
    // successful send, holding the unsent points on a failed one.
    await persistPending();

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
  Future<bool> sendNow(List<UserEventLocation> points) async =>
      await _sendBatch(points) == _SendOutcome.accepted;

  /// Stop the flush timer and release an injected test client, if any. The
  /// production one-shot path has no client to close.
  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _injectedClient?.close();
  }

  Future<_SendOutcome> _sendBatch(List<UserEventLocation> batch) async {
    if (batch.isEmpty) return _SendOutcome.accepted;

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
        final int started = NetworkMeter.begin(body);
        final http.Response resp;
        try {
          resp = await (client != null
                  ? client.post(uri, headers: headers, body: body)
                  : http.post(uri, headers: headers, body: body))
              .timeout(_sendTimeout);
        } catch (_) {
          NetworkMeter.end(started, null);
          rethrow;
        }
        NetworkMeter.end(started, resp);
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          if (carriesResumedFlag) _resumedCleanupPending = false;
          if (kDebugMode) {
            debugPrint(resp.body);
          }
          _checkRemoteTrackingEnded(resp.body);
          return _SendOutcome.accepted;
        }
        // 429/5xx: retry; others: give up
        if (resp.statusCode == 429 ||
            (resp.statusCode >= 500 && resp.statusCode < 600)) {
          // fall through to retry
        } else {
          BootLogger.logBreadcrumb(
            'PackTrack: upload batch REFUSED and discarded '
            '(non-retryable ${resp.statusCode}, ${batch.length} pts)',
          );
          return _SendOutcome.refused;
        }
      } catch (_) {
        // network error -> retry
      }
      attempt++;
      if (attempt >= maxAttempts) {
        // NOT data loss, and the wording matters: this used to say ABANDONED,
        // which reads as "these points are gone". They are not — they stay
        // queued, are mirrored to storage, and ride the next flush. Reviewing
        // the GNH 2026 logs, this line was initially read as 16,798 lost
        // points when it was the same growing queue retried over and over.
        BootLogger.logBreadcrumb(
          'PackTrack: upload failed after $maxAttempts attempts — '
          '${batch.length} pts RETAINED for retry',
        );
        return _SendOutcome.retryLater;
      }
      final backoffMs = 200 * (1 << (attempt - 1));
      await Future.delayed(Duration(milliseconds: backoffMs));
    }
  }
}
