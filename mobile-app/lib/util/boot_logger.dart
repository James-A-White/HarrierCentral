import 'dart:io';

import 'package:flutter/foundation.dart';

/// Session error log for debug harvesting.
///
/// When [BoolPrefsEnum.debugHarvestEnabled] is set, AppBootService wires up
/// [onErrorPersist] after initPrefs(). Until then, errors accumulate in
/// [_errorBuffer] and are drained (or discarded) by [AppBootService._startErrorPersistence].
class BootLogger {
  BootLogger._();

  // Errors accumulated before AppBootService wires up the pref callback.
  static final List<String> _errorBuffer = [];

  // Set by AppBootService after initPrefs() completes, only when
  // debugHarvestEnabled is true. Once set, new errors are written directly
  // to the pref rather than buffered in memory.
  static Function(String entry)? onErrorPersist;

  static List<String> get pendingErrorEntries =>
      List.unmodifiable(_errorBuffer);

  static void clearErrorBuffer() => _errorBuffer.clear();

  /// Log an unexpected exception. Prints to the debug console and either
  /// persists to the shared pref (if the harvest callback is wired) or
  /// buffers in memory until AppBootService decides whether to drain it.
  static void logError(String tag, Object error, StackTrace? stack) {
    final timestamp = DateTime.now().toIso8601String();
    final frames = stack
        ?.toString()
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .take(8)
        .join('\n');
    final entry =
        '[$timestamp] $tag $error${frames != null ? '\n$frames' : ''}';
    debugPrint(entry);

    _record(entry);
  }

  /// Record a non-error breadcrumb (a lifecycle/state marker) into the same
  /// harvest stream as [logError], tagged `[TRACE]` and with no stack trace so
  /// it stays out of error greps. Use this to trace what the app was doing just
  /// before a crash that leaves NO Dart stack — e.g. an iOS background-location
  /// watchdog kill or an out-of-memory termination during live tracking. Only
  /// persisted when debug harvest is enabled, exactly like [logError].
  static void logBreadcrumb(String message) {
    final entry = '[${DateTime.now().toIso8601String()}] [TRACE] $message';
    debugPrint(entry);
    _record(entry);
  }

  /// Compact memory footprint of the app process, e.g. `rss=142MB peak=180MB`.
  /// RSS (resident set size) is what climbs before an iOS out-of-memory (jetsam)
  /// kill, so attaching it to tracking breadcrumbs shows the trend leading up to
  /// a crash. This is the app's *usage*, not device-free memory (that needs a
  /// native `os_proc_available_memory` channel). Returns `mem=n/a` if the
  /// platform doesn't expose it.
  static String memInfo() {
    try {
      final rssMb = (ProcessInfo.currentRss / (1024 * 1024)).round();
      final peakMb = (ProcessInfo.maxRss / (1024 * 1024)).round();
      return 'rss=${rssMb}MB peak=${peakMb}MB';
    } catch (_) {
      return 'mem=n/a';
    }
  }

  static void _record(String entry) {
    final persist = onErrorPersist;
    if (persist != null) {
      persist(entry);
    } else {
      _errorBuffer.add(entry);
    }
  }
}
