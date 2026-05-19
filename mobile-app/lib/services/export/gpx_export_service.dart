import 'package:harrier_central/imports.dart';

import 'package:path/path.dart' as p;

import 'package:share_plus/share_plus.dart';

class GpxExportService {
  const GpxExportService();

  Future<File> buildGpxFile({
    required UserTrack track,
    required String fileName,
    String? trackName,
  }) async {
    if (track.positions.isEmpty) {
      throw StateError('No track points to export.');
    }

    final sorted = [...track.positions]
      ..sort((a, b) => a.timestampMs.compareTo(b.timestampMs));

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<gpx version="1.1" creator="Harrier Central" xmlns="http://www.topografix.com/GPX/1/1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v2" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">',
    );

    final safeName = _xmlEscape(trackName ?? 'Run');
    buffer.writeln('<metadata><name>$safeName</name></metadata>');

    final waypoints = _extractWaypoints(sorted);
    for (final wp in waypoints) {
      buffer.writeln(
        '<wpt lat="${_fmtCoord(wp.lat)}" lon="${_fmtCoord(wp.lon)}">',
      );
      if (wp.ele != null) {
        buffer.writeln('<ele>${_fmtElevation(wp.ele!)}</ele>');
      }
      buffer.writeln('<time>${_fmtTime(wp.timestampMs)}</time>');
      buffer.writeln('<name>${_xmlEscape(wp.name)}</name>');
      buffer.writeln('<desc>${_xmlEscape(wp.description)}</desc>');
      buffer.writeln('<sym>${_xmlEscape(wp.symbol)}</sym>');
      buffer.writeln('<type>${_xmlEscape(wp.typeLabel)}</type>');
      buffer.writeln('</wpt>');
    }

    buffer.writeln('<trk>');
    buffer.writeln('<name>$safeName</name>');
    buffer.writeln('<trkseg>');

    for (final p in sorted) {
      buffer.writeln(
        '<trkpt lat="${_fmtCoord(p.lat)}" lon="${_fmtCoord(p.lng)}">',
      );
      if (p.alt != null) {
        buffer.writeln('<ele>${_fmtElevation(p.alt!)}</ele>');
      }
      buffer.writeln('<time>${_fmtTime(p.timestampMs)}</time>');
      buffer.writeln('<extensions><gpxtpx:TrackPointExtension>');
      buffer.writeln(
        '<gpxtpx:Accuracy>${_fmtAccuracy(p.acc)}</gpxtpx:Accuracy>',
      );
      buffer.writeln('</gpxtpx:TrackPointExtension></extensions>');
      buffer.writeln('</trkpt>');
    }

    buffer.writeln('</trkseg>');
    buffer.writeln('</trk>');
    buffer.writeln('</gpx>');

    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, fileName));
    await file.writeAsString(buffer.toString(), flush: true);
    return file;
  }

  Future<void> exportTrack({
    required BuildContext context,
    required UserTrack track,
    required String trackName,
  }) async {
    final sanitizedName = _sanitizeFileName(trackName);
    final fileName = '${sanitizedName}_run.gpx';
    final file = await buildGpxFile(
      track: track,
      fileName: fileName,
      trackName: trackName,
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(file.path, mimeType: 'application/gpx+xml', name: fileName),
        ],
        text: 'GPX export for $trackName',
        subject: 'Run GPX export',
      ),
    );

    if (navigatorKey.currentContext != null) {
      _showSnackbar(navigatorKey.currentContext!, 'Shared GPX file: $fileName');
    }
  }

  List<_Waypoint> _extractWaypoints(List<TrackPoint> points) {
    final waypoints = <_Waypoint>[];
    final seen = <String>{};

    for (final point in points) {
      final waypoint = _buildWaypoint(point);
      if (waypoint == null) continue;
      final key =
          '${waypoint.lat}:${waypoint.lon}:${waypoint.timestampMs}:${waypoint.name}';
      if (seen.add(key)) {
        waypoints.add(waypoint);
      }
    }

    return waypoints;
  }

  _Waypoint? _buildWaypoint(TrackPoint point) {
    final rawType = point.type?.trim();
    if (rawType == null || rawType.isEmpty) return null;

    final parts = rawType.split('::');
    final typeKey = parts.first.trim();
    final customLabel = parts.length > 1
        ? parts.sublist(1).join('::').trim()
        : null;

    final HashRunPointTypes? type = HashRunPointTypes.fromKey(typeKey);
    if (type == null) return null; // unknown marker type — skip waypoint

    final name = (customLabel != null && customLabel.isNotEmpty)
        ? customLabel
        : type.label;
    final descriptionBase = type.label;
    final description = (customLabel != null && customLabel.isNotEmpty)
        ? '$descriptionBase — $customLabel'
        : descriptionBase;

    return _Waypoint(
      lat: point.lat,
      lon: point.lng,
      ele: point.alt,
      timestampMs: point.timestampMs,
      name: name,
      description: '$description @ ${_fmtTime(point.timestampMs)}',
      symbol: type.gpxSymbol,
      typeLabel: type.label,
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    final SnackBar snackBar = SnackBar(
      duration: const Duration(seconds: 6),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: ts_titleCondensed,
      ),
      backgroundColor: hc_blue,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String _fmtCoord(double value) => value.toStringAsFixed(6);

  String _fmtElevation(double value) => value.toStringAsFixed(1);

  String _fmtAccuracy(double value) => value.toStringAsFixed(2);

  String _fmtTime(int timestampMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs, isUtc: true);
    return dt.toIso8601String();
  }

  String _xmlEscape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _sanitizeFileName(String raw) {
    final cleaned = raw.isEmpty ? 'run' : raw;
    return cleaned.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
  }
}

class _Waypoint {
  const _Waypoint({
    required this.lat,
    required this.lon,
    required this.timestampMs,
    required this.name,
    required this.description,
    required this.symbol,
    required this.typeLabel,
    this.ele,
  });

  final double lat;
  final double lon;
  final double? ele;
  final int timestampMs;
  final String name;
  final String description;
  final String symbol;
  final String typeLabel;
}
