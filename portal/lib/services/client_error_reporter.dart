import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:hcportal/queries/client_error_query.dart';

/// The portal's client-side error telemetry — installed once, in `main()`,
/// before `runApp`.
///
/// Until 2026-09-23 the portal had none: no `FlutterError.onError`, no zone
/// handler, no upload. Seventy-seven catch blocks, thirty-one of them empty
/// or print-only, and an exception anywhere else went to the browser console
/// of the one person who hit it. The app writes a session log and the public
/// web posts to /api/web-error; this is the portal's equivalent, into the
/// same HC.ErrorLog the sweep and the Usage Data dashboard already read.
///
/// Two handlers cover the two ways an error surfaces in Flutter:
///  * `FlutterError.onError` — framework errors: build, layout, paint, and
///    anything a widget threw. Debug behaviour (the red box, the console
///    dump) is kept by chaining the previous handler.
///  * `PlatformDispatcher.instance.onError` — everything else: an unawaited
///    future, a timer, a stream. Returning true tells Flutter it is handled,
///    which stops the web engine printing it and moving on silently.
///
/// Throttled: 20 reports per page load, and an identical message is not
/// sent twice within five minutes. A rebuild loop throws the same error many
/// times a second, and forty copies of one row tell us nothing thirty-nine
/// of them did not.
class ClientErrorReporter {
  ClientErrorReporter._();

  static const int _maxPerSession = 20;
  static const Duration _dedupeWindow = Duration(minutes: 5);

  static int _sent = 0;
  static final Map<String, DateTime> _lastSeen = <String, DateTime>{};
  static String _version = 'unknown';
  static bool _installed = false;

  static void install() {
    if (_installed) return;
    _installed = true;

    // Not awaited: the handlers must be in place before the first frame, and
    // the version can arrive whenever it arrives.
    unawaited(_loadVersion());

    final FlutterExceptionHandler? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      previous?.call(details);
      report(details.exception, details.stack, source: 'portal-flutter');
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      report(error, stack, source: 'portal-async');
      return true;
    };
  }

  /// Report an error caught by hand. Use this from a `catch` that would
  /// otherwise be silent — it is the portal's `BootLogger.logError`.
  static void report(Object error, StackTrace? stack, {String source = 'portal-client'}) {
    try {
      final String name = _oneLine(error.toString());
      if (name.isEmpty) return;

      final DateTime now = DateTime.now();
      final DateTime? seen = _lastSeen[name];
      if (seen != null && now.difference(seen) < _dedupeWindow) return;
      if (_sent >= _maxPerSession) return;
      _lastSeen[name] = now;
      _sent++;

      final String frames = (stack?.toString() ?? '')
          .split('\n')
          .where((String l) => l.trim().isNotEmpty)
          .take(12)
          .join('\n');

      // Fire and forget. sendClientError never throws.
      unawaited(sendClientError(
        errorName: name,
        errorDescription: frames,
        source: source,
        appVersion: _version,
        route: _currentRoute(),
      ));
    } catch (_) {
      // A failure in the reporter must never reach the handlers that call it.
    }
  }

  static Future<void> _loadVersion() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      _version = '${info.version}+${info.buildNumber}';
    } catch (_) {
      // 'unknown' is fine; the report still lands.
    }
  }

  static String _oneLine(String s) {
    final String first = s.split('\n').first.trim();
    return first.length > 500 ? first.substring(0, 500) : first;
  }

  static String? _currentRoute() {
    try {
      return Uri.base.fragment.isNotEmpty ? Uri.base.fragment : Uri.base.path;
    } catch (_) {
      return null;
    }
  }
}
