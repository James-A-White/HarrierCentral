import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

// A file in the exact shape GpxExportService writes: marks as <wpt> whose
// <type> is the mark's label (with its emoji; the Caution one below has had
// them stripped by a re-save) and <name> the label or custom text, track
// points with our accuracy extension, all times in UTC.
const String _hcExport = '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="Harrier Central" xmlns="http://www.topografix.com/GPX/1/1" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v2">
<metadata><name>Test run</name></metadata>
<wpt lat="55.950100" lon="-3.190100"><ele>60.0</ele><time>2026-09-06T08:00:30Z</time><name>⭕️ Check ⭕️</name><desc>Check @ …</desc><sym>Flag</sym><type>⭕️ Check ⭕️</type></wpt>
<wpt lat="55.950500" lon="-3.190500"><ele>60.0</ele><time>2026-09-06T08:01:30Z</time><name>watch the road</name><desc>Caution — watch the road</desc><sym>Danger</sym><type>Caution</type></wpt>
<wpt lat="55.950900" lon="-3.190900"><ele>60.0</ele><time>2026-09-06T08:02:00Z</time><name>Somebody's photo</name><sym>Photo</sym><type>Photo</type></wpt>
<wpt lat="55.951000" lon="-3.191000"><ele>60.0</ele><time>2026-09-06T08:02:30Z</time><name>Strava segment start</name><type>Segment</type></wpt>
<trk><name>Test run</name><trkseg>
<trkpt lat="55.950000" lon="-3.190000"><ele>60.0</ele><time>2026-09-06T08:00:00Z</time><extensions><gpxtpx:TrackPointExtension><gpxtpx:Accuracy>4.20</gpxtpx:Accuracy></gpxtpx:TrackPointExtension></extensions></trkpt>
<trkpt lat="55.950010" lon="-3.190010"><ele>60.0</ele><time>2026-09-06T08:00:02Z</time></trkpt>
<trkpt lat="55.950100" lon="-3.190100"><ele>61.0</ele><time>2026-09-06T08:00:30Z</time><hdop>1.2</hdop></trkpt>
<trkpt lat="55.950500" lon="-3.190500"><ele>62.0</ele><time>2026-09-06T08:01:30Z</time></trkpt>
<trkpt lat="55.951000" lon="-3.191000"><ele>63.0</ele><time>2026-09-06T08:02:30Z</time></trkpt>
</trkseg></trk></gpx>''';

void main() {
  const GpxImportService svc = GpxImportService();

  test('parses track points and waypoints, UTC, ascending', () {
    final ParsedGpx g = svc.parse(_hcExport);
    expect(g.points.length, 5);
    expect(g.waypoints.length, 4);
    expect(g.firstTimestampMs, DateTime.utc(2026, 9, 6, 8).millisecondsSinceEpoch);
    expect(g.lastTimestampMs, DateTime.utc(2026, 9, 6, 8, 2, 30).millisecondsSinceEpoch);
    expect(g.points.first.accuracy, 4.2);
    expect(g.points[2].hdop, 1.2);
  });

  test('a time without a zone is read as UTC, not phone-local', () {
    final ParsedGpx g = svc.parse(
      _hcExport.replaceAll('2026-09-06T08:00:00Z', '2026-09-06T08:00:00'),
    );
    expect(g.points.first.timestampMs, DateTime.utc(2026, 9, 6, 8).millisecondsSinceEpoch);
  });

  test('thins to the app cadence, keeps first and last, ends with On Inn', () {
    final ParsedGpx g = svc.parse(_hcExport);
    final List<UserEventLocation> out = svc.buildPoints(g);
    final List<UserEventLocation> gps = out.where((p) => p.type == null).toList();
    // The second point is ~1 m and 2 s after the first: thinned away.
    expect(gps.length, 4);
    expect(gps.first.lat, 55.95);
    expect(gps.last.lat, 55.951);
    // Ends with an On Inn one second after the last point.
    expect(out.last.type, 'OIN');
    expect(int.parse(out.last.ts), g.lastTimestampMs + 1000);
    // Accuracy: ours round-trips, hdop converts, default fills the rest.
    expect(gps[0].acc, 4.2);
    expect(gps[1].acc, 6.0); // hdop 1.2 × 5
    expect(gps[2].acc, GpxImportService.defaultAccuracyMeters);
  });

  test('our waypoints come back as marks; photos and foreign ones do not', () {
    final ParsedGpx g = svc.parse(_hcExport);
    final List<String?> marks = svc
        .buildPoints(g)
        .map((p) => p.type)
        .where((t) => t != null && t != 'OIN')
        .toList();
    expect(marks, <String>['CHK', 'CAU::watch the road']);
  });

  test('rejects a file whose points carry no time', () {
    final String noTimes = _hcExport.replaceAll(RegExp(r'<time>[^<]*</time>'), '');
    expect(
      () => svc.parse(noTimes),
      throwsA(isA<GpxImportException>().having((e) => e.message, 'message', contains('no timestamps'))),
    );
  });

  test('rejects something that is not GPX', () {
    expect(() => svc.parse('<html></html>'), throwsA(isA<GpxImportException>()));
    expect(() => svc.parse('not xml at all <'), throwsA(isA<GpxImportException>()));
  });
}
