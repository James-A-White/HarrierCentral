import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// The run card's image (James, 2026-09-26, option B): once the run has
/// started, a chosen cover photo replaces the run image; before, the run
/// image. LH3 #2852 kept its sheep after a cover was chosen.
void main() {
  final DateTime start = DateTime(2026, 9, 26, 12, 0);
  const String img = 'https://x/event.jpg';
  const String cover = 'https://x/cover.jpg';

  String? at(DateTime now, {String? image = img, String? coverUrl = cover}) =>
      runCardImage(
        eventImage: image,
        coverPhotoUrl: coverUrl,
        runStart: start,
        now: now,
      );

  test('before the start: the run image, even with a cover', () {
    expect(at(DateTime(2026, 9, 26, 11, 59)), img);
  });

  test('from the start on: the cover replaces the run image', () {
    expect(at(start), cover);
    expect(at(DateTime(2026, 9, 26, 17, 51)), cover);
    expect(at(DateTime(2026, 10, 3)), cover);
  });

  test('no cover: the run image at any time', () {
    expect(at(DateTime(2026, 9, 26, 18), coverUrl: null), img);
    expect(at(DateTime(2026, 9, 26, 18), coverUrl: ''), img);
  });

  test('cover but no run image: nothing before the start, cover after', () {
    expect(at(DateTime(2026, 9, 26, 9), image: null), isNull);
    expect(at(DateTime(2026, 9, 26, 13), image: null), cover);
  });

  test('neither: no image', () {
    expect(at(DateTime(2026, 9, 26, 13), image: null, coverUrl: null), isNull);
  });
}
