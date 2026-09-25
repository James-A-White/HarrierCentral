import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// Section headers in the run list: ints 1-4 in front of the first run of
/// each classification (1 mine, 2 nearby, 3 kennels I follow, 4 others).
void main() {
  // Runs are strings like 'r3' (class 3) so the list reads plainly.
  List<dynamic> headed(List<String> runs) {
    final List<dynamic> list = <dynamic>[...runs];
    FutureRunListPageController.insertClassificationHeaders(
      list,
      (dynamic r) => int.parse((r as String).substring(1, 2)),
    );
    return list;
  }

  test('a followed-kennel run last stays under its own header', () {
    // Was [1, 2, 3, 4, 'r3'] — the London Eye run under "All other".
    expect(headed(<String>['r3']), <dynamic>[1, 2, 3, 'r3', 4]);
  });

  test('a list ending in class 4 is laid out as it always was', () {
    expect(headed(<String>['r1a', 'r3a', 'r4a', 'r4b']), <dynamic>[
      1,
      'r1a',
      2,
      3,
      'r3a',
      4,
      'r4a',
      'r4b',
    ]);
  });

  test('empty sections keep their headers, in order', () {
    expect(headed(<String>['r2a']), <dynamic>[1, 2, 'r2a', 3, 4]);
    expect(headed(<String>['r1a', 'r1b']), <dynamic>[1, 'r1a', 'r1b', 2, 3, 4]);
  });

  test('an empty list gets header 1 alone, as before', () {
    expect(headed(<String>[]), <dynamic>[1]);
  });
}
