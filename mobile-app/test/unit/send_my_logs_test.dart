// "Send my logs" in the Beta Testers room (E18.F9, 2026-10-14): the room
// check that decides where the button appears, and the shape of the upload,
// which must match the next-boot harvest so the sweep reads both alike.
import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

void main() {
  group('isBetaTestersRoom', () {
    test('room 8 is the Beta Testers room', () {
      expect(kBetaTestersRoomType, 8);
      expect(isBetaTestersRoom(8), isTrue);
    });

    test('every other room, and a thread with no room, is not', () {
      for (final int room in <int>[0, 1, 2, 3, 4, 5, 6, 7, 9, 10]) {
        expect(isBetaTestersRoom(room), isFalse, reason: 'room $room');
      }
      expect(isBetaTestersRoom(null), isFalse);
    });
  });

  group('AppBootService.composeSessionLogUpload', () {
    const String marker = '[t] [TRACE] === Send my logs ===';

    test('nothing persisted sends nothing (harvest off)', () {
      expect(
        AppBootService.composeSessionLogUpload(
          errors: '',
          series: '',
          marker: marker,
        ),
        isEmpty,
      );
    });

    test('breadcrumbs, metrics ring, marker — joined like the boot upload', () {
      expect(
        AppBootService.composeSessionLogUpload(
          errors: 'a\n===\nb',
          series: '[s] [METRICS:RING] rows=1',
          marker: marker,
        ),
        'a\n===\nb\n===\n[s] [METRICS:RING] rows=1\n===\n$marker',
      );
    });

    test('a missing block is left out, not sent as an empty section', () {
      expect(
        AppBootService.composeSessionLogUpload(
          errors: 'a',
          series: '',
          marker: marker,
        ),
        'a\n===\n$marker',
      );
      expect(
        AppBootService.composeSessionLogUpload(
          errors: '',
          series: 'ring',
          marker: marker,
        ),
        'ring\n===\n$marker',
      );
    });
  });
}
