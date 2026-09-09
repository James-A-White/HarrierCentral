import 'package:harrier_central/imports.dart';

/// Byte counters for the app's OWN HTTP traffic — every stored-procedure call
/// through [ServiceCommon], PackTrack position uploads and polls, and the log
/// upload itself. Read by [DeviceMetricsService] and written into the
/// `[METRICS]` lines of the session log.
///
/// What it does NOT see: image downloads (cached_network_image talks to the
/// blob store directly), map tiles, and push traffic. On Android the
/// `dev_rx`/`dev_tx` figures in the same line come from `TrafficStats` and
/// cover everything the process sent; iOS offers no per-app counter, so on
/// iOS these app-layer numbers are the only ones there are (MetricKit's daily
/// `networkTransferMetrics` payload is the other source, one day late).
///
/// Counts are per process lifetime, exactly like the session log they end up
/// in. Counting is a couple of integer adds per request; the utf8 encode of
/// the body is the only real work and bodies are small except position
/// batches, which are counted once per flush.
class NetworkMeter {
  NetworkMeter._();

  static int txBytes = 0;
  static int rxBytes = 0;
  static int requests = 0;
  static int failures = 0;

  /// Count a request body about to be sent.
  static void countRequest(String body) {
    txBytes += utf8.encode(body).length;
    requests++;
  }

  /// Count a response that came back. Failures are HTTP >= 400 and the
  /// locally synthesised 500/599 that [ServiceCommon] produces on transport
  /// failure or timeout, so `fail` in the metrics line means "did not get an
  /// answer", whatever the reason.
  static void countResponse(Response response) {
    rxBytes += response.bodyBytes.length;
    if (response.statusCode >= 400) failures++;
  }

  /// `app_tx=12.3KB app_rx=1.1MB req=41 fail=0`
  static String summary() =>
      'app_tx=${formatBytes(txBytes)} app_rx=${formatBytes(rxBytes)} '
      'req=$requests fail=$failures';

  /// Human-scale bytes: `812B`, `12.3KB`, `1.1MB`, `2.0GB`. `-1` → `n/a`.
  static String formatBytes(int bytes) {
    if (bytes < 0) return 'n/a';
    if (bytes < 1024) return '${bytes}B';
    final double kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)}KB';
    final double mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)}MB';
    return '${(mb / 1024).toStringAsFixed(1)}GB';
  }
}
