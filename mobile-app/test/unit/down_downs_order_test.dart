import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// Down Downs display order: pending first, then cancelled, then done, and
/// oldest first within each band. Lived in a State's sort callback until
/// 2026-09-23; now DownDownsController.ordered, a pure function.
void main() {
  DownDownModel dd(
    String id, {
    bool done = false,
    bool cancelled = false,
    int minute = 0,
  }) => DownDownModel(
    downDownId: id,
    chargeText: id,
    isDone: done,
    isCancelled: cancelled,
    createdByDisplayName: 'RA',
    createdAt: DateTime(2026, 1, 1).add(Duration(minutes: minute)),
  );

  test('pending, then cancelled, then done; oldest first within a band', () {
    final out = DownDownsController.ordered([
      dd('done-early', done: true, minute: 1),
      dd('cancelled', cancelled: true, minute: 2),
      dd('pending-late', minute: 3),
      dd('pending-early', minute: 0),
      dd('done-late', done: true, minute: 9),
    ]);
    expect(out.map((d) => d.downDownId).toList(), <String>[
      'pending-early',
      'pending-late',
      'cancelled',
      'done-early',
      'done-late',
    ]);
  });

  test('does not mutate its input', () {
    final input = [dd('b', minute: 2), dd('a', minute: 1)];
    DownDownsController.ordered(input);
    expect(input.first.downDownId, 'b');
  });
}
