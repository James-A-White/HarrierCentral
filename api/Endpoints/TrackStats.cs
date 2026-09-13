using System;
using System.Collections.Generic;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// What a finished track measures out to: distance, time actually moving,
    /// climb, where it started and ended, and its bounding box.
    ///
    /// Measured ONCE, when the nightly archiver has already decoded the points,
    /// and kept on HC.HasherEventMap (2026-09-13). Nothing server-side knew how
    /// far a track was before this, and a blob of gzipped deltas is not
    /// something SQL can measure on demand.
    ///
    /// Every figure is deliberately conservative: a GPS track is a noisy thing,
    /// and a number that flatters is worse than one that is merely close.
    /// </summary>
    internal sealed class TrackStats
    {
        public int DistanceM { get; init; }
        public int MovingSeconds { get; init; }
        public int ElevationGainM { get; init; }
        public decimal StartLat { get; init; }
        public decimal StartLng { get; init; }
        public decimal EndLat { get; init; }
        public decimal EndLng { get; init; }
        public decimal MinLat { get; init; }
        public decimal MinLng { get; init; }
        public decimal MaxLat { get; init; }
        public decimal MaxLng { get; init; }

        private const double EarthRadiusM = 6371008.8;

        /// <summary>A fix worse than this is a guess, not a position.</summary>
        private const double MaxUsableAccuracyM = 50;

        /// <summary>
        /// Below this speed the hasher is standing at a check, not running, and
        /// the seconds do not count as moving time. 0.5 m/s is a slow walk.
        /// </summary>
        private const double MovingSpeedMps = 0.5;

        /// <summary>
        /// A gap longer than this is a dropout or a pause, not a leg: its
        /// seconds are not counted and neither is the straight line across it,
        /// which would otherwise draw distance through buildings.
        /// </summary>
        private const double MaxLegSeconds = 120;

        /// <summary>
        /// GPS altitude wanders by several metres while standing still. Only
        /// rises bigger than this count, or a flat trail "climbs" a mountain.
        /// </summary>
        private const double MinRealClimbM = 4;

        /// <summary>
        /// Nobody runs at 36 km/h. A leg implying more is a GPS fix that
        /// teleported, or a phone left tracking in a car on the way home —
        /// either way it is not trail, so neither its metres nor its seconds
        /// count.
        ///
        /// Without this the first backfill produced a median of 8.5 km (right)
        /// beside a mean of 22 km and a longest of 8,645 km (a teleport across
        /// the world). Seven tracks over 50 km were dragging every average
        /// (2026-09-13).
        /// </summary>
        private const double MaxLegSpeedMps = 10;

        /// <summary>
        /// Measure a track. Points must be in ascending time order — which is
        /// what the archiver sorts them into and what the codec's deltas
        /// assume. Returns null when there is nothing measurable.
        /// </summary>
        internal static TrackStats? Measure(IReadOnlyList<ArchivedTrackPoint> points)
        {
            if (points == null || points.Count < 2) return null;

            // Only real positions: a typed mark (a photo, a check, the On-Inn)
            // is an annotation rather than a place the hasher was measured, and
            // a fix with terrible accuracy moves the track without them moving.
            List<ArchivedTrackPoint> usable = new(points.Count);
            foreach (ArchivedTrackPoint p in points)
            {
                if (!string.IsNullOrEmpty(p.Type)) continue;
                if (p.Accuracy is double acc && acc > MaxUsableAccuracyM) continue;
                usable.Add(p);
            }
            if (usable.Count < 2) return null;

            double distance = 0;
            double movingSeconds = 0;
            double climb = 0;
            double minLat = usable[0].Latitude, maxLat = minLat;
            double minLng = usable[0].Longitude, maxLng = minLng;
            double? climbReference = usable[0].Altitude;

            for (int i = 1; i < usable.Count; i++)
            {
                ArchivedTrackPoint a = usable[i - 1];
                ArchivedTrackPoint b = usable[i];

                if (b.Latitude < minLat) minLat = b.Latitude;
                if (b.Latitude > maxLat) maxLat = b.Latitude;
                if (b.Longitude < minLng) minLng = b.Longitude;
                if (b.Longitude > maxLng) maxLng = b.Longitude;

                double seconds = (b.TimestampMs - a.TimestampMs) / 1000.0;
                if (seconds <= 0 || seconds > MaxLegSeconds) continue;

                double metres = HaversineMetres(a.Latitude, a.Longitude, b.Latitude, b.Longitude);
                double speed = metres / seconds;
                if (speed > MaxLegSpeedMps) continue;
                distance += metres;
                if (speed >= MovingSpeedMps) movingSeconds += seconds;

                // Climb is measured against the last altitude we BELIEVED, not
                // the previous point, so a long steady ascent still counts
                // while a jittering one does not accumulate.
                if (b.Altitude is double alt && climbReference is double reference)
                {
                    double rise = alt - reference;
                    if (Math.Abs(rise) >= MinRealClimbM)
                    {
                        if (rise > 0) climb += rise;
                        climbReference = alt;
                    }
                }
                else if (b.Altitude is double firstAlt && climbReference is null)
                {
                    climbReference = firstAlt;
                }
            }

            return new TrackStats
            {
                DistanceM = (int)Math.Round(distance),
                MovingSeconds = (int)Math.Round(movingSeconds),
                ElevationGainM = (int)Math.Round(climb),
                StartLat = (decimal)usable[0].Latitude,
                StartLng = (decimal)usable[0].Longitude,
                EndLat = (decimal)usable[^1].Latitude,
                EndLng = (decimal)usable[^1].Longitude,
                MinLat = (decimal)minLat,
                MinLng = (decimal)minLng,
                MaxLat = (decimal)maxLat,
                MaxLng = (decimal)maxLng,
            };
        }

        private static double HaversineMetres(double lat1, double lng1, double lat2, double lng2)
        {
            double p1 = lat1 * Math.PI / 180;
            double p2 = lat2 * Math.PI / 180;
            double dLat = p2 - p1;
            double dLng = (lng2 - lng1) * Math.PI / 180;
            double h = Math.Sin(dLat / 2) * Math.Sin(dLat / 2)
                     + Math.Cos(p1) * Math.Cos(p2) * Math.Sin(dLng / 2) * Math.Sin(dLng / 2);
            return 2 * EarthRadiusM * Math.Asin(Math.Min(1, Math.Sqrt(h)));
        }
    }
}
