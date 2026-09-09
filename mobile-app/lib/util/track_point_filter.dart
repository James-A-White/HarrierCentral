import 'dart:math' as math;

import 'package:harrier_central/data/models/user_positions/user_positions.dart';
import 'package:latlong2/latlong.dart' as latlng;

/// Utility class for filtering and cleaning GPS track points.
///
/// This class identifies and removes inaccurate GPS points based on:
/// - GPS accuracy values (accuracy radius in meters)
/// - Sudden velocity changes (detecting unrealistic jumps)
/// - Time gaps between points (deduplication)
///
/// Multi-stage approach:
/// 1. Smooth each fix toward its neighbours in proportion to its own
///    uncertainty — an accurate fix is left exactly where it is, a hopeless one
///    is replaced by its neighbourhood's accuracy-weighted mean
/// 2. Pass 1: drop near-duplicate timestamps (<1000ms) that cause velocity spikes
/// 3. Pass 2: drop unrealistic velocities (>5 m/s), measured between consecutive
///    GOOD points so one bad fix cannot cascade
/// 4. Interpolate replacements for dropped points, preserving their timestamps
///
/// Smoothing replaced a hard accuracy gate on 2026-08-30 — see
/// [filterAndInterpolate] for the run that forced it. Photo marks are held aside
/// for the whole pipeline; every other typed mark is left exactly where the
/// hasher dropped it.
class TrackPointFilter {
  TrackPointFilter({
    this.maxAccuracyMeters = 50.0,
    this.maxVelocityMetersPerSecond = 5.0,
    this.minTimeDeltaMs = 1000,
  });

  /// DEPRECATED as a gate — retained so existing callers still compile.
  ///
  /// Dropping every fix worse than this was replaced by uncertainty-weighted
  /// smoothing on 2026-08-30. A fixed gate assumes a quality of GPS the device
  /// may simply not be providing, and when it isn't the gate deletes the run
  /// rather than cleaning it. See [filterAndInterpolate].
  /// Good GPS: ~5m, Balanced: ~10-15m, Low Power: ~30-50m, Indoor/poor: >50m
  final double maxAccuracyMeters;

  /// At or below this accuracy a fix is trusted completely and never moved.
  static const double smoothTrustMeters = 20.0;

  /// At or above this accuracy a fix is replaced by its neighbourhood entirely.
  static const double smoothFullMeters = 80.0;

  /// Neighbours either side included in the weighted mean.
  static const int smoothWindow = 4;

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
  ///
  /// Photo marks carry the PHOTO's coordinates, not the runner's — an imported
  /// shot sits wherever the photographer was standing — so they are held aside
  /// and merged back afterwards. They must not anchor the velocity check or an
  /// interpolation.
  ///
  /// Without this a single off-trail photo poisons the track twice over. It is
  /// typed, so it is never dropped and becomes the velocity reference; the next
  /// GENUINE fixes then measure their speed from the photo's location, blow past
  /// [maxVelocityMetersPerSecond] and get dropped; and their interpolated
  /// replacements are strung along a line running out to the photo and back.
  /// Those replacements carry no photo type, so callers that skip photo points
  /// when drawing (see `_isPhotoPoint` in RunTrackerMapController) cannot remove
  /// them and the phantom out-and-back is drawn anyway.
  ///
  /// Kilty, BMPH3 #2060 (2026-08-30): GPS was clean — accuracy p50 8 m, max
  /// 17.6 m — yet one photo 515 m off-trail discarded 25 good fixes and added
  /// 1.09 km of phantom trail (8.83 vs 7.74 km).
  ///
  /// Points are then SMOOTHED toward their neighbours in proportion to their own
  /// uncertainty, replacing the old "drop anything worse than [maxAccuracyMeters]"
  /// gate. Pussy Printer on the same run reported a median accuracy of 67 m, so
  /// 209 of his 312 points were rejected and 101 CONSECUTIVE rejects — 29.7
  /// minutes, over which he actually covered 4.45 km — became a single straight
  /// line 733 m long; his distance read 5.26 km against a pack that ran
  /// 7.2–7.7 km. Smoothing degrades gracefully instead: at full blend a fix is
  /// replaced by its neighbours' accuracy-weighted mean, in which its own weight
  /// (1/acc) is negligible, so a hopeless fix self-corrects rather than punching
  /// a hole. Measured: 5.26 -> 7.80 km, 308 of 312 points kept (was 100), and
  /// all four clean tracks on that run byte-identical.
  ///
  /// Mirrored in public-web `lib/packtrack.ts` — keep the two in step.
  List<TrackPoint> filterAndInterpolate(List<TrackPoint> points) {
    if (points.length < 2) return points;
    // Every mark is held aside, not just photos. A mark's coordinate is
    // never a GPS fix: photos carry the photographer's position, the admin
    // trim boundaries (AST/AEN) carry the event venue, and the rest were
    // one-shot fixes that could be stale. Letting any of them anchor the
    // velocity check or an interpolation bends the track — the GNH Hangover
    // run drew a 507 m straight line out to its official-start marker. The
    // marks come back in timestamp order afterwards, untouched, for the
    // marker layer and the On Inn terminator.
    if (points.any(_isMark)) {
      final List<TrackPoint> marks = points.where(_isMark).toList();
      final List<TrackPoint> fixes =
          points.where((TrackPoint p) => !_isMark(p)).toList();
      return _mergeByTimestamp(_filterTrack(fixes), marks);
    }
    return _filterTrack(points);
  }

  List<TrackPoint> _filterTrack(List<TrackPoint> points) {
    if (points.length < 2) return points;

    // Step 1: Smooth by uncertainty. Velocity and interpolation then work on the
    // smoothed positions, so a noisy fix pulled back into line no longer reads
    // as an impossible sprint and survives instead of being re-invented.
    final smoothed = _smoothByUncertainty(points);

    // Step 2: Mark bad points
    final pointQuality = _evaluatePointQuality(smoothed);

    // Step 3: Filter and interpolate
    final filtered = _filterAndInterpolatePoints(smoothed, pointQuality);

    // Step 4: Collapse the wandering that happens while nobody is moving.
    return _collapseStationary(filtered);
  }

  /// How far a fix may sit from the anchor and still count as "not moving",
  /// when both fixes are confident. Poor fixes get a wider radius — see
  /// [_stationaryRadius].
  static const double stationaryRadiusMeters = 25.0;

  /// Ceiling on the accuracy-widened radius. Without a cap a pair of hopeless
  /// fixes (acc 500 appears in real data) would swallow the whole trail. 60m is
  /// two fixes at 30m each — the edge of usable GPS. Sweeping the GNH 2026
  /// Sunday pack from 25m to 90m, every clean track measured EXACTLY the same
  /// length at every cap; only the noisy tracks moved, and their improvement
  /// stopped at 60.
  static const double stationaryRadiusMaxMeters = 60.0;

  /// How long the runner must stay inside that radius before the stretch is
  /// treated as standing still rather than moving slowly.
  static const int stationaryMinDurationMs = 90 * 1000;

  /// Replaces each stretch where the runner stayed put with a single position
  /// held for the same length of time.
  ///
  /// GPS does not sit still when its owner does. At a beer stop or an On Inn
  /// the fixes keep wandering inside their own error, and every wander is added
  /// to the distance: measuring the GNH 2026 Sunday trail, 0.87 km of the
  /// 15.58 km recorded was accumulated by runners who were not going anywhere —
  /// 5.6% overall and 11.4% for one runner. That is phantom distance on
  /// somebody's run total, and it is the part they notice.
  ///
  /// The stretch is replaced by TWO points, not one: same position, but keeping
  /// the first and last timestamps. Collapsing to a single point would pull the
  /// time axis out from under playback and make the dot skip the pause; keeping
  /// both ends holds the dot where it was for exactly as long as it was there,
  /// while contributing no distance.
  ///
  /// Marks are never absorbed — a stretch breaks at any typed point, so a
  /// CHK/PHO/OIN dropped during the pause keeps its own position and time.
  ///
  /// Trade-off worth knowing: milling around at a check looks identical to this
  /// and will also be flattened. That movement is arguably real, but it is
  /// indistinguishable from jitter at this radius, and counting it means
  /// counting the jitter too.
  List<TrackPoint> _collapseStationary(List<TrackPoint> points) {
    if (points.length < 3) return points;

    final List<TrackPoint> out = <TrackPoint>[];
    int i = 0;
    while (i < points.length) {
      if (_isMark(points[i])) {
        out.add(points[i]);
        i++;
        continue;
      }

      // Extend while every point stays within the radius of where we started
      // and no mark interrupts.
      final TrackPoint anchor = points[i];
      int j = i;
      while (j + 1 < points.length &&
          !_isMark(points[j + 1]) &&
          _calculateDistance(anchor, points[j + 1]) <=
              _stationaryRadius(anchor, points[j + 1])) {
        j++;
      }

      final int spanMs = points[j].timestampMs - anchor.timestampMs;
      if (j > i && spanMs >= stationaryMinDurationMs) {
        // Weight by 1/accuracy, matching _smoothByUncertainty, so the confident
        // fixes decide where the group actually stood.
        double wsum = 0, latSum = 0, lngSum = 0;
        for (int k = i; k <= j; k++) {
          final double a = (points[k].acc <= 0) ? 1.0 : points[k].acc;
          final double w = 1.0 / a;
          wsum += w;
          latSum += points[k].lat * w;
          lngSum += points[k].lng * w;
        }
        final double lat = latSum / wsum;
        final double lng = lngSum / wsum;
        out.add(points[i].copyWith(lat: lat, lng: lng));
        out.add(points[j].copyWith(lat: lat, lng: lng));
        i = j + 1;
      } else {
        out.add(points[i]);
        i++;
      }
    }
    return out;
  }

  /// How far apart two fixes may be and still describe the same spot.
  ///
  /// A fixed 25m radius assumes a quality of GPS the phone may not be
  /// providing. On the GNH 2026 Sunday trail one hasher stood at a check for
  /// twenty minutes on fixes accurate to 60-116m; the readings ping-ponged
  /// between two spots 37m apart, which is well inside their own error but
  /// outside a flat 25m radius. The stretch was never recognised as a pause, so
  /// roughly half a kilometre of standing still was added to their distance.
  ///
  /// Two fixes describe the same place when their error circles overlap, so the
  /// radius is the sum of the two accuracies — floored at
  /// [stationaryRadiusMeters] so confident fixes behave exactly as before, and
  /// capped at [stationaryRadiusMaxMeters] so a pair of hopeless fixes cannot
  /// swallow real movement.
  double _stationaryRadius(TrackPoint a, TrackPoint b) {
    final double accA = a.acc <= 0 ? stationaryRadiusMeters : a.acc;
    final double accB = b.acc <= 0 ? stationaryRadiusMeters : b.acc;
    return math.min(
      math.max(stationaryRadiusMeters, accA + accB),
      stationaryRadiusMaxMeters,
    );
  }

  /// Pulls each fix toward its neighbours in proportion to how uncertain it is:
  /// untouched at [smoothTrustMeters] or better, fully replaced by the
  /// neighbourhood mean at [smoothFullMeters] or worse. The mean is weighted by
  /// 1/accuracy so nearby good fixes dominate. Typed points are never moved — a
  /// mark belongs exactly where the hasher dropped it.
  List<TrackPoint> _smoothByUncertainty(List<TrackPoint> points) {
    final List<TrackPoint> out = <TrackPoint>[];
    for (int i = 0; i < points.length; i++) {
      final TrackPoint p = points[i];
      if (p.type != null && p.type!.isNotEmpty) {
        out.add(p);
        continue;
      }
      final double blend = ((p.acc - smoothTrustMeters) /
              (smoothFullMeters - smoothTrustMeters))
          .clamp(0.0, 1.0);
      if (blend <= 0) {
        out.add(p);
        continue;
      }
      double sw = 0, sLat = 0, sLng = 0;
      final int from = (i - smoothWindow) < 0 ? 0 : i - smoothWindow;
      final int to = (i + smoothWindow) >= points.length
          ? points.length - 1
          : i + smoothWindow;
      for (int j = from; j <= to; j++) {
        final TrackPoint n = points[j];
        if (n.type != null && n.type!.isNotEmpty) continue;
        final double w = 1 / (n.acc < 5 ? 5 : n.acc);
        sw += w;
        sLat += n.lat * w;
        sLng += n.lng * w;
      }
      if (sw == 0) {
        out.add(p);
        continue;
      }
      out.add(p.copyWith(
        lat: p.lat * (1 - blend) + (sLat / sw) * blend,
        lng: p.lng * (1 - blend) + (sLng / sw) * blend,
      ));
    }
    return out;
  }

  /// A deliberately placed mark (CHK, PHO, OIN, a trail-slot icon …) rather
  /// than an ordinary GPS fix. Marks are never moved or absorbed.
  static bool _isMark(TrackPoint p) => p.type != null && p.type!.isNotEmpty;



  /// Merges two timestamp-ordered lists, preserving order.
  static List<TrackPoint> _mergeByTimestamp(
    List<TrackPoint> a,
    List<TrackPoint> b,
  ) {
    final List<TrackPoint> out = <TrackPoint>[];
    int i = 0;
    int j = 0;
    while (i < a.length && j < b.length) {
      out.add(
        a[i].timestampMs <= b[j].timestampMs ? a[i++] : b[j++],
      );
    }
    while (i < a.length) {
      out.add(a[i++]);
    }
    while (j < b.length) {
      out.add(b[j++]);
    }
    return out;
  }

  /// Evaluates each point and marks it as good (true) or bad (false).
  List<bool> _evaluatePointQuality(List<TrackPoint> points) {
    final quality = List<bool>.filled(points.length, true);

    // First pass: de-duplicate near-identical timestamps.
    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      // Typed points (hash markers, photo markers, etc.) are intentional user
      // actions — never filter them regardless of accuracy or timing.
      if (point.type != null && point.type!.isNotEmpty) continue;

      // Time delta against previous point (deduplication)
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

    // Second pass: check velocity against last good point.
    // Typed points are skipped — they anchor to their GPS fix regardless of
    // how far they appear from the previous good point.
    int? lastGoodIndex;
    for (int i = 0; i < points.length; i++) {
      if (!quality[i]) continue; // Skip already marked bad points

      final point = points[i];
      final isTyped = point.type != null && point.type!.isNotEmpty;

      if (!isTyped && lastGoodIndex != null) {
        final lastGoodPoint = points[lastGoodIndex];
        final timeDeltaMs = point.timestampMs - lastGoodPoint.timestampMs;

        if (timeDeltaMs > 0) {
          final distance = _calculateDistance(lastGoodPoint, point);
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
