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

    final persist = onErrorPersist;
    if (persist != null) {
      persist(entry);
    } else {
      _errorBuffer.add(entry);
    }
  }
}
