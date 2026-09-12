import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/util/track_archive_codec.dart';

/// The fixture is a real production blob (one of Opee's tracks, 328 points,
/// 2,070 bytes) and the expected values are what the API's C# decoder
/// printed for it on 2026-09-12. If this test fails after a codec change on
/// either side, the phone would draw the wrong trail.
void main() {
  final String b64 = File('test/fixtures/track_archive_v1.b64').readAsStringSync();

  test('decodes a production v1 blob exactly as the C# decoder does', () {
    final List<ArchivedTrackPoint> pts = TrackArchiveCodec.decodeBase64(b64);
    expect(pts.length, 328);

    expect(pts[0].timestampMs, 1767399249800);
    expect(pts[0].lat, closeTo(37.32705, 1e-9));
    expect(pts[0].lng, closeTo(-122.01973, 1e-9));
    expect(pts[0].alt, isNull);
    expect(pts[0].acc, 5.0);
    expect(pts[0].type, isNull);

    expect(pts[1].timestampMs, 1767399251056);
    expect(pts[1].lat, closeTo(37.32698, 1e-9));
    expect(pts[1].acc, 10.0);

    expect(pts[2].timestampMs, 1767399253051);
    expect(pts[2].lat, closeTo(37.32691, 1e-9));
    expect(pts[2].lng, closeTo(-122.01973, 1e-9));

    final ArchivedTrackPoint last = pts.last;
    expect(last.timestampMs, 1767483781322);
    expect(last.lat, closeTo(51.50632, 1e-9));
    expect(last.lng, closeTo(-0.05305, 1e-9));
    expect(last.type, 'OIN');

    expect(pts.where((ArchivedTrackPoint p) => p.type != null).length, 7);
    for (int i = 1; i < pts.length; i++) {
      expect(pts[i].timestampMs >= pts[i - 1].timestampMs, isTrue);
    }
  });

  test('refuses an unknown version', () {
    // gzip of a single byte 0x02 (version 2) followed by nothing.
    final List<int> blob = gzip.encode(<int>[2, 0]);
    expect(
      () => TrackArchiveCodec.decode(blob),
      throwsA(isA<TrackArchiveVersionException>()),
    );
  });
}
