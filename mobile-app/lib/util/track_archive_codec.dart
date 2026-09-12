import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// One point of an archived PackTrack trail, as the server stored it.
class ArchivedTrackPoint {
  const ArchivedTrackPoint({
    required this.timestampMs,
    required this.lat,
    required this.lng,
    this.alt,
    this.acc,
    this.type,
  });

  final int timestampMs;
  final double lat;
  final double lng;
  final double? alt;
  final double? acc;
  final String? type;
}

/// Thrown when a blob is not a version this app can read. The caller falls
/// back to the server for that run rather than drawing anything.
class TrackArchiveVersionException implements Exception {
  const TrackArchiveVersionException(this.version);
  final int version;
  @override
  String toString() => 'TrackArchiveCodec: unknown version $version';
}

/// Decoder for `HasherEventMap.TrackGzip` — a faithful port of the API's
/// `TrackArchiveCodec.Decode` (E5.F6.S4 / E5.F7.S1). The blob is a gzip
/// stream whose payload is:
///
/// ```
///   byte   version (1)
///   varint pointCount
///   per point, ascending by time:
///     zigzag-varint  Δ timestampMs        (first point: absolute)
///     zigzag-varint  Δ latitude  × 1e5
///     zigzag-varint  Δ longitude × 1e5
///     zigzag-varint  Δ altitude  × 10     (decimetres; 0 = unknown)
///     zigzag-varint  Δ accuracy  × 10     (decimetres; 0 = unknown)
///     varint         type byte length, then that many UTF-8 bytes
/// ```
///
/// Verified against production blobs in `test/track_archive_codec_test.dart`
/// (the C# decoder's output is the expected value). Decode only: the phone
/// never writes an archive.
class TrackArchiveCodec {
  TrackArchiveCodec._();

  static const int version = 1;
  static const double _coordinateScale = 1e5;
  static const double _metreScale = 10;

  /// The sync carries the VARBINARY as base64 text; this is what the local
  /// `trackGzip` column holds.
  static List<ArchivedTrackPoint> decodeBase64(String base64Blob) =>
      decode(base64Decode(base64Blob.trim()));

  static List<ArchivedTrackPoint> decode(List<int> blob) {
    final Uint8List raw = Uint8List.fromList(gzip.decode(blob));
    final _Reader r = _Reader(raw);
    final int v = r.byte();
    if (v != version) throw TrackArchiveVersionException(v);
    final int count = r.varint();
    final List<ArchivedTrackPoint> points = <ArchivedTrackPoint>[];
    int ts = 0, lat = 0, lng = 0, alt = 0, acc = 0;
    for (int i = 0; i < count; i++) {
      ts += r.zigzag();
      lat += r.zigzag();
      lng += r.zigzag();
      alt += r.zigzag();
      acc += r.zigzag();
      final int typeLen = r.varint();
      String? type;
      if (typeLen > 0) {
        type = utf8.decode(r.bytes(typeLen));
      }
      points.add(
        ArchivedTrackPoint(
          timestampMs: ts,
          lat: lat / _coordinateScale,
          lng: lng / _coordinateScale,
          alt: alt == 0 ? null : alt / _metreScale,
          acc: acc == 0 ? null : acc / _metreScale,
          type: type,
        ),
      );
    }
    return points;
  }
}

class _Reader {
  _Reader(this._b);
  final Uint8List _b;
  int _p = 0;

  int byte() {
    if (_p >= _b.length) throw const FormatException('TrackArchiveCodec: truncated');
    return _b[_p++];
  }

  /// Unsigned LEB128, as the C# writer emits it (up to 10 bytes for 64 bits).
  int varint() {
    int result = 0;
    int shift = 0;
    while (true) {
      final int b = byte();
      result |= (b & 0x7f) << shift;
      if (b & 0x80 == 0) return result;
      shift += 7;
      if (shift > 63) throw const FormatException('TrackArchiveCodec: varint too long');
    }
  }

  /// Zigzag: (n << 1) ^ (n >> 63) on the way in, so (u >>> 1) ^ -(u & 1) out.
  int zigzag() {
    final int u = varint();
    return (u >>> 1) ^ -(u & 1);
  }

  Uint8List bytes(int n) {
    if (_p + n > _b.length) throw const FormatException('TrackArchiveCodec: truncated type');
    final Uint8List out = Uint8List.sublistView(_b, _p, _p + n);
    _p += n;
    return out;
  }
}
