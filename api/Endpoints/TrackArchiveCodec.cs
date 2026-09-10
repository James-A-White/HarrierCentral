using System.IO.Compression;
using System.Text;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// One point of a runner's track as archived on their HC.HasherEventMap row.
    /// </summary>
    public sealed record ArchivedTrackPoint(
        long TimestampMs,
        double Latitude,
        double Longitude,
        double? Altitude,
        double? Accuracy,
        string? Type);

    /// <summary>
    /// Encodes a runner's track into the compact gzipped form stored in
    /// HC.HasherEventMap.TrackGzip (E5.F6.S4), and decodes it back.
    ///
    /// Format, version 1 — a gzip stream whose payload is:
    /// <code>
    ///   byte   version (1)
    ///   varint pointCount
    ///   per point, in ascending timestamp order:
    ///     zigzag-varint  Δ timestampMs        (first point: absolute)
    ///     zigzag-varint  Δ latitude  × 1e5    (first point: absolute)
    ///     zigzag-varint  Δ longitude × 1e5    (first point: absolute)
    ///     zigzag-varint  Δ altitude  × 10     (decimetres; 0 when unknown)
    ///     zigzag-varint  Δ accuracy  × 10     (decimetres; 0 when unknown)
    ///     varint         type byte length, then that many UTF-8 bytes (0 = no type)
    /// </code>
    /// Coordinates are already stored to 5 decimal places (≈1.1 m), so the
    /// integer scaling loses nothing. Consecutive points differ by a few metres
    /// and a few seconds, so every delta fits in one or two bytes before gzip
    /// squeezes the repetition further. A type string ("CHK", "OIN",
    /// "I-400.png::historic icehouse") travels verbatim so a replay can redraw
    /// every mark; a track without its marks cannot redraw the run.
    ///
    /// The version byte is the escape hatch: a reader that sees a version it
    /// does not know must refuse rather than guess.
    /// </summary>
    public static class TrackArchiveCodec
    {
        public const byte Version = 1;
        private const double CoordinateScale = 100_000.0;  // 1e-5 degrees
        private const double MetreScale = 10.0;            // decimetres

        public static byte[] Encode(IReadOnlyList<ArchivedTrackPoint> points)
        {
            using var raw = new MemoryStream();
            raw.WriteByte(Version);
            WriteVarint(raw, (ulong)points.Count);

            long prevTs = 0, prevLat = 0, prevLng = 0, prevAlt = 0, prevAcc = 0;
            foreach (ArchivedTrackPoint p in points)
            {
                long lat = (long)Math.Round(p.Latitude * CoordinateScale);
                long lng = (long)Math.Round(p.Longitude * CoordinateScale);
                long alt = p.Altitude.HasValue ? (long)Math.Round(p.Altitude.Value * MetreScale) : 0;
                long acc = p.Accuracy.HasValue ? (long)Math.Round(p.Accuracy.Value * MetreScale) : 0;

                WriteZigZag(raw, p.TimestampMs - prevTs);
                WriteZigZag(raw, lat - prevLat);
                WriteZigZag(raw, lng - prevLng);
                WriteZigZag(raw, alt - prevAlt);
                WriteZigZag(raw, acc - prevAcc);

                byte[] type = string.IsNullOrEmpty(p.Type) ? Array.Empty<byte>() : Encoding.UTF8.GetBytes(p.Type);
                WriteVarint(raw, (ulong)type.Length);
                raw.Write(type, 0, type.Length);

                prevTs = p.TimestampMs; prevLat = lat; prevLng = lng; prevAlt = alt; prevAcc = acc;
            }

            using var packed = new MemoryStream();
            using (var gzip = new GZipStream(packed, CompressionLevel.SmallestSize, leaveOpen: true))
            {
                raw.Position = 0;
                raw.CopyTo(gzip);
            }
            return packed.ToArray();
        }

        public static List<ArchivedTrackPoint> Decode(byte[] blob)
        {
            using var packed = new MemoryStream(blob);
            using var gzip = new GZipStream(packed, CompressionMode.Decompress);
            using var raw = new MemoryStream();
            gzip.CopyTo(raw);
            raw.Position = 0;

            int version = raw.ReadByte();
            if (version != Version)
            {
                throw new InvalidDataException($"TrackArchiveCodec: unknown version {version}.");
            }
            int count = checked((int)ReadVarint(raw));
            var points = new List<ArchivedTrackPoint>(count);

            long ts = 0, lat = 0, lng = 0, alt = 0, acc = 0;
            for (int i = 0; i < count; i++)
            {
                ts += ReadZigZag(raw);
                lat += ReadZigZag(raw);
                lng += ReadZigZag(raw);
                alt += ReadZigZag(raw);
                acc += ReadZigZag(raw);
                int typeLen = checked((int)ReadVarint(raw));
                string? type = null;
                if (typeLen > 0)
                {
                    byte[] typeBytes = new byte[typeLen];
                    int read = raw.Read(typeBytes, 0, typeLen);
                    if (read != typeLen) throw new InvalidDataException("TrackArchiveCodec: truncated type.");
                    type = Encoding.UTF8.GetString(typeBytes);
                }
                points.Add(new ArchivedTrackPoint(
                    ts,
                    lat / CoordinateScale,
                    lng / CoordinateScale,
                    alt == 0 ? null : alt / MetreScale,
                    acc == 0 ? null : acc / MetreScale,
                    type));
            }
            return points;
        }

        // --- varint plumbing (protobuf-style LEB128 with zigzag for signed values) ---

        private static void WriteVarint(Stream s, ulong value)
        {
            while (value >= 0x80)
            {
                s.WriteByte((byte)(value | 0x80));
                value >>= 7;
            }
            s.WriteByte((byte)value);
        }

        private static ulong ReadVarint(Stream s)
        {
            ulong result = 0;
            int shift = 0;
            while (true)
            {
                int b = s.ReadByte();
                if (b < 0) throw new InvalidDataException("TrackArchiveCodec: truncated varint.");
                result |= (ulong)(b & 0x7F) << shift;
                if ((b & 0x80) == 0) return result;
                shift += 7;
                if (shift > 63) throw new InvalidDataException("TrackArchiveCodec: varint too long.");
            }
        }

        private static void WriteZigZag(Stream s, long value) =>
            WriteVarint(s, (ulong)((value << 1) ^ (value >> 63)));

        private static long ReadZigZag(Stream s)
        {
            ulong u = ReadVarint(s);
            return (long)(u >> 1) ^ -(long)(u & 1);
        }
    }
}
