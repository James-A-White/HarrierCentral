import 'package:harrier_central/imports.dart';
import 'package:harrier_central/services/official_trails/official_trail_service.dart';
import 'package:latlong2/latlong.dart' as latlng;

/// The run's official trail on the PackTrack map (E5.F6.S6, James
/// 2026-10-03). Owned by [RunTrackerMapController]; fetched once when the
/// map opens (never polled), and again when the hasher says they are lost.
///
/// Drawn dashed under the pack's tracks. In replay a TIMED lane is aligned
/// to the first pack track's start ("auto-align"): its first point sits at
/// the timeline's minimum, so the hare's pace runs alongside the pack. An
/// untimed lane (most files, the imports) is drawn whole and never animated.
class OfficialTrailOverlay {
  OfficialTrailOverlay(this.eventId);

  final HcId eventId;

  final RxList<OfficialTrailLane> lanes = <OfficialTrailLane>[].obs;

  /// The viewer may set or replace a lane (hares, kennel admins).
  final RxBool canEdit = false.obs;

  /// Events whose official trail the viewer has asked for from "I'm Lost".
  /// A static set so the Live Run page can raise it without holding the map
  /// controller; every open overlay for that run reloads.
  static final RxSet<String> lostRevealed = <String>{}.obs;

  Worker? _lostWorker;
  bool _disposed = false;

  void start() {
    unawaited(load());
    _lostWorker = ever<Set<String>>(lostRevealed, (Set<String> s) {
      if (s.contains(eventId.toString()) && lanes.isEmpty) {
        unawaited(load(announce: true));
      }
    });
  }

  void dispose() {
    _disposed = true;
    _lostWorker?.dispose();
  }

  /// Asks for the run's trail from the I'm-lost flow. Shown to the lost
  /// runner only, from an hour before the start to 12 hours after it.
  static void revealForLost(String eventId) =>
      lostRevealed.add(HcId(eventId).toString());

  Future<void> load({bool announce = false}) async {
    final bool lost = lostRevealed.contains(eventId.toString());
    final RunOfficialTrail? got = await OfficialTrailService.fetchRunTrail(
      eventId,
      lost: lost,
    );
    if (_disposed || got == null) return;
    canEdit.value = got.canEdit;
    lanes.assignAll(got.available ? got.lanes : const <OfficialTrailLane>[]);
    if (announce && lanes.isNotEmpty) {
      hcSnack("The hare's trail is now on your PackTrack map (dashed).");
    }
  }

  /// Dashed lanes. With [elapsedMs] (replay, ms since the first pack
  /// track's start) a timed lane is drawn faint in full and solid up to the
  /// hare's position then.
  List<Polyline> polylines({int? elapsedMs}) {
    final List<Polyline> out = <Polyline>[];
    for (final OfficialTrailLane l in lanes) {
      final Color c = OfficialTrailLane.colorOf(l.type);
      final bool animate = l.timed && elapsedMs != null;
      out.add(
        Polyline(
          points: l.points,
          strokeWidth: 4,
          color: c.withValues(alpha: animate ? 0.35 : 0.8),
          pattern: StrokePattern.dashed(segments: const <double>[10, 8]),
        ),
      );
      if (animate) {
        final List<latlng.LatLng> soFar = l.pointsUpTo(elapsedMs);
        if (soFar.length >= 2) {
          out.add(
            Polyline(
              points: soFar,
              strokeWidth: 4,
              color: c.withValues(alpha: 0.9),
              pattern: StrokePattern.dashed(segments: const <double>[10, 8]),
            ),
          );
        }
      }
    }
    return out;
  }

  /// The hare's position on each timed lane during replay.
  List<Marker> markers({int? elapsedMs}) {
    if (elapsedMs == null) return const <Marker>[];
    final List<Marker> out = <Marker>[];
    for (final OfficialTrailLane l in lanes) {
      final latlng.LatLng? at = l.positionAt(elapsedMs);
      if (at == null) continue;
      out.add(
        Marker(
          point: at,
          width: 26,
          height: 26,
          child: Container(
            decoration: BoxDecoration(
              color: OfficialTrailLane.colorOf(l.type),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.flag, size: 14, color: Colors.white),
          ),
        ),
      );
    }
    return out;
  }

  /// A runner's PackTrack as lane points: plain fixes only, cut at the
  /// first On Inn (the track terminator).
  static List<TrackPoint> trackForPromotion(List<TrackPoint> positions) {
    final List<TrackPoint> sorted = List<TrackPoint>.of(positions)
      ..sort((TrackPoint a, TrackPoint b) => a.timestampMs.compareTo(b.timestampMs));
    final List<TrackPoint> out = <TrackPoint>[];
    for (final TrackPoint p in sorted) {
      final String? t = p.type;
      if (t != null && t.split('::').first == 'OIN') break;
      if (t == null) out.add(p);
    }
    return out;
  }
}
