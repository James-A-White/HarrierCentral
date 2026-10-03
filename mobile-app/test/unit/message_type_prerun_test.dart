import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// The pre-run push (E5.F1.S10, 2026-10-03) arrives as MessageType 3; an id
/// this build does not know still degrades to chat rather than throwing.
void main() {
  test('3 is the pre-run push', () {
    expect(MessageType.fromId(3), MessageType.preRun);
  });
  test('the existing reminders keep their ids', () {
    expect(MessageType.fromId(1), MessageType.checkinReminder);
    expect(MessageType.fromId(2), MessageType.rsvpReminder);
  });
  test('an unknown id degrades to chat', () {
    expect(MessageType.fromId(99), MessageType.chat);
  });
}
