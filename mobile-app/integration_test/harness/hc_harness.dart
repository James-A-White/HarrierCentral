// Shared helpers for the on-device walk-through tests.
//
// Run (simulator UDID from `xcrun simctl list devices`):
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/screens_test.dart -d <udid> \
//     --dart-define=HC_TEST_INVITE_CODE=URC:…    # first run on a fresh install only
//
// The app talks to the real server. The invite code is only needed when the
// simulator is not yet signed in; once a device is authorised it stays so.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show FlutterExceptionHandler;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/main.dart' as app;
import 'package:harrier_central/util/constants.dart' show kUiTest;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

/// Every framework error raised while a screen was open, keyed by the screen.
/// GetX's "improper use" is one of these: it is thrown from an Obx build and
/// reaches FlutterError.onError, so it lands here with the screen's name.
class ErrorLedger {
  final List<({String screen, String error})> entries = [];
  String screen = 'boot';

  void record(FlutterErrorDetails d) {
    entries.add((screen: screen, error: d.exceptionAsString()));
    debugPrint('[HARNESS][$screen] ${d.exceptionAsString()}');
    // Where it came from: the "relevant error-causing widget" node carries
    // the source location in debug builds (e.g. Row ... lib/x.dart:123:9),
    // which is what makes an overflow report actionable.
    final String where = d
        .toString()
        .split('\n')
        .where((String t) => t.contains('.dart:') && t.contains('lib/'))
        .map((String t) => t.trim())
        .toSet()
        .join(' | ');
    if (where.isNotEmpty) debugPrint('[HARNESS-AT][$screen] $where');
  }

  String report() {
    if (entries.isEmpty) return 'no framework errors';
    final b = StringBuffer('${entries.length} framework error(s):\n');
    for (final e in entries) {
      b.writeln('  [${e.screen}] ${e.error.split('\n').first}');
    }
    return b.toString();
  }
}

class Harness {
  Harness(this.tester, this.binding);

  final WidgetTester tester;
  final IntegrationTestWidgetsFlutterBinding binding;
  final ErrorLedger ledger = ErrorLedger();
  int _shotIndex = 0;
  FlutterExceptionHandler? _originalOnError;
  Directory? _shotDir;

  /// Boots the real app. Errors are collected, not rethrown, so one broken
  /// screen does not end the walk; the test asserts the ledger at the end.
  Future<void> launch() async {
    _originalOnError = FlutterError.onError;
    FlutterError.onError = ledger.record;
    // Screenshots are also written inside the app's container as they are
    // taken, so a run that dies early still leaves evidence:
    //   xcrun simctl get_app_container <udid> com.harriercentral.app data
    try {
      final Directory docs = await getApplicationDocumentsDirectory();
      _shotDir = Directory('${docs.path}/walk')..createSync(recursive: true);
      for (final FileSystemEntity f in _shotDir!.listSync()) {
        f.deleteSync();
      }
    } catch (e) {
      debugPrint('[HARNESS] no in-app screenshot dir: $e');
    }
    debugPrint('[HARNESS] kUiTest=$kUiTest (HC_UI_TEST define reached the app build)');
    await app.main();
    // main() wraps whatever onError it found (ours) and calls it — keep it.
    await settle(const Duration(seconds: 3));
  }

  /// Hands FlutterError.onError back to the test framework. Call before the
  /// final expect(): the binding asserts if a test leaves it overridden.
  void restoreErrorHandler() {
    FlutterError.onError = _originalOnError;
  }

  /// Pumps real frames for [d]. pumpAndSettle cannot be used: spinners,
  /// the map and the location stream never settle.
  Future<void> settle(Duration d) async {
    final DateTime end = DateTime.now().add(d);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Pumps until [finder] matches, or fails after [timeout].
  Future<Finder> waitFor(
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
    String? what,
  }) async {
    final DateTime end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) return finder;
    }
    await shot('timeout_${what ?? finder.toString()}');
    throw TestFailure('Timed out waiting for ${what ?? finder}');
  }

  /// True if [finder] shows up within [timeout]; never throws.
  Future<bool> appears(
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final DateTime end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  Future<void> tap(Finder finder, {String? what}) async {
    await waitFor(finder, what: what);
    // A button below the fold is found but not hit; scroll it into view.
    try {
      await tester.ensureVisible(finder.first);
      await settle(const Duration(milliseconds: 300));
    } catch (_) {}
    await tester.tap(finder.first, warnIfMissed: false);
    await settle(const Duration(milliseconds: 600));
  }

  Future<void> tapText(String text) =>
      tap(find.text(text, skipOffstage: false), what: 'text "$text"');

  Future<void> tapIcon(IconData icon) =>
      tap(find.byIcon(icon), what: 'icon $icon');

  Future<void> enterText(Finder field, String text) async {
    await waitFor(field, what: 'text field');
    await tester.enterText(field.first, text);
    await settle(const Duration(milliseconds: 300));
  }

  Future<void> back() async {
    final NavigatorState nav = tester.state(find.byType(Navigator).first);
    if (nav.canPop()) nav.pop();
    await settle(const Duration(milliseconds: 800));
  }

  /// Names the screen for the ledger and takes a screenshot.
  Future<void> screen(String name) async {
    ledger.screen = name;
    await settle(const Duration(milliseconds: 500));
    await shot(name);
  }

  Future<void> shot(String name) async {
    _shotIndex++;
    final String safe = name.replaceAll(RegExp(r'[^A-Za-z0-9_]+'), '_');
    final String file = '${_shotIndex.toString().padLeft(2, '0')}_$safe';
    try {
      // Rendered in-process from the root repaint boundary: no driver round
      // trip and no platform channel, so a native alert cannot hang it. It
      // shows the Flutter layer only, which is what the walk is about.
      // The whole render tree, overlays and dialogs included.
      final RenderView view = tester.binding.renderViews.first;
      final OffsetLayer layer = view.debugLayer! as OffsetLayer;
      final ui.Image image = await layer.toImage(view.paintBounds, pixelRatio: 1.0);
      final ByteData? png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (png == null) throw StateError('no png bytes');
      final Uint8List bytes = png.buffer.asUint8List();
      _shotDir?.let((Directory d) => File('${d.path}/$file.png').writeAsBytesSync(bytes));
      // Also hand it to the driver so it lands in integration_test/screenshots/.
      binding.reportData ??= <String, dynamic>{};
      (binding.reportData!['screenshots'] ??= <dynamic>[]).add(<String, dynamic>{
        'screenshotName': file,
        'bytes': bytes,
      });
    } catch (e) {
      debugPrint('[HARNESS] screenshot $name failed: $e');
    }
  }
}
