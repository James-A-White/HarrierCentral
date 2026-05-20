import 'package:harrier_central/data/models/user_positions/user_positions.dart';
import 'package:latlong2/latlong.dart' as latlng;

/// Utility class for filtering and cleaning GPS track points.
///
/// This class identifies and removes inaccurate GPS points based on:
/// - GPS accuracy values (accuracy radius in meters)
/// - Sudden velocity changes (detecting unrealistic jumps)
/// - Time gaps between points (deduplication)
///
/// Multi-stage filtering approach:
/// 1. Pass 1: Filter poor accuracy AND duplicate timestamps
///    - Removes GPS acquisition/loss artifacts (>15m accuracy)
///    - Removes duplicate points (<1000ms apart) that cause velocity spikes
/// 2. Pass 2: Filter unrealistic velocities (>5 m/s)
///    - Checked only between consecutive GOOD points
///    - Prevents cascading failures from already-filtered bad points
/// 3. Interpolation: Replaces filtered points while preserving timestamps
///    - Maintains track continuity
///
/// Key improvements based on real-world data analysis:
/// - Stricter accuracy threshold (15m vs 20m) filters GPS signal issues
/// - Deduplication prevents timing bugs causing 100+ m/s calculations
/// - Two-pass approach prevents one bad point from cascading failures
class TrackPointFilter {
  TrackPointFilter({
    this.maxAccuracyMeters = 15.0,
    this.maxVelocityMetersPerSecond = 5.0,
    this.minTimeDeltaMs = 1000,
  });

  /// Maximum acceptable GPS accuracy in meters.
  /// Points with accuracy > this value are considered unreliable.
  /// Lowered to 15m based on data analysis showing GPS acquisition/loss
  /// periods have 30-50m accuracy causing map artifacts.
  /// Good GPS: ~5m, Acceptable: ~10-15m, Poor GPS: ~30-50m
  final double maxAccuracyMeters;

  /// Maximum realistic velocity in meters per second.
  /// ~5 m/s = ~18 km/h = ~11 mph (fast running)
  /// Based on actual GPS data: 99th percentile is ~4 m/s
  /// Adjust based on your use case (increase for cycling/driving).
  final double maxVelocityMetersPerSecond;

  /// Minimum time delta between points in milliseconds.
  /// Points closer than this are considered duplicates/noise.
  /// Based on data analysis: many duplicate timestamps exist in real data.
  final int minTimeDeltaMs;

  static const latlng.Distance _distanceCalculator = latlng.Distance();

  /// Filters a list of track points, removing inaccurate points and
  /// interpolating between good points.
  List<TrackPoint> filterAndInterpolate(List<TrackPoint> points) {
    if (points.length < 2) return points;

    // Step 1: Mark bad points
    final pointQuality = _evaluatePointQuality(points);

    // Step 2: Filter and interpolate
    return _filterAndInterpolatePoints(points, pointQuality);
  }

  /// Evaluates each point and marks it as good (true) or bad (false).
  List<bool> _evaluatePointQuality(List<TrackPoint> points) {
    final quality = List<bool>.filled(points.length, true);

    // First pass: check accuracy and time deltas
    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      // Check 1: GPS accuracy
      if (point.acc > maxAccuracyMeters) {
        quality[i] = false;
        continue;
      }

      // Check 2: Time delta against previous point (deduplication)
      // Analysis showed timing bugs create 0ms, 1ms, 4ms deltas causing
      // extreme velocity calculations (e.g., 277 m/s from 4ms delta).
      // Filtering these prevents false velocity spikes in Pass 2.
      if (i > 0) {
        final prevPoint = points[i - 1];
        final timeDeltaMs = point.timestampMs - prevPoint.timestampMs;

        // Skip points too close in time (likely duplicates or timing bugs)
        if (timeDeltaMs < minTimeDeltaMs) {
          quality[i] = false;
          continue;
        }
      }
    }

    // Second pass: check velocity against last good point
    int? lastGoodIndex;
    for (int i = 0; i < points.length; i++) {
      if (!quality[i]) continue; // Skip already marked bad points

      if (lastGoodIndex != null) {
        final lastGoodPoint = points[lastGoodIndex];
        final currentPoint = points[i];
        final timeDeltaMs =
            currentPoint.timestampMs - lastGoodPoint.timestampMs;

        if (timeDeltaMs > 0) {
          final distance = _calculateDistance(lastGoodPoint, currentPoint);
          final timeDeltaSeconds = timeDeltaMs / 1000.0;
          final velocity = distance / timeDeltaSeconds;

          if (velocity > maxVelocityMetersPerSecond) {
            quality[i] = false;
            continue;
          }
        }
      }

      lastGoodIndex = i;
    }

    return quality;
  }

  /// Filters bad points and interpolates between good points.
  List<TrackPoint> _filterAndInterpolatePoints(
    List<TrackPoint> points,
    List<bool> quality,
  ) {
    final filtered = <TrackPoint>[];

    // Always keep the first point if we have any points
    if (points.isEmpty) return filtered;

    // Count good points
    final goodPointCount = quality.where((q) => q).length;

    // If we have less than 2 good points, return original data
    // (better to show questionable data than no data)
    if (goodPointCount < 2) return points;

    int? lastGoodIndex;
    for (int i = 0; i < points.length; i++) {
      if (quality[i]) {
        // This is a good point
        if (lastGoodIndex != null && i > lastGoodIndex + 1) {
          // There are bad points between lastGoodIndex and i
          // Interpolate between them
          final interpolated = _interpolateBetween(
            points[lastGoodIndex],
            points[i],
            points.sublist(lastGoodIndex + 1, i),
          );
          filtered.addAll(interpolated);
        }
        filtered.add(points[i]);
        lastGoodIndex = i;
      }
    }

    return filtered;
  }

  /// Interpolates between two good points, replacing bad points in between.
  /// Uses the timestamps from the original bad points to maintain timing.
  List<TrackPoint> _interpolateBetween(
    TrackPoint start,
    TrackPoint end,
    List<TrackPoint> badPoints,
  ) {
    if (badPoints.isEmpty) return [];

    final interpolated = <TrackPoint>[];
    final startTime = start.timestampMs.toDouble();
    final endTime = end.timestampMs.toDouble();
    final totalTimeDelta = endTime - startTime;

    if (totalTimeDelta <= 0) return [];

    for (final badPoint in badPoints) {
      final currentTime = badPoint.timestampMs.toDouble();
      final ratio = ((currentTime - startTime) / totalTimeDelta).clamp(
        0.0,
        1.0,
      );

      final interpolatedLat = start.lat + (end.lat - start.lat) * ratio;
      final interpolatedLng = start.lng + (end.lng - start.lng) * ratio;
      final interpolatedAlt = _interpolateAltitude(start.alt, end.alt, ratio);

      // Use better accuracy (average of start and end)
      final interpolatedAcc = (start.acc + end.acc) / 2.0;

      interpolated.add(
        TrackPoint(
          lat: interpolatedLat,
          lng: interpolatedLng,
          acc: interpolatedAcc,
          alt: interpolatedAlt,
          timestampMs: badPoint.timestampMs,
          type: badPoint.type,
        ),
      );
    }

    return interpolated;
  }

  /// Calculates distance in meters between two points.
  double _calculateDistance(TrackPoint p1, TrackPoint p2) {
    return _distanceCalculator(
      latlng.LatLng(p1.lat, p1.lng),
      latlng.LatLng(p2.lat, p2.lng),
    );
  }

  double? _interpolateAltitude(double? startAlt, double? endAlt, double ratio) {
    if (startAlt == null && endAlt == null) return null;
    if (startAlt == null) return endAlt;
    if (endAlt == null) return startAlt;
    return startAlt + (endAlt - startAlt) * ratio;
  }

  /// Sums the cumulative distance in meters between consecutive points.
  /// Pass the output of [filterAndInterpolate] to get a noise-cleaned distance.
  static double cumulativeDistanceMeters(List<TrackPoint> points) {
    if (points.length < 2) return 0.0;
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += _distanceCalculator(
        latlng.LatLng(points[i - 1].lat, points[i - 1].lng),
        latlng.LatLng(points[i].lat, points[i].lng),
      );
    }
    return total;
  }

  /// Creates a summary of filtering statistics for debugging.
  FilterStats getFilterStats(
    List<TrackPoint> original,
    List<TrackPoint> filtered,
  ) {
    int badAccuracy = 0;
    int badVelocity = 0;
    int tooClose = 0;

    for (int i = 0; i < original.length; i++) {
      final point = original[i];

      if (point.acc > maxAccuracyMeters) {
        badAccuracy++;
      }

      if (i > 0) {
        final prevPoint = original[i - 1];
        final timeDeltaMs = point.timestampMs - prevPoint.timestampMs;

        if (timeDeltaMs < minTimeDeltaMs) {
          tooClose++;
        } else if (timeDeltaMs > 0) {
          final distance = _calculateDistance(prevPoint, point);
          final velocity = distance / (timeDeltaMs / 1000.0);

          if (velocity > maxVelocityMetersPerSecond) {
            badVelocity++;
          }
        }
      }
    }

    return FilterStats(
      originalCount: original.length,
      filteredCount: filtered.length,
      removedCount: original.length - filtered.length,
      badAccuracyCount: badAccuracy,
      badVelocityCount: badVelocity,
      tooCloseCount: tooClose,
    );
  }
}

/// Statistics from filtering operation.
class FilterStats {
  const FilterStats({
    required this.originalCount,
    required this.filteredCount,
    required this.removedCount,
    required this.badAccuracyCount,
    required this.badVelocityCount,
    required this.tooCloseCount,
  });

  final int originalCount;
  final int filteredCount;
  final int removedCount;
  final int badAccuracyCount;
  final int badVelocityCount;
  final int tooCloseCount;

  @override
  String toString() {
    return 'FilterStats(original: $originalCount, filtered: $filteredCount, '
        'removed: $removedCount, badAccuracy: $badAccuracyCount, '
        'badVelocity: $badVelocityCount, tooClose: $tooCloseCount)';
  }
}
