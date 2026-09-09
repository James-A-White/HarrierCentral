import 'package:harrier_central/imports.dart';

/// Byte and latency counters for the app's OWN HTTP traffic — every stored-procedure call
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
  static int _latencySumMs = 0;
  static int _latencyMaxMs = 0;
  static int _latencyCount = 0;

  /// Count a request body about to be sent. Returns the start time to hand
  /// back to [end], so latency is measured around the whole exchange.
  static int begin(String body) {
    txBytes += utf8.encode(body).length;
    requests++;
    return DateTime.now().millisecondsSinceEpoch;
  }

  /// Count the outcome of a request begun with [begin]. Pass the response, or
  /// `null` when the call threw (timeout, transport failure). Failures are
  /// HTTP >= 400, the locally synthesised 500/599 that [ServiceCommon]
  /// produces, and thrown exceptions — so `fail` means "did not get a usable
  /// answer", whatever the reason. Latency is recorded for every outcome, so
  /// a stalled network shows up in `max` rather than vanishing.
  static void end(int startedMs, Response? response) {
    final int ms = DateTime.now().millisecondsSinceEpoch - startedMs;
    _latencySumMs += ms;
    _latencyCount++;
    if (ms > _latencyMaxMs) _latencyMaxMs = ms;
    if (response == null) {
      failures++;
      return;
    }
    rxBytes += response.bodyBytes.length;
    if (response.statusCode >= 400) failures++;
  }

  /// `app_tx=12.3KB app_rx=1.1MB req=41 fail=0 lat_avg=420ms lat_max=8.2s`
  static String summary() {
    final String avg = _latencyCount == 0
        ? 'n/a'
        : _fmtMs(_latencySumMs ~/ _latencyCount);
    final String max = _latencyCount == 0 ? 'n/a' : _fmtMs(_latencyMaxMs);
    return 'app_tx=${formatBytes(txBytes)} app_rx=${formatBytes(rxBytes)} '
        'req=$requests fail=$failures lat_avg=$avg lat_max=$max';
  }

  static String _fmtMs(int ms) =>
      ms < 1000 ? '${ms}ms' : '${(ms / 1000).toStringAsFixed(1)}s';

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
