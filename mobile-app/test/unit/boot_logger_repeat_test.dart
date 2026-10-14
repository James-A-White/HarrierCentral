// A widget holding a disposed controller throws on every frame. BootLogger
// keeps the first copies whole and then only counts, so a flood cannot push
// the session's breadcrumbs out of the 100 KB upload (2026-10-14).
import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/util/boot_logger.dart';

void main() {
  final List<String> written = <String>[];
  setUp(() {
    written.clear();
    BootLogger.onErrorPersist = written.add;
  });
  tearDown(() => BootLogger.onErrorPersist = null);

  test('keeps 3 copies whole, then a repeat line at 10 and 100 only', () {
    final StackTrace stack = StackTrace.fromString('#0 a (x.dart:1)\n#1 b');
    for (int i = 0; i < 150; i++) {
      BootLogger.logError('[ERROR][FLUTTER]', StateError('flood'), stack);
    }
    expect(
      written.where(
        (e) => e.contains('[ERROR][FLUTTER]') && !e.contains('repeat'),
      ),
      hasLength(3),
    );
    final List<String> repeats = written
        .where((e) => e.contains('[TRACE] repeat'))
        .toList();
    expect(repeats, hasLength(2));
    expect(repeats[0], contains('x10 '));
    expect(repeats[1], contains('x100 '));
  });

  test('a different error is counted on its own', () {
    final StackTrace stack = StackTrace.fromString('#0 c (y.dart:1)');
    BootLogger.logError('[ERROR][ASYNC]', StateError('other'), stack);
    expect(written, hasLength(1));
  });

  test('a close breadcrumb carries the caller frames', () {
    BootLogger.logControllerClose('TestController x');
    expect(written.single, contains('[TRACE] [CLOSE] TestController x'));
    expect(written.single, contains('boot_logger_repeat_test.dart'));
  });
}
