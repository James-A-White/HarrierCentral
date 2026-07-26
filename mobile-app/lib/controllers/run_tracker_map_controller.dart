import 'dart:math' as math;

import 'package:harrier_central/imports.dart';
import 'package:harrier_central/util/track_point_filter.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:harrier_central/widgets/camera_photo_marker.dart';
import 'package:latlong2/latlong.dart' as latlng;

// TODO(S4): This controller mixes UI layout state (map rendering, playback
// animation, marker building) with domain logic (position loading, track
// filtering, distance calculation). Extract PlaybackState and TrackDataState
// into dedicated sub-controllers when this page is next significantly modified.
class RunTrackerMapController extends GetxController
    with GetSingleTickerProviderStateMixin, WidgetsBindingObserver {
  RunTrackerMapController({
    required this.event,
    required this.eventLocation,
    required latlng.LatLng mapCenter,
    required this.kennelLocation,
    required this.minZoom,
    required this.maxZoom,
    required this.initialZoom,
    required bool trueNorthLock,
    bool autoFollowOnLoad = true,
  }) : _trueNorthLock = trueNorthLock.obs,
       followRunner = autoFollowOnLoad.obs,
       _mapCenterPoint =
           (mapCenter.latitude == CLEAR_LATLONG &&
               mapCenter.longitude == CLEAR_LATLONG)
           ? kennelLocation
           : mapCenter;

  // ── UI state ──────────────────────────────────────────────────────────────
  // Map controllers, playback animation, scroll/carousel controllers.

  static const double _zoomFastThreshold = 15.0;
  static const double _zoomSlowThreshold = 22.0;
  // Playback duration scales with the trail's length, not a fixed wall-clock
  // time: the zoomed-out rate is 2.5 s/km, and zooming in slows that toward
  // 20 s/km so detail is watchable. The rate is interpolated by zoom between
  // the two thresholds. Constants match public-web (MS_PER_KM_FAST/SLOW,
  // MIN_DURATION_MS) so a given run plays at the same speed on app and web.
  static const double _msPerKmFast = 2500.0; // 2.5 s/km — fully zoomed out (≤ 15)
  static const double _msPerKmSlow = 20000.0; // 20 s/km — fully zoomed in (≥ 22)
  static const Duration _minPlaybackDuration =
      Duration(seconds: 5); // floor so a very short trail doesn't flash past
  static const Duration _autoUpdateInterval = Duration(seconds: 15);

  // Stable per-runner colour palette, matched to public-web's TRACK_COLORS so a
  // runner reads the same colour on app and web. Assigned by order of appearance
  // in the loaded set (see [_assignRunnerColors]) and keyed by id, so filtering
  // trail lanes never reshuffles the colours.
  static const List<Color> _trackColors = <Color>[
    Color(0xFFEF4444), Color(0xFF3B82F6), Color(0xFF22C55E), Color(0xFFF59E0B),
    Color(0xFFA855F7), Color(0xFFEC4899), Color(0xFF06B6D4), Color(0xFFF97316),
  ];
  final Map<String, Color> _colorById = <String, Color>{};

  // Manual playback-speed steps cycled by the speed button (matches web
  // SPEED_STEPS). Tilt control is continuous and overrides this while on.
  static const List<double> _speedSteps = <double>[0.5, 1.0, 2.0, 4.0];
  final RxDouble playbackSpeed = 1.0.obs;

  // Horizontal runner carousel (replaces the old Cupertino wheel picker). One
  // tile per visible runner; the centred tile is the selection. This is the
  // scroll geometry the controller uses to snap/centre — see [onCarouselScrollEnd].
  static const double runnerTileExtent = 60.0;

  final MapController mapController = MapController();
  final ScrollController runnerCarouselController = ScrollController();

  late final AnimationController _playbackController;
  bool _mapReady = false;
  bool _isVisible = false;
  double? _lastRotationDeg;
  Duration? _lastPlaybackDuration;
  // Speed-1 duration for the current zoom; drives the tilt ticker so tilt speed
  // is independent of the manual speed button.
  Duration? _lastBaseDuration;
  double _lastMarkerZoom = 0.0;

  // ── Domain state ──────────────────────────────────────────────────────────
  // Track data, timeline bounds, selection, user identity.

  final EventModel event;
  final latlng.LatLng? eventLocation;
  final latlng.LatLng kennelLocation;
  final double minZoom;
  final double maxZoom;
  final double initialZoom;

  final latlng.LatLng _mapCenterPoint;
  final RxBool _trueNorthLock;
  final RxList<UserTrack> userPositions = <UserTrack>[].obs;
  final RxMap<String, String> userLogos = <String, String>{}.obs;
  final RxMap<String, String> userNames = <String, String>{}.obs;
  final TrackPointFilter _trackFilter = TrackPointFilter();
  final RxnDouble minTimestampMs = RxnDouble();
  final RxnDouble maxTimestampMs = RxnDouble();
  final RxnDouble currentTimestampMs = RxnDouble();
  final RxBool isPlaying = false.obs;
  final RxnString selectedRunnerId = RxnString();

  // ── Tilt-to-scrub playback (ported from the web PackTrack) ────────────────
  // Opt-in: tilt the phone away to speed playback up (to ×4), toward you to
  // slow, then REVERSE (to −×2). While enabled, the AnimationController is
  // stopped and a ticker drives _playbackController.value directly (the value
  // setter fires the normal tick handler, so everything downstream is
  // unchanged). Calibrates the neutral holding angle on enable; ±8° dead zone,
  // ±32° span, EMA smoothing — same tuning as the web.
  final RxBool tiltEnabled = false.obs;
  final RxDouble tiltSpeed = 1.0.obs; // smoothed multiplier, for the indicator

  // Viewer's device-compass heading in degrees (0 = North), or null when no
  // compass feed is active. Drives the blue-dot direction wedge. Left null for
  // now — a compass source is wired in a later step; the wedge only renders when
  // this is non-null, so the dot degrades cleanly to a plain marker meanwhile.
  final RxnDouble deviceHeading = RxnDouble();

  // ── Photo showcase (in-map zoom-from-pin) ──────────────────────────────────
  // When armed (Camera toggle), playback pauses as the playhead crosses one of
  // the selected runner's photo cues and the photo grows out of its pin toward
  // centre and back, then playback resumes. Mirrors public-web's PhotoZoomOverlay.
  final RxBool photoShowcaseArmed = false.obs;
  final Rxn<PhotoShowcaseState> photoShowcase = Rxn<PhotoShowcaseState>();
  final RxDouble showcaseZoom = 0.0.obs; // 0 = at pin, 1 = full at centre
  // Horizontal navigation cue, -1 (left) … 0 (centre) … +1 (right). Forward
  // playback enters the photo from the right and exits to the left; reverse
  // mirrors it — so the sweep direction makes navigation direction obvious.
  final RxDouble showcasePan = 0.0.obs;
  double _showcaseDir = 1.0; // +1 forward, -1 reverse — captured at show start
  // The showcase animation is driven off vsync frame callbacks (one update per
  // rendered frame), not a wall-clock Timer — this coalesces redraws to the
  // frame rate and avoids timer-vs-refresh phase-beating (a source of stutter).
  int? _showcaseFrameCallbackId;
  // Progress through the show curve in "virtual ms", advanced each frame by
  // dt × effective speed (tilt magnitude, or playback speed when tilt is off).
  // Freezes when the effective speed is 0 (tilt held at the stop-point).
  double _showcaseVirtualMs = 0.0;
  Duration? _lastShowcaseStamp; // previous frame timestamp (vsync clock)
  bool _showcaseResumeAfter = false;
  // Zoom envelope (ms), matches web: IN → HOLD → OUT.
  static const int _showInMs = 450;
  static const int _showHoldMs = 1500;
  static const int _showOutMs = 650;

  // Camera follow (mirrors the web's follow toggle): while ON the camera
  // tracks the selected runner on every timeline/position update; OFF lets
  // the user pan freely without the map snapping back. Explicit actions
  // (tapping a runner, picking in the carousel) still recenter either way.
  // Starts OFF when opened focused on a coordinate (e.g. a run photo) so the
  // load-time auto-recenter doesn't drag the camera to the run's end.
  final RxBool followRunner;
  StreamSubscription<AccelerometerEvent>? _tiltSub;
  StreamSubscription<CompassEvent>? _compassSub;
  Timer? _tiltTicker;
  double? _tiltNeutralDeg;
  final List<double> _tiltCalibSamples = [];
  double _tiltEma = 1.0;
  DateTime? _lastTiltTick;
  static const double _tiltDeadDeg = 8.0;
  static const double _tiltSpanDeg = 32.0;
  // Widened paused band: any target speed within ±this of zero snaps to exactly
  // 0, so the freeze point between slow-forward and reverse is a comfortably
  // holdable band rather than a razor-thin angle. Pairs with the red "paused"
  // speed bubble (tiltPaused). Widened from 0.5 → 0.8 (2026-07-16, James) for an
  // easier hold; tune here if the pause range still feels too small/large.
  static const double _tiltNeutralBand = 0.8;

  // Trail-type filtering: the kennel's config (bundled by GetPositions on the
  // full fetch), the set of lanes currently shown, and the lanes ever seen so
  // newly-appearing lanes default to visible while user deselections persist.
  final RxnString trailTypesConfigJson = RxnString();
  final RxSet<int> selectedTrailValues = <int>{}.obs;
  final Set<int> _knownTrailValues = {};

  // Official run window (epoch-ms) from the admin AST/AEN boundary markers,
  // surfaced by GetPositions. Null on the unbounded side / when unset. Drives
  // the admin trim editor's readout; normal viewers already receive a
  // server-trimmed track so these are display-only here.
  final RxnInt officialStartMs = RxnInt();
  final RxnInt officialEndMs = RxnInt();

  // When true, loadPositions asks GetPositions for the FULL (untrimmed) track
  // so the admin trim editor can see out-of-window points and drag the
  // boundaries back outward. Off for everyone else — they get the trimmed view.
  bool adminEditMode = false;

  final latlng.Distance _distanceCalculator = const latlng.Distance();

  // Marks of the same type closer than this are treated as the same physical
  // point (e.g. several runners marking one check) and collapsed to one marker.
  static const double _markDedupeMeters = 25.0;

  // A runner counts as having "reached" a mark if their track passed within this
  // distance of it — used by the tap-a-mark "who got here, and when" dialog.
  static const double _reachedMarkMeters = 20.0;

  // A runner is "checking" if they reached a mark, ran at least this far away,
  // then came back to it (an out-and-back excursion = solving the check).
  static const double _checkExcursionMeters = 50.0;
  final String? _currentUserId = getStringPref(StringPrefsEnum.userId);

  // Reused across loadPositions() calls to avoid creating a new http.Client each time.
  final GetPositionsApi _positionsApi = GetPositionsApi();

  // Bumped whenever the photo caches below change (photos loaded/refreshed), so
  // the memoised marker lists know to rebuild and pick up newly-resolved photos.
  int _photoCacheVersion = 0;

  // Memoised checkpoint/photo marker lists. The getters rebuild these only when
  // the marker set would actually differ (see _markerCacheKey), returning the
  // SAME list instance across the many per-frame reads during playback — so we
  // don't reconstruct every marker widget, and (with _PhotoClusterLayer) don't
  // re-cluster, 60x/second while nothing has changed.
  List<Marker> _cachedCheckpointMarkers = const [];
  String? _cachedCheckpointMarkersKey;
  List<Marker> _cachedPhotoMarkers = const [];
  String? _cachedPhotoMarkersKey;
  // The photo-cluster layer widget, cached as a stable instance while its
  // marker set is unchanged so FlutterMap skips re-clustering on frame-only
  // rebuilds (see photoClusterLayer).
  Widget? _cachedPhotoClusterLayer;
  List<Marker>? _cachedPhotoClusterMarkers;

  // photoId (lowercase UUID) → blob URL, populated from hcapp_getRunPhotos.
  // Refreshed on every live-run auto-update tick so newly-taken photos appear.
  final Map<String, String> _photoUrlCache = {};

  // photoId → device-library asset ID for own photos (null for others').
  // Used to attempt local-first image loading in CameraPhotoMarker.
  final Map<String, String> _photoAssetIdCache = {};

  // photoId → caption text. Null entries are simply absent from the map.
  final Map<String, String> _photoCaptionCache = {};

  // blobUrl → isLandscape, populated on first render of each photo marker.
  // Survives map zoom/pan rebuilds so markers skip the loading animation.
  final Map<String, bool> _photoOrientationCache = {};

  // Uploader identity — populated lazily from local SQLite on first photo fetch.
  // Keyed by lowercase userId so multiple photos by the same person only trigger
  // one DB lookup. photoId → userId provides the join between the two maps.
  final Map<String, String> _photoUploaderIdCache = {};  // photoId  → userId
  final Map<String, String> _uploaderNameCache = {};     // userId   → display name
  final Map<String, String> _uploaderPhotoCache = {};    // userId   → profile photo URL

  Worker? _timelineWorker;
  Worker? _selectionWorker;
  StreamSubscription<MapEvent>? _mapEventsSub;
  Timer? _autoUpdateTimer;
  String? _afterTimestampMs;

  // ── Operations ────────────────────────────────────────────────────────────
  // Lifecycle, data loading, playback control, camera, rendering helpers.

  bool get _isPlaybackActive =>
      isPlaying.value || _playbackController.isAnimating;

  bool get _isStaleEvent {
    // Use GMT start time to avoid local offset drift
    final DateTime startUtc = event.eventStartDatetimeGmt.toUtc();
    final cutoffUtc = startUtc.add(const Duration(days: 1));
    return DateTime.now().toUtc().isAfter(cutoffUtc);
  }

  latlng.LatLng get mapCenterPoint => _mapCenterPoint;
  bool get trueNorthLock => _trueNorthLock.value;

  bool get timelineAvailable =>
      minTimestampMs.value != null &&
      maxTimestampMs.value != null &&
      currentTimestampMs.value != null &&
      maxTimestampMs.value! > minTimestampMs.value!;

  List<Polyline> get dimmedPolylines {
    if (userPositions.isEmpty) return const [];
    final cutoff = timelineAvailable ? currentTimestampMs.value : null;
    final String? selectedId = selectedRunnerId.value;
    final bool hasSelection = selectedId != null;
    final double baseAlpha = hasSelection ? 0.6 : 1.0;

    return visibleRunners
        .where((user) => !hasSelection || user.id != selectedId)
        .map((user) => _buildPolylineForUser(user, cutoff, alpha: baseAlpha))
        .whereType<Polyline>()
        .toList(growable: false);
  }

  Polyline? get highlightedPolyline {
    final runner = _runnerById(selectedRunnerId.value);
    if (runner == null || !isRunnerVisible(runner)) return null;
    final cutoff = timelineAvailable ? currentTimestampMs.value : null;
    return _buildPolylineForUser(runner, cutoff, alpha: 1.0, strokeWidth: 6.0);
  }

  /// Distance in meters for the current user, using the same filtered/interpolated
  /// track used by the map/timeline. Returns null if the current user has no data yet.
  double? currentUserDistanceMeters() {
    if (_currentUserId == null) return null;
    final runner = _runnerById(_currentUserId);
    if (runner == null) return null;
    final cutoff = timelineAvailable ? currentTimestampMs.value : null;
    return _sumInterpolatedDistance(_interpolatedTrackPoints(runner, cutoff));
  }

  List<Marker> get runnerMarkers {
    if (userPositions.isEmpty) return const [];
    final cutoff = timelineAvailable ? currentTimestampMs.value : null;
    final selectedId = selectedRunnerId.value;
    final markers = <Marker>[];
    final highlightedMarkers = <Marker>[];

    final hasSelection = selectedId != null;

    for (final user in visibleRunners) {
      final interpolated = _interpolatedPosition(user, cutoff);
      if (interpolated == null) continue;
      // No skip on a missing photo — avatarImageProvider falls back to a bundled
      // avatar, so photo-less runners still get a marker instead of vanishing.
      final logo = userLogos[user.id];
      final bool isHighlighted = hasSelection ? user.id == selectedId : false;
      final bool isDimmed = hasSelection && user.id != selectedId;
      final marker = Marker(
        width: 80,
        height: 90,
        point: latlng.LatLng(interpolated.lat, interpolated.lng),
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => selectRunner(user.id, recenter: true, syncPicker: true),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isDimmed ? 0.75 : 1.0,
            child: _buildRunnerMarker(logo, isHighlighted: isHighlighted),
          ),
        ),
      );
      if (hasSelection && user.id == selectedId) {
        highlightedMarkers.add(marker);
      } else {
        markers.add(marker);
      }
    }

    return [...markers, ...highlightedMarkers];
  }

  Color runnerColor(String userId) => _colorForUser(userId);

  List<Marker> get checkpointMarkers {
    final key = _markerCacheKey(photosOnly: false);
    if (key == _cachedCheckpointMarkersKey) return _cachedCheckpointMarkers;
    _cachedCheckpointMarkersKey = key;
    _cachedCheckpointMarkers = _buildCheckpointMarkers(photosOnly: false);
    return _cachedCheckpointMarkers;
  }

  List<Marker> get photoCheckpointMarkers {
    final key = _markerCacheKey(photosOnly: true);
    if (key == _cachedPhotoMarkersKey) return _cachedPhotoMarkers;
    _cachedPhotoMarkersKey = key;
    _cachedPhotoMarkers = _buildCheckpointMarkers(photosOnly: true);
    return _cachedPhotoMarkers;
  }

  /// The photo-checkpoint marker-cluster layer, cached as a stable widget
  /// instance while the photo marker set is unchanged. FlutterMap is rebuilt
  /// every frame during playback (runners move); handing it the identical layer
  /// widget lets it skip re-running the clustering algorithm when nothing about
  /// the photos changed. A camera move still re-clusters — the layer depends on
  /// MapCamera and rebuilds itself when the map pans/zooms.
  Widget get photoClusterLayer {
    final List<Marker> markers = photoCheckpointMarkers;
    if (_cachedPhotoClusterLayer != null &&
        identical(markers, _cachedPhotoClusterMarkers)) {
      return _cachedPhotoClusterLayer!;
    }
    _cachedPhotoClusterMarkers = markers;
    _cachedPhotoClusterLayer = MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        maxClusterRadius: 40,
        size: const Size(52, 52),
        spiderfyCircleRadius: 90,
        markers: markers,
        builder: (context, clustered) => _photoClusterBadge(clustered.length),
      ),
    );
    return _cachedPhotoClusterLayer!;
  }

  Widget _photoClusterBadge(int count) => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black87,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_camera, color: Colors.white, size: 18),
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  /// A signature that changes only when the built marker set would differ. Used
  /// to memoise [checkpointMarkers] / [photoCheckpointMarkers] so per-frame reads
  /// during playback return a cached list instead of rebuilding every marker
  /// widget. Captures: how many marks are revealed at the current playhead
  /// ([_visibleMarkCount]), the marker scale (zoom), the trail filter, the
  /// selected runner, the data size, and the photo-cache version.
  String _markerCacheKey({required bool photosOnly}) {
    final double? cutoff = timelineAvailable ? currentTimestampMs.value : null;
    final String scale =
        (photosOnly ? _photoMarkerScale() : _markerScale()).toStringAsFixed(3);
    return '${_visibleMarkCount(photosOnly: photosOnly, cutoff: cutoff)}'
        '|$scale'
        '|${selectedTrailValues.join(",")}'
        '|${selectedRunnerId.value ?? ""}'
        '|${userPositions.length}'
        '|$_photoCacheVersion';
  }

  /// Counts the marks of the requested kind (photos vs checkpoints) that are
  /// revealed at [cutoff], from lane-visible runners. Cheap relative to building
  /// the marker widgets — the flood of plain GPS points is skipped on the empty
  /// type check; only actual marks are parsed.
  int _visibleMarkCount({required bool photosOnly, required double? cutoff}) {
    int n = 0;
    for (final user in visibleRunners) {
      for (final p in user.positions) {
        if ((p.type ?? '').isEmpty) continue;
        if (cutoff != null && p.timestampMs.toDouble() > cutoff) continue;
        final parsed = _parseCheckpointType(p.type);
        if (parsed == null) continue;
        final bool isPhoto = parsed.type == HashRunPointTypes.photo;
        if (photosOnly == isPhoto) n++;
      }
    }
    return n;
  }

  List<Marker> _buildCheckpointMarkers({required bool photosOnly}) {
    if (userPositions.isEmpty) return const [];
    final cutoff = timelineAvailable ? currentTimestampMs.value : null;

    // Gather the mark points that belong on this layer (checkpoints vs photos).
    // Only from lane-VISIBLE runners: hiding a trail type (e.g. Ballbreaker)
    // must hide the marks its runners put down, not just the polyline.
    final entries = <_MarkEntry>[];
    for (final point in visibleRunners.expand((user) => user.positions)) {
      final rawType = (point.type ?? '').trim();
      if (rawType.isEmpty) continue;
      if (cutoff != null && point.timestampMs.toDouble() > cutoff) continue;
      final parsedType = _parseCheckpointType(point.type);
      if (parsedType == null) continue;
      final bool isPhoto = parsedType.type == HashRunPointTypes.photo;
      if (photosOnly != isPhoto) continue;
      entries.add((point: point, type: rawType, parsed: parsedType));
    }

    // When several runners mark the same physical point (e.g. a check), the
    // marks land a few metres apart and stack up. Collapse same-type marks that
    // are within _markDedupeMeters of an already-kept one. Photos are never
    // collapsed — each is a distinct image.
    final shown = photosOnly ? entries : _dedupeNearbyMarks(entries);

    return shown.map((entry) {
      final parsedType = entry.parsed;
      final bool isPhoto = parsedType.type == HashRunPointTypes.photo;

      final bool hasAttachedLabel =
          (parsedType.customLabel?.isNotEmpty ?? false) &&
          (parsedType.slotIcon != null ||
              parsedType.glyphId != null ||
              parsedType.text != null ||
              parsedType.type == HashRunPointTypes.customLabel ||
              parsedType.type == HashRunPointTypes.caution);

      const double baseIconSize = 72.0;
      const double basePhotoSize = 144.0;
      const double baseLabelWidth = 140.0;
      const double baseLabelHeight = 140.0;

      final double scale = isPhoto ? _photoMarkerScale() : _markerScale();
      final double markerWidth = hasAttachedLabel
          ? baseLabelWidth * scale
          : (isPhoto ? basePhotoSize : baseIconSize) * scale;
      final double markerHeight = hasAttachedLabel
          ? baseLabelHeight * scale
          : (isPhoto ? basePhotoSize : baseIconSize) * scale;

      final markChild = _buildCheckpointMarker(parsedType);
      return Marker(
        width: markerWidth,
        height: markerHeight,
        point: latlng.LatLng(entry.point.lat, entry.point.lng),
        alignment: Alignment.topCenter,
        // Photos keep their own tap behaviour. Tap a trail mark to see which
        // runners passed through that point during the run, and when.
        child: isPhoto
            ? markChild
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showRunnersAtMark(
                  latlng.LatLng(entry.point.lat, entry.point.lng),
                  parsedType,
                ),
                child: markChild,
              ),
      );
    }).toList(growable: false);
  }

  /// Collapses marks of the same type that sit within [_markDedupeMeters] of an
  /// already-kept mark, so multiple runners marking the same physical point
  /// (e.g. a check) render as one marker instead of an overlapping stack. The
  /// first mark of each cluster is kept.
  List<_MarkEntry> _dedupeNearbyMarks(List<_MarkEntry> entries) {
    final kept = <_MarkEntry>[];
    for (final entry in entries) {
      final bool isDuplicate = kept.any(
        (k) =>
            k.type == entry.type &&
            _distanceCalculator.as(
                  latlng.LengthUnit.Meter,
                  latlng.LatLng(k.point.lat, k.point.lng),
                  latlng.LatLng(entry.point.lat, entry.point.lng),
                ) <=
                _markDedupeMeters,
      );
      if (!isDuplicate) kept.add(entry);
    }
    return kept;
  }

  /// Tap-a-mark handler ("who passed through"): finds every runner whose track
  /// came within [_reachedMarkMeters] of [location] — by each runner's closest
  /// approach — and shows them earliest-first, with the time they were nearest.
  void _showRunnersAtMark(
    latlng.LatLng location,
    _ParsedCheckpointType parsed,
  ) {
    final reached =
        <({String userId, int timestampMs, double distance, int returns})>[];
    for (final user in userPositions) {
      int? arrivedTs; // first time this track entered the "reached" radius
      double closest = double.infinity; // nearest the track ever got
      int returns = 0; // out-and-back excursions of >= _checkExcursionMeters
      bool everInside = false;
      bool currentlyInside = false;
      double peakAwaySinceInside = 0;
      for (final p in user.positions) {
        final d = _distanceCalculator.as(
          latlng.LengthUnit.Meter,
          location,
          latlng.LatLng(p.lat, p.lng),
        );
        if (d < closest) closest = d;
        final bool inside = d <= _reachedMarkMeters;
        if (inside) {
          arrivedTs ??= p.timestampMs;
          // Re-entering the mark after running at least _checkExcursionMeters
          // away counts as a check (they ran out a lead and came back).
          if (everInside &&
              !currentlyInside &&
              peakAwaySinceInside >= _checkExcursionMeters) {
            returns++;
          }
          everInside = true;
          currentlyInside = true;
          peakAwaySinceInside = 0;
        } else if (everInside) {
          currentlyInside = false;
          if (d > peakAwaySinceInside) peakAwaySinceInside = d;
        }
      }
      if (arrivedTs != null) {
        reached.add((
          userId: user.id,
          timestampMs: arrivedTs,
          distance: closest,
          returns: returns,
        ));
      }
    }
    // Checkers (ran out >= _checkExcursionMeters and came back) sort to the top,
    // most-active first; everyone else follows by arrival time.
    reached.sort((a, b) {
      final byChecks = b.returns.compareTo(a.returns);
      return byChecks != 0 ? byChecks : a.timestampMs.compareTo(b.timestampMs);
    });

    final String title = (parsed.customLabel?.isNotEmpty ?? false)
        ? 'Reached: ${parsed.customLabel}'
        : 'Who reached this mark';

    unawaited(
      Get.dialog(
        AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: reached.isEmpty
                ? Text(
                    'No runner passed within '
                    '${_reachedMarkMeters.toStringAsFixed(0)} m of this mark.',
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: reached.length,
                    itemBuilder: (context, i) {
                      final r = reached[i];
                      final name = userNames[r.userId]?.trim();
                      final label =
                          (name == null || name.isEmpty) ? 'Runner' : name;
                      final bool checked = r.returns > 0;
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: _colorForUser(r.userId),
                          child: Text(
                            label[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          label,
                          style: TextStyle(
                            fontWeight:
                                checked ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          checked
                              ? '🔍 checked${r.returns > 1 ? ' ${r.returns}×' : ''} · nearest ${r.distance.toStringAsFixed(0)} m'
                              : 'nearest ${r.distance.toStringAsFixed(0)} m',
                        ),
                        trailing: Text(
                          _formatTimestamp(r.timestampMs.toDouble())
                              .split(' ')
                              .last,
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back<void>(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  String get formattedTimelineLabel => _formatElapsed();

  /// Elapsed run time from the start of the track to the current playhead, as
  /// H:MM:SS — hours are shown only when > 0 (e.g. `7:32`, `1:07:32`). Replaces
  /// the absolute timestamp in the map control panel.
  String _formatElapsed() {
    final cur = currentTimestampMs.value;
    final start = minTimestampMs.value;
    if (cur == null || start == null) return '0:00';
    final totalSec = ((cur - start).clamp(0, double.infinity) / 1000).floor();
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
  }
  String get formattedDistanceLabel => _formatDistanceLabel();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    final initialPlaybackDuration = _durationForZoom(initialZoom);
    _lastPlaybackDuration = initialPlaybackDuration;
    _playbackController =
        AnimationController(vsync: this, duration: initialPlaybackDuration)
          ..addListener(_handlePlaybackTick)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && timelineAvailable) {
              currentTimestampMs.value = maxTimestampMs.value;
              isPlaying.value = false;
              _startAutoUpdateTimer();
            }
          });
    _timelineWorker = ever<double?>(currentTimestampMs, (_) {
      _updateCameraForSelection();
    });
    _selectionWorker = ever<String?>(selectedRunnerId, (_) {
      _updateCameraForSelection();
      syncRunnerPickerToSelection(onlyIfMismatch: true, animated: false);
    });
    _mapEventsSub = mapController.mapEventStream.listen((event) {
      final zoom = event.camera.zoom;
      debugPrint('Map zoom update: $zoom');
      final wasReady = _mapReady;
      _mapReady = true;
      if (zoom != _lastMarkerZoom) {
        _lastMarkerZoom = zoom;
        update(); // refresh marker sizes when zoom changes
      }
      _applyPlaybackDurationFromZoom(zoomOverride: zoom);
      if (!wasReady) {
        _updateCameraForSelection();
      }
    });

    // Start with map visible
    _isVisible = true;
    _lastMarkerZoom = initialZoom;
    _startAutoUpdateTimer();
    _startCompass();
    BootLogger.logBreadcrumb(
      'PackTrack map OPENED (eventId=${event.eventId})',
    );
    unawaited(loadPositions());
    unawaited(_loadPhotoCache());
  }

  // The compass fires many times a second. A sub-degree wedge rotation isn't
  // visible, so ignore heading changes below this — it collapses the write rate
  // to only meaningful movements. Paired with the isolated Obx around the viewer
  // dot (see _viewerDot), so even these writes never rebuild the map.
  static const double _headingUpdateThresholdDeg = 2.0;

  /// Subscribes to the device compass so the blue-dot wedge points where the
  /// viewer is facing. Heading is null on devices without a magnetometer, in
  /// which case the wedge simply never appears. Idempotent.
  void _startCompass() {
    _compassSub ??= FlutterCompass.events?.listen((event) {
      final h = event.heading;
      if (h == null) return;
      final prev = deviceHeading.value;
      if (prev != null) {
        // Smallest angle between the two headings, accounting for the 0/360 wrap.
        var diff = (h - prev).abs();
        if (diff > 180.0) diff = 360.0 - diff;
        if (diff < _headingUpdateThresholdDeg) return; // sub-visible — skip
      }
      deviceHeading.value = h;
    });
  }

  void _stopCompass() {
    unawaited(_compassSub?.cancel());
    _compassSub = null;
    deviceHeading.value = null; // hide the wedge when not actively watching
  }

  @override
  void onClose() {
    BootLogger.logBreadcrumb('PackTrack map CLOSED');
    WidgetsBinding.instance.removeObserver(this);
    _stopAutoUpdateTimer();
    unawaited(_tiltSub?.cancel());
    unawaited(_compassSub?.cancel());
    _tiltTicker?.cancel();
    _cancelShowcaseFrame();
    _timelineWorker?.dispose();
    _selectionWorker?.dispose();
    unawaited(_mapEventsSub?.cancel());
    runnerCarouselController.dispose();
    _playbackController.dispose();
    _positionsApi.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Breadcrumb: if the app is killed while backgrounded during live tracking
    // (iOS OOM / background-location watchdog), this transition is the last
    // thing captured and points straight at the background path.
    BootLogger.logBreadcrumb('PackTrack map: app lifecycle -> $state');
    switch (state) {
      case AppLifecycleState.resumed:
        setVisible(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        setVisible(false);
        break;
    }
  }

  // Fetches the authorised photo URL list for this event and populates
  // _photoUrlCache, _photoAssetIdCache, _photoCaptionCache, and the uploader
  // identity caches. Called on init and every auto-update tick.
  Future<void> _loadPhotoCache() async {
    try {
      final raw = await KennelPhotoService().getRunPhotos(eventId: event.eventId);
      if (raw.startsWith(ERROR_PREFIX)) return;
      final outer = jsonDecode(raw) as List<dynamic>;
      // No envelope on success. rowset 0 = own photos, rowset 1 = public photos.
      bool updated = false;
      for (final idx in [0, 1]) {
        if (outer.length <= idx || outer[idx] is! List) continue;
        for (final row in outer[idx] as List<dynamic>) {
          if (row is! Map<String, dynamic>) continue;
          final id = (row['photoId'] as String?)?.toLowerCase();
          final url = (row['BlobUrl'] ?? row['blobUrl']) as String?;
          if (id != null && id.isNotEmpty && url != null && url.isNotEmpty) {
            _photoUrlCache[id] = url;
            // AssetId is only present in rowset 0 (own photos). Store it so
            // CameraPhotoMarker can attempt local device loading first.
            final assetId = (row['AssetId'] ?? row['assetId']) as String?;
            if (assetId != null && assetId.isNotEmpty) {
              _photoAssetIdCache[id] = assetId;
            }
            final description =
                (row['Description'] ?? row['description']) as String?;
            if (description != null && description.isNotEmpty) {
              _photoCaptionCache[id] = description;
            }
            // Uploader identity — look up from local SQLite on first encounter.
            final rawUserId = (row['UserId'] ?? row['userId']) as String?;
            if (rawUserId != null && rawUserId.isNotEmpty) {
              final userId = normalizeUuid(rawUserId);
              _photoUploaderIdCache[id] = userId;
              if (!_uploaderNameCache.containsKey(userId)) {
                final userData = await QueryUsers.querySingleUser(userId);
                if (userData.isNotEmpty) {
                  _uploaderNameCache[userId] =
                      _preferredDisplayName(userData.first);
                  final photoUrl = userData.first[
                      tableModel.hashersTableHelper.colPhoto] as String?;
                  _uploaderPhotoCache[userId] = photoUrl ?? '';
                }
              }
            }
            updated = true;
          }
        }
      }
      if (updated) {
        _photoCacheVersion++; // invalidate the memoised marker lists
        update();
      }
    } catch (e, s) {
      debugPrint('_loadPhotoCache error: $e');
      BootLogger.logError('[RunTrackerMapController._loadPhotoCache] eventId=${event.eventId}', e, s);
    }
  }

  Future<void> loadPositions({bool reset = false}) async {
    if (reset) {
      _afterTimestampMs = null;
    }

    // print(
    //   'Loading positions for event ${event.eventId}... at ${DateTime.now().microsecondsSinceEpoch}',
    // );

    try {
      final data = await _positionsApi.fetchPositions(
        eventId: event.eventId,
        latestClientTimestampMs: _afterTimestampMs ?? '0000000000000000000',
        includeTrimmed: adminEditMode,
      );
      _afterTimestampMs = data.latestServerTimestampMs;
      // Trail-type config arrives on the full fetch only; cache it (incremental
      // polls return null, so don't clobber the cached value).
      if (data.trailTypesConfigJson != null) {
        trailTypesConfigJson.value = data.trailTypesConfigJson;
      }
      // Official window is recomputed server-side on every response, so mirror
      // it each load (null clears it when the boundary markers are removed).
      officialStartMs.value = data.trimStartMs;
      officialEndMs.value = data.trimEndMs;
      _startAutoUpdateTimer();
      await _hydrateLogos(data.users);

      // Filter and clean track points for each user
      final cleanedUsers = data.users.map((user) {
        if (user.positions.length < 2) return user;

        final filteredPositions = _trackFilter.filterAndInterpolate(
          user.positions,
        );

        // Log filtering stats for debugging
        if (user.positions.length != filteredPositions.length) {
          final stats = _trackFilter.getFilterStats(
            user.positions,
            filteredPositions,
          );
          debugPrint('Filtered track for ${user.id}: $stats');
        }

        return user.copyWith(positions: filteredPositions);
      }).toList();

      userPositions.assignAll(cleanedUsers);
      _assignRunnerColors(cleanedUsers);
      _refreshTrailFilter();
      _initializeTimelineBounds();
      _ensureSelection();
      syncRunnerPickerToSelection(onlyIfMismatch: true, animated: false);
    } catch (error, s) {
      debugPrint('Error fetching positions: $error');
      BootLogger.logError('[RunTrackerMapController.loadPositions] eventId=${event.eventId}', error, s);
    }
  }

  // ── Trail-type filtering ──────────────────────────────────────────────────

  /// The trail lane a runner declared, from their latest `TRL::<value>` point.
  /// Defaults to Normal when none was declared (legacy / undeclared tracks).
  int trailValueForRunner(UserTrack user) {
    int? latest;
    for (final p in user.positions) {
      final t = (p.type ?? '').trim();
      if (!t.startsWith('TRL::')) continue;
      // Strip any trailing '::...' or diagnostic '~tag' before parsing the int.
      final body = t.substring(5).split('::').first.split('~').first.trim();
      final v = int.tryParse(body);
      if (v != null) latest = v; // positions are time-ordered → last wins
    }
    return latest ?? TrailType.normalValue;
  }

  /// Resolves a lane value to its display type (label + emoji) for this kennel.
  TrailType trailTypeFor(int value) =>
      TrailType.resolveOne(value, trailTypesConfigJson.value);

  /// Distinct lanes present in the loaded data, ordered by the kennel's order.
  List<int> get presentTrailValues {
    final present = userPositions.map(trailValueForRunner).toSet();
    final visible = TrailType.resolveVisible(trailTypesConfigJson.value);
    final order = <int, int>{};
    for (var i = 0; i < visible.length; i++) {
      order[visible[i].value] = i;
    }
    final list = present.toList()
      ..sort((a, b) => (order[a] ?? 1000 + a).compareTo(order[b] ?? 1000 + b));
    return list;
  }

  bool isRunnerVisible(UserTrack user) =>
      selectedTrailValues.isEmpty ||
      selectedTrailValues.contains(trailValueForRunner(user));

  /// Runners passing the active trail-type filter.
  List<UserTrack> get visibleRunners =>
      userPositions.where(isRunnerVisible).toList(growable: false);

  /// Adds newly-seen lanes to the selection so new runners show by default,
  /// while keeping any deselections the user has already made.
  void _refreshTrailFilter() {
    for (final v in presentTrailValues) {
      if (_knownTrailValues.add(v)) selectedTrailValues.add(v);
    }
  }

  /// Toggles a lane in the filter. Refuses to clear the last one (a runner must
  /// always be visible) and nudges the user with a toast.
  void toggleTrailFilter(int value) {
    if (selectedTrailValues.contains(value)) {
      if (selectedTrailValues.length <= 1) {
        Get.snackbar(
          'Trail filter',
          'Please select at least one trail type',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      selectedTrailValues.remove(value);
    } else {
      selectedTrailValues.add(value);
    }
    _ensureSelectionVisible();
  }

  /// If the selected runner is filtered out, moves selection to the first
  /// still-visible runner so follow/camera never points at a hidden track.
  void _ensureSelectionVisible() {
    final sel = selectedRunnerId.value;
    if (sel != null) {
      final runner = _runnerById(sel);
      if (runner != null && isRunnerVisible(runner)) return;
    }
    final firstVisible = userPositions.firstWhereOrNull(isRunnerVisible);
    selectRunner(firstVisible?.id, recenter: false, syncPicker: true);
  }

  void setVisible(bool visible) {
    if (_isVisible == visible) return;
    _isVisible = visible;
    if (visible) {
      _startAutoUpdateTimer();
      _startCompass();
      // Immediately refresh when becoming visible
      unawaited(loadPositions());
    } else {
      _stopAutoUpdateTimer();
      _stopCompass();
    }
  }

  void _startAutoUpdateTimer() {
    _stopAutoUpdateTimer();
    if (!_isVisible || _isPlaybackActive || _isStaleEvent) return;
    _autoUpdateTimer = Timer.periodic(_autoUpdateInterval, (_) {
      if (_isStaleEvent) {
        _stopAutoUpdateTimer();
        return;
      }
      if (_isVisible && !_isPlaybackActive) {
        unawaited(loadPositions());
        unawaited(_loadPhotoCache());
      }
    });
  }

  void _stopAutoUpdateTimer() {
    _autoUpdateTimer?.cancel();
    _autoUpdateTimer = null;
  }

  void togglePlayback() {
    if (!timelineAvailable) return;
    // _isPlaybackActive (not just isAnimating) so pause also works in tilt
    // mode, where the ticker — not the AnimationController — drives playback.
    if (_isPlaybackActive) {
      _playbackController.stop();
      isPlaying.value = false;
      _startAutoUpdateTimer();
      return;
    }
    if (minTimestampMs.value == null) return;
    final bool restartFromBeginning = _isAtTimelineEnd();
    _applyPlaybackDurationFromZoom();
    if (currentTimestampMs.value == null || restartFromBeginning) {
      currentTimestampMs.value = minTimestampMs.value;
    }
    _playbackController.value = restartFromBeginning
        ? 0.0
        : _currentPlaybackProgress();
    isPlaying.value = true;
    _stopAutoUpdateTimer();
    // In tilt mode the periodic ticker advances the value; otherwise the
    // AnimationController plays as normal.
    if (!tiltEnabled.value) {
      unawaited(_playbackController.forward());
    } else {
      _lastTiltTick = null;
    }
  }

  void seekTo(double value) {
    // _isPlaybackActive so a scrub also pauses tilt-driven playback (where the
    // AnimationController isn't animating but the ticker is driving).
    if (_isPlaybackActive) {
      _playbackController.stop();
      isPlaying.value = false;
    }
    currentTimestampMs.value = value;
    // Keep the controller's progress in sync so resuming (tilt or normal)
    // continues from the scrubbed position rather than the pre-scrub one.
    final double? mn = minTimestampMs.value;
    final double? mx = maxTimestampMs.value;
    if (mn != null && mx != null && mx > mn) {
      _playbackController.value = ((value - mn) / (mx - mn)).clamp(0.0, 1.0);
    }
    _startAutoUpdateTimer();
  }

  void pausePlayback() {
    if (_playbackController.isAnimating) {
      _playbackController.stop();
    }
    isPlaying.value = false;
    _startAutoUpdateTimer();
  }

  void toggleFollow() {
    followRunner.value = !followRunner.value;
    if (followRunner.value) {
      // Re-engaging follow snaps straight back to the selected runner.
      _centerOnSelectedRunner();
    }
  }

  /// Cycles the manual playback speed (0.5 → 1 → 2 → 4 → …). No-op while tilt is
  /// enabled — tilt owns the rate then. Applies live so a change mid-playback
  /// takes effect immediately.
  void cycleSpeed() {
    if (tiltEnabled.value) return;
    final idx = _speedSteps.indexOf(playbackSpeed.value);
    playbackSpeed.value = _speedSteps[(idx + 1) % _speedSteps.length];
    if (isPlaying.value) _applyPlaybackDurationFromZoom();
  }

  /// True when tilt playback is effectively frozen (in the neutral band). Drives
  /// the red "paused" state of the speed bubble, mirroring web.
  bool get tiltPaused => tiltEnabled.value && tiltSpeed.value.abs() < 0.15;

  /// Recenters the map on the viewer's own location (locate button). Flies in to
  /// at least zoom 16 so the blue dot is comfortably framed; keeps the current
  /// zoom if already closer. No-op without a known position.
  void recenterOnUser() {
    final lat = deviceInfo.deviceLat;
    final lon = deviceInfo.deviceLon;
    if (lat == null || lon == null) return;
    final target = latlng.LatLng(lat, lon);
    final z = mapController.camera.zoom < 16.0 ? 16.0 : mapController.camera.zoom;
    mapController.move(target, z);
  }

  /// Whether to draw the GPS-accuracy halo — only when the fix is loose enough
  /// to be worth signalling (matches web's 25 m threshold).
  bool get showsAccuracyHalo {
    final acc = deviceInfo.deviceAccuracy;
    return appModel.hasLocationPermissions &&
        deviceInfo.deviceLat != null &&
        deviceInfo.deviceLon != null &&
        acc != null &&
        acc > 25.0;
  }

  /// Photo cues for the selected runner (timestamp + pin location + resolved
  /// URL) — one per `PHO::<id>` point whose photo is approved/visible to this
  /// viewer. Scoped to the selected runner only, mirroring web, so the showcase
  /// never pops photos from other tracks.
  List<PhotoCue> get _selectedRunnerCues {
    final id = selectedRunnerId.value;
    if (id == null) return const <PhotoCue>[];
    final runner = userPositions.firstWhereOrNull((r) => r.id == id);
    if (runner == null) return const <PhotoCue>[];
    final prefix = '${HashRunPointTypes.photo.key}::'; // 'PHO::'
    final cues = <PhotoCue>[];
    for (final p in runner.positions) {
      final t = p.type ?? '';
      if (!t.startsWith(prefix)) continue;
      final rawId = t.substring(prefix.length).split('~').first.trim();
      final url = rawId.startsWith('http')
          ? rawId
          : _photoUrlCache[rawId.toLowerCase()];
      if (url == null || url.isEmpty) continue;
      cues.add(PhotoCue(
        timestampMs: p.timestampMs,
        point: latlng.LatLng(p.lat, p.lng),
        url: url,
      ));
    }
    return cues;
  }

  /// True when the selected runner has at least one showable photo — gates the
  /// Camera (auto-showcase) toggle so it only appears when there's something to
  /// show.
  bool get selectedRunnerHasPhotos => _selectedRunnerCues.isNotEmpty;

  void togglePhotoShowcase() {
    photoShowcaseArmed.value = !photoShowcaseArmed.value;
    if (!photoShowcaseArmed.value && photoShowcase.value != null) {
      _endShowcase();
    }
  }

  /// Manually dismiss the active showcase (tap-to-close) and resume playback.
  void dismissShowcase() => _endShowcase();

  /// Fires the showcase when the playhead crosses a photo cue (either
  /// direction) during playback. Only while playing, so scrubbing onto a photo
  /// doesn't trigger it (matches web, where a scrub cancels the showcase).
  void _maybeTriggerShowcase(double prevMs, double curMs) {
    if (!photoShowcaseArmed.value ||
        !isPlaying.value ||
        photoShowcase.value != null ||
        prevMs == curMs) {
      return;
    }
    for (final cue in _selectedRunnerCues) {
      final t = cue.timestampMs.toDouble();
      final crossed =
          (prevMs < t && t <= curMs) || (curMs <= t && t < prevMs);
      if (crossed) {
        _startShowcase(cue);
        return;
      }
    }
  }

  /// The rate that drives the photo zoom. In tilt mode it follows the tilt
  /// speed (0 in the neutral/stop band → freeze); it is SIGNED, and
  /// [_showcaseFrame] applies it relative to the entry direction so rocking the
  /// phone scrubs the zoom in and out. With tilt off it follows the chosen
  /// (always-forward) playback speed.
  double get _showcaseSpeed {
    if (tiltEnabled.value) {
      final s = tiltSpeed.value;
      return s.abs() < 0.15 ? 0.0 : s; // clean freeze in the neutral band
    }
    return playbackSpeed.value;
  }

  void _startShowcase(PhotoCue cue) {
    _showcaseResumeAfter = isPlaying.value;
    // Direction the run was being navigated when the photo triggered: forward
    // (+1) enters from the right and exits left; reverse (−1, only possible
    // under tilt) mirrors it.
    _showcaseDir = (tiltEnabled.value && tiltSpeed.value < 0) ? -1.0 : 1.0;
    if (_playbackController.isAnimating) _playbackController.stop();
    isPlaying.value = false; // freezes both normal and tilt playback
    photoShowcase.value = PhotoShowcaseState(url: cue.url, point: cue.point);
    showcaseZoom.value = 0.0;
    showcasePan.value = _showcaseDir; // start on the leading side
    _showcaseVirtualMs = 0.0;
    _lastShowcaseStamp = null;
    _scheduleShowcaseFrame();
  }

  void _scheduleShowcaseFrame({bool rescheduling = false}) {
    _showcaseFrameCallbackId = WidgetsBinding.instance
        .scheduleFrameCallback(_showcaseFrame, rescheduling: rescheduling);
  }

  void _cancelShowcaseFrame() {
    final int? id = _showcaseFrameCallbackId;
    if (id != null) {
      WidgetsBinding.instance.cancelFrameCallbackWithId(id);
      _showcaseFrameCallbackId = null;
    }
  }

  // Below this the zoom/pan has moved too little to be worth a redraw. On a
  // [0..1] envelope that grows the photo ~200px, 0.004 is well under one pixel —
  // it just suppresses the flurry of sub-visible writes during slow scrubbing.
  static const double _showcaseCommitEpsilon = 0.004;

  /// Vsync frame callback that advances the showcase. Runs at most once per
  /// rendered frame; reschedules itself until the show ends.
  void _showcaseFrame(Duration stamp) {
    _showcaseFrameCallbackId = null;
    if (photoShowcase.value == null) {
      _endShowcase();
      return;
    }

    final Duration? last = _lastShowcaseStamp;
    _lastShowcaseStamp = stamp;
    if (last == null) {
      _scheduleShowcaseFrame(rescheduling: true); // first frame just seeds the clock
      return;
    }

    final double rawDtMs = (stamp - last).inMicroseconds / 1000.0;
    if (rawDtMs <= 0) {
      _scheduleShowcaseFrame(rescheduling: true);
      return;
    }
    // Cap the step: a dropped frame / GC hitch (or a resume after backgrounding)
    // should ease forward, not teleport the zoom to the end.
    final double dtMs = rawDtMs > 100.0 ? 100.0 : rawDtMs;

    // Progress is driven by the speed RELATIVE to the entry direction
    // (_showcaseDir): rock WITH the run to zoom the photo in, rock AGAINST it to
    // zoom back out, hold at the neutral tilt to freeze. This works identically
    // whether the photo was crossed going forward or backward, because a reverse
    // entry has dir = −1, so a continued reverse tilt (negative speed) still
    // advances the zoom.
    final double speed = _showcaseSpeed;
    _showcaseVirtualMs += dtMs * speed * _showcaseDir;

    const total = _showInMs + _showHoldMs + _showOutMs;
    if (_showcaseVirtualMs >= total) {
      _endShowcase(); // played fully through — resume playback
      return;
    }
    if (_showcaseVirtualMs <= 0.0) {
      _endShowcase(); // rocked back to the entry — dismiss and resume
      return;
    }

    final double e = _showcaseVirtualMs;
    double z;
    if (e < _showInMs) {
      z = Curves.easeOut.transform(e / _showInMs);
    } else if (e < _showInMs + _showHoldMs) {
      z = 1.0;
    } else {
      final o = (e - _showInMs - _showHoldMs) / _showOutMs;
      z = 1.0 - Curves.easeIn.transform(o.clamp(0.0, 1.0));
    }

    // Horizontal navigation cue: enter from the leading side (right when
    // forward), pass through centre at peak zoom, exit the trailing side (left).
    // Direction is fixed at trigger time (_showcaseDir), so a photo crossed
    // while navigating backward sweeps the opposite way.
    double pan;
    if (e < _showInMs) {
      pan = _showcaseDir * (1.0 - (e / _showInMs)); // leading side → centre
    } else if (e < _showInMs + _showHoldMs) {
      pan = 0.0; // hold at centre
    } else {
      final o = ((e - _showInMs - _showHoldMs) / _showOutMs).clamp(0.0, 1.0);
      pan = -_showcaseDir * o; // centre → trailing side
    }

    _commitShowcaseValues(z.clamp(0.0, 1.0), pan);
    _scheduleShowcaseFrame(rescheduling: true);
  }

  /// Writes zoom/pan only when they've moved a visible amount since the last
  /// committed value (or hit a phase endpoint), so tiny sub-pixel steps don't
  /// each trigger an overlay rebuild. GetX already suppresses identical writes;
  /// this also suppresses near-identical ones.
  void _commitShowcaseValues(double z, double pan) {
    final bool zAtEnd = z == 0.0 || z == 1.0;
    if (zAtEnd || (z - showcaseZoom.value).abs() >= _showcaseCommitEpsilon) {
      showcaseZoom.value = z;
    }
    final bool panAtEnd = pan == 0.0;
    if (panAtEnd || (pan - showcasePan.value).abs() >= _showcaseCommitEpsilon) {
      showcasePan.value = pan;
    }
  }

  void _endShowcase() {
    _cancelShowcaseFrame();
    _showcaseVirtualMs = 0.0;
    _lastShowcaseStamp = null;
    photoShowcase.value = null;
    showcaseZoom.value = 0.0;
    showcasePan.value = 0.0;
    if (_showcaseResumeAfter && !_isAtTimelineEnd()) {
      _showcaseResumeAfter = false;
      isPlaying.value = true;
      // Tilt playback resumes via its own ticker (which checks isPlaying);
      // normal playback needs the AnimationController restarted.
      if (!tiltEnabled.value) {
        unawaited(
          _playbackController.forward(
            from: _playbackController.value.clamp(0.0, 1.0),
          ),
        );
      }
    } else {
      _showcaseResumeAfter = false;
    }
  }

  // ── Tilt-to-scrub ──────────────────────────────────────────────────────────

  void toggleTilt() {
    if (tiltEnabled.value) {
      _stopTilt();
    } else {
      _startTilt();
    }
  }

  void _startTilt() {
    tiltEnabled.value = true;
    _tiltNeutralDeg = null;
    _tiltCalibSamples.clear();
    _tiltEma = 1.0;
    tiltSpeed.value = 1.0;
    _lastTiltTick = null;

    _tiltSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(_onTiltAccel, onError: (Object _) => _stopTilt());

    // Manual drive replaces the AnimationController while tilt is active.
    if (_playbackController.isAnimating) _playbackController.stop();
    _tiltTicker = Timer.periodic(
      const Duration(milliseconds: 33),
      (_) => _tiltDriveTick(),
    );
  }

  void _stopTilt() {
    unawaited(_tiltSub?.cancel());
    _tiltSub = null;
    _tiltTicker?.cancel();
    _tiltTicker = null;
    _tiltNeutralDeg = null;
    _tiltEma = 1.0;
    tiltSpeed.value = 1.0;
    tiltEnabled.value = false;
    // Hand playback back to the AnimationController if we were mid-play.
    if (isPlaying.value && timelineAvailable) {
      _applyPlaybackDurationFromZoom();
      unawaited(
        _playbackController.forward(
          from: _playbackController.value.clamp(0.0, 1.0),
        ),
      );
    }
  }

  void _onTiltAccel(AccelerometerEvent e) {
    // Pitch: 0° upright (portrait), +90° flat screen-up. Gravity is included in
    // the plain accelerometer stream, so atan2(z, y) gives the holding angle.
    final double pitch = math.atan2(e.z, e.y) * 180.0 / math.pi;

    // Calibrate: average the first samples as the neutral holding angle.
    if (_tiltNeutralDeg == null) {
      _tiltCalibSamples.add(pitch);
      if (_tiltCalibSamples.length >= 10) {
        _tiltNeutralDeg =
            _tiltCalibSamples.reduce((a, b) => a + b) /
            _tiltCalibSamples.length;
      }
      return;
    }

    // Away (screen flattening upward) = positive delta = faster.
    final double delta = pitch - _tiltNeutralDeg!;
    double target;
    if (delta.abs() <= _tiltDeadDeg) {
      target = 1.0;
    } else if (delta > 0) {
      target = 1.0 +
          math.min((delta - _tiltDeadDeg) / _tiltSpanDeg, 1.0) * 3.0; // → ×4
    } else {
      target = 1.0 +
          math.max((delta + _tiltDeadDeg) / _tiltSpanDeg, -1.0) * 3.0; // → −×2
    }
    // Widened paused band: snap a small speed to a clean freeze so it's easy to
    // hold playback still (rather than the freeze being a single exact angle).
    if (target.abs() <= _tiltNeutralBand) target = 0.0;
    // Smooth (EMA) so hand shake doesn't jitter the playback rate.
    _tiltEma = _tiltEma * 0.8 + target * 0.2;
    if ((tiltSpeed.value - _tiltEma).abs() > 0.1) {
      tiltSpeed.value = _tiltEma;
    }
  }

  void _tiltDriveTick() {
    if (!tiltEnabled.value || !isPlaying.value || !timelineAvailable) {
      _lastTiltTick = null;
      return;
    }
    final now = DateTime.now();
    final int dtMs = _lastTiltTick == null
        ? 0
        : now.difference(_lastTiltTick!).inMilliseconds;
    _lastTiltTick = now;
    if (dtMs <= 0) return;

    // Base (speed-1) duration so tilt rate is unaffected by the speed button.
    final int durMs =
        (_lastBaseDuration ?? _playbackController.duration)
                ?.inMilliseconds ??
            10000;
    final double dv = dtMs / durMs * _tiltEma;
    // Hold at either bound instead of stopping — tilting the other way
    // resumes from there, which makes tilt-scrubbing feel continuous.
    _playbackController.value =
        (_playbackController.value + dv).clamp(0.0, 1.0);
  }

  void updateTrueNorthLock(bool value) {
    if (_trueNorthLock.value == value) return;
    _trueNorthLock.value = value;
    if (value) {
      mapController.rotate(0.0);
      _lastRotationDeg = 0.0;
    } else {
      _updateCameraForSelection();
    }
  }

  void selectRunner(
    String? userId, {
    bool recenter = true,
    bool syncPicker = false,
  }) {
    if (selectedRunnerId.value == userId) {
      if (recenter && userId != null) {
        _moveToRunner(userId);
      }
      return;
    }
    selectedRunnerId.value = userId;
    if (userId == null) return;
    if (recenter) {
      _moveToRunner(userId);
    }
    if (syncPicker) {
      syncRunnerPickerToSelection(animated: true, onlyIfMismatch: true);
    }
  }

  Color _colorForUser(String id) => _colorById[id] ?? _trackColors.first;

  /// Assigns each runner a stable palette colour by order of appearance in the
  /// loaded set, keyed by id — mirrors public-web (`users.forEach((u,i) => …)`)
  /// so a runner is the same colour on both platforms (both receive the same
  /// server-ordered user list). Reassigned every load; filtering never touches it.
  void _assignRunnerColors(List<UserTrack> users) {
    _colorById.clear();
    for (var i = 0; i < users.length; i++) {
      _colorById[users[i].id] = _trackColors[i % _trackColors.length];
    }
  }

  Widget _buildRunnerMarker(String? logo, {required bool isHighlighted}) {
    final double imageSize = isHighlighted ? 43 : 43;
    //final borderRadius = BorderRadius.circular(12);
    final glowColor = hc_blue.withValues(alpha: 0.65);

    return Stack(
      alignment: AlignmentDirectional.topCenter,
      clipBehavior: Clip.none,
      children: [
        Image.asset('images/icons/grey_square_pin.png'),
        Positioned(
          top: isHighlighted ? 8 : 8,
          child: Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              //borderRadius: borderRadius,
              boxShadow: isHighlighted
                  ? [
                      BoxShadow(
                        color: glowColor,
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                      const BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ]
                  : const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            child: ClipRRect(
              //borderRadius: borderRadius,
              child: Image(
                image: avatarImageProvider(logo),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  _ParsedCheckpointType? _parseCheckpointType(String? rawType) {
    final value = rawType?.trim();
    if (value == null || value.isEmpty) return null;

    final parts = value.split('::');
    final typeKey = parts.first.trim();

    // Trail-type declarations ride in the type field but are metadata, not
    // checkpoints — never draw them.
    if (typeKey == 'TRL') return null;

    // New grammar: `GLY::id` / `TXT::text` with order-independent ::L= / ::A=
    // attributes (unknown attrs ignored). See docs/trail_markers/SPEC.md §3.
    if (typeKey == 'GLY' || typeKey == 'TXT') {
      final primary = parts.length > 1 ? parts[1] : '';
      String? attrLabel;
      String? action;
      for (final seg in parts.skip(2)) {
        final s = seg.trim();
        if (s.startsWith('L=')) {
          attrLabel = s.substring(2);
        } else if (s.startsWith('A=')) {
          action = s.substring(2);
        }
      }
      final label = _cleanMarkLabel(attrLabel);
      if (typeKey == 'GLY') {
        if (primary.isEmpty) return null;
        return _ParsedCheckpointType(
          glyphId: primary,
          customLabel: label,
          action: action,
        );
      }
      if (primary.trim().isEmpty) return null;
      return _ParsedCheckpointType(
        text: primary,
        customLabel: label,
        action: action,
      );
    }

    final label = _cleanMarkLabel(
      parts.length > 1 ? parts.sublist(1).join('::').trim() : null,
    );

    // Legacy slot icon (e.g. 'I-100.png') — use asset filename directly.
    if (typeKey.startsWith('I-')) {
      return _ParsedCheckpointType(slotIcon: typeKey, customLabel: label);
    }

    // Legacy: resolve via HashRunPointTypes enum.
    try {
      final type = HashRunPointTypes.fromKey(typeKey);
      if (type == null) return null;
      return _ParsedCheckpointType(type: type, customLabel: label);
    } catch (_) {
      return null;
    }
  }

  /// Normalises a raw mark label: strips the retired mark-multiplication
  /// diagnostic suffix (`~tapId`) still present on marks stored while the
  /// instrumentation was live, and maps empty → null.
  String? _cleanMarkLabel(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceFirst(RegExp(r'~\d+$'), '').trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  Widget _buildCheckpointMarker(_ParsedCheckpointType parsed) {
    final type = parsed.type;
    final customLabel = parsed.customLabel;

    // PHO markers: customLabel is the blob sub-path, not a display label.
    if (type == HashRunPointTypes.photo) {
      return _buildPhotoMarker(customLabel ?? '');
    }

    final bool showLabel = customLabel != null && customLabel.isNotEmpty;
    final bool isCaution =
        type == HashRunPointTypes.caution || parsed.glyphId == 'caution';

    final Widget icon;
    if (parsed.glyphId != null || parsed.text != null) {
      icon = _buildTileCheckpointIcon(
        glyphId: parsed.glyphId,
        text: parsed.text,
      );
    } else if (parsed.slotIcon != null) {
      icon = _buildSlotCheckpointIcon(parsed.slotIcon!);
    } else {
      icon = _buildCheckpointIcon(type!);
    }

    if (!showLabel) return icon;

    final double scale = _markerScale();
    const double baseIconSize = 72.0;
    final double labelMaxWidth = 120.0 * scale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: isCaution ? Colors.red.shade600 : Colors.yellow.shade200,
            border: Border.all(
              color: isCaution ? Colors.red.shade800 : Colors.red,
              width: 1.6,
            ),
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: labelMaxWidth),
            child: Text(
              customLabel,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isCaution ? Colors.white : Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4.0),
        SizedBox(
          width: baseIconSize * scale,
          height: baseIconSize * scale,
          child: icon,
        ),
      ],
    );
  }

  Widget _buildCheckpointIcon(HashRunPointTypes type) {
    final double scale = _markerScale();
    const double baseIconSize = 72.0;
    final double size = baseIconSize * scale;

    return Image.asset(
      'images/live_run_map_markers/${type.pngIcon}',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          Icon(type.iconData, color: type.color, size: size * 0.8),
    );
  }

  Widget _buildSlotCheckpointIcon(String icon) {
    final double scale = _markerScale();
    const double baseIconSize = 72.0;
    final double size = baseIconSize * scale;

    return Image.asset(
      'images/live_run_map_markers/$icon',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          Icon(Icons.place, color: customRed, size: size * 0.8),
    );
  }

  /// Renders a new-model mark (glyph or text) as the standard square tile —
  /// the same look as the control grid and public web. Tracks carry no invert
  /// flag, so map marks always use the standard yellow/dark palette.
  Widget _buildTileCheckpointIcon({String? glyphId, String? text}) {
    const Color yellow = Color(0xFFFCFF04);
    const Color ink = Color(0xFF2D0000);
    final double size = 72.0 * _markerScale();

    Widget content;
    if (text != null) {
      final lines = text.trim().split(' ').where((l) => l.isNotEmpty).toList();
      content = FittedBox(
        fit: BoxFit.contain,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final line in lines)
              Text(
                line,
                style: const TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
          ],
        ),
      );
    } else {
      final glyph = glyphById(glyphId);
      content = glyph == null
          ? const Icon(Icons.help_outline, color: ink)
          : Image.asset(
              glyph.assetPath,
              fit: BoxFit.contain,
              color: glyph.fixed ? null : ink,
              colorBlendMode: glyph.fixed ? null : BlendMode.srcIn,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.place, color: customRed),
            );
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        color: yellow,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _buildPhotoMarker(String? label) {
    const double baseSize = 144.0;
    final double size = baseSize * _photoMarkerScale();

    // New format: label is a photoId UUID → look up blobUrl in the cache.
    // Legacy format: label is a full blob URL (markers stored before this
    // change) → use directly so old runs continue to display correctly.
    final String? resolvedUrl;
    if (label == null || label.isEmpty) {
      resolvedUrl = null;
    } else if (label.startsWith('http')) {
      resolvedUrl = label;
    } else {
      resolvedUrl = _photoUrlCache[label.toLowerCase()];
    }

    // No URL resolved → photo not yet approved for this viewer. Hide the
    // marker entirely rather than showing an empty camera frame.
    if (resolvedUrl == null) return const SizedBox.shrink();

    final String? resolvedLabel = label?.toLowerCase();
    final String? assetId =
        resolvedLabel != null ? _photoAssetIdCache[resolvedLabel] : null;

    final marker = CameraPhotoMarker(
      photoUrl: resolvedUrl,
      size: size,
      assetId: assetId,
      isOwnPhoto: assetId != null && _currentUserId != null,
      cachedOrientation: _photoOrientationCache[resolvedUrl],
      onOrientationDetected: (url, isLandscape) =>
          _photoOrientationCache[url] = isLandscape,
    );

    final photoItems = _orderedPhotoItems;
    final tappedIndex =
        photoItems.indexWhere((p) => p.imageUrl == resolvedUrl);

    return GestureDetector(
      onTap: () => Navigator.of(navigatorKey.currentContext!).push(
        MaterialPageRoute<void>(
          builder: (_) => MapPhotoPage(
            pageTitle: event.eventName,
            photos: photoItems,
            initialIndex: tappedIndex.clamp(0, photoItems.length - 1),
            background: Backgrounds.defaultHcBackground(),
          ),
        ),
      ),
      child: marker,
    );
  }

  // Builds the ordered list of resolved photo items from userPositions for the
  // carousel. Order matches the order markers appear on the track. Photos whose
  // URL has not yet resolved (not approved / not fetched) are excluded.
  List<MapPhotoItem> get _orderedPhotoItems {
    final seen = <String>{};
    final items = <MapPhotoItem>[];
    for (final user in userPositions) {
      for (final point in user.positions) {
        final parsed = _parseCheckpointType(point.type);
        if (parsed == null || parsed.type != HashRunPointTypes.photo) continue;
        final label = parsed.customLabel;
        if (label == null || label.isEmpty) continue;
        final lowerLabel = label.toLowerCase();
        final String? url =
            label.startsWith('http') ? label : _photoUrlCache[lowerLabel];
        if (url == null) continue;
        if (!seen.add(url)) continue; // deduplicate legacy-URL markers
        final caption = _photoCaptionCache[lowerLabel] ?? '';
        final userId = _photoUploaderIdCache[lowerLabel] ?? '';
        items.add(MapPhotoItem(
          imageUrl: url,
          caption: caption,
          uploaderName: _uploaderNameCache[userId] ?? '',
          uploaderPhotoUrl: _uploaderPhotoCache[userId] ?? '',
        ));
      }
    }
    return items;
  }

  double _markerScale() {
    final double zoom = _mapReady ? mapController.camera.zoom : initialZoom;
    final double ratio = zoom / initialZoom;
    final double scaled = ratio / 1.5; // reduce size by ~150% relative to zoom
    return scaled.clamp(0.10, 3.0);
  }

  // Photo markers interpolate between two pixel-size anchors using a quadratic
  // curve (t²) so they shrink faster as you zoom out while keeping both ends fixed:
  //   initialZoom (full-run view) → 50 px
  //   maxZoom     (closest zoom)  → 360 px  (≈ fills a phone screen horizontally)
  double _photoMarkerScale() {
    const double baseSize    = 144.0;
    const double pxAtInitial =  50.0;
    const double pxAtMax     = 360.0;
    if (maxZoom <= initialZoom) return pxAtMax / baseSize;
    final double zoom = _mapReady ? mapController.camera.zoom : initialZoom;
    final double t = ((zoom - initialZoom) / (maxZoom - initialZoom)).clamp(0.0, 1.0);
    final double tCurved = t * t; // quadratic: faster shrink toward initialZoom
    return (pxAtInitial + (pxAtMax - pxAtInitial) * tCurved) / baseSize;
  }

  String _formatDistanceLabel() {
    final meters = _selectedRunnerDistanceMeters();
    if (meters == null) return '';
    final miles = meters * METERS_TO_MILES;
    final kilometers = meters / 1000.0;
    final milesLabel = miles >= 10
        ? miles.toStringAsFixed(1)
        : miles.toStringAsFixed(2);
    final kmLabel = kilometers >= 10
        ? kilometers.toStringAsFixed(1)
        : kilometers.toStringAsFixed(2);
    return '$milesLabel mi / $kmLabel km';
  }

  double? _selectedRunnerDistanceMeters() {
    final runner = _runnerById(selectedRunnerId.value);
    if (runner == null) return null;
    final cutoff = timelineAvailable ? currentTimestampMs.value : null;
    return _sumInterpolatedDistance(_interpolatedTrackPoints(runner, cutoff));
  }

  double _sumInterpolatedDistance(List<_InterpolatedPoint> track) {
    if (track.length < 2) return 0.0;
    var total = 0.0;
    for (var i = 1; i < track.length; i++) {
      final prev = track[i - 1];
      final curr = track[i];
      if (prev.lat == curr.lat && prev.lng == curr.lng) continue;
      total += _distanceCalculator(
        latlng.LatLng(prev.lat, prev.lng),
        latlng.LatLng(curr.lat, curr.lng),
      );
    }
    return total;
  }

  void _initializeTimelineBounds() {
    final timestamps = userPositions
        .expand((user) => user.positions)
        .map((pos) => pos.timestampMs)
        .whereType<num>()
        .toList(growable: false);
    if (timestamps.isEmpty) {
      pausePlayback();
      minTimestampMs.value = null;
      maxTimestampMs.value = null;
      currentTimestampMs.value = null;
      _playbackController.value = 0.0;
      return;
    }
    timestamps.sort();
    final double newMin = timestamps.first.toDouble();
    final double newMax = timestamps.last.toDouble();
    final double? previousMax = maxTimestampMs.value;
    final double? current = currentTimestampMs.value;
    minTimestampMs.value = newMin;
    maxTimestampMs.value = newMax;

    // On the first load (no position yet) jump to the latest point. On later
    // reloads — notably the 15s auto-update for a run that isn't 24h-stale yet —
    // do NOT snap the scrubber to the end: preserve where the user parked it so
    // they can review the run. Only keep following the live edge if they were
    // already sitting at the end.
    final double resolved;
    if (current == null || (previousMax != null && current >= previousMax)) {
      resolved = newMax;
    } else {
      resolved = current.clamp(newMin, newMax).toDouble();
    }
    currentTimestampMs.value = resolved;
    pausePlayback();
    final double span = newMax - newMin;
    _playbackController.value = span <= 0
        ? 1.0
        : ((resolved - newMin) / span).clamp(0.0, 1.0).toDouble();
  }

  void _ensureSelection() {
    if (userPositions.isEmpty) {
      selectedRunnerId.value = null;
      return;
    }
    final selectedId = selectedRunnerId.value;
    final exists =
        selectedId != null &&
        userPositions.any((runner) => runner.id == selectedId);
    if (exists) return;

    // Prefer current user if present in the fetched positions
    if (_currentUserId != null) {
      final self = userPositions.firstWhereOrNull(
        (runner) => runner.id == _currentUserId,
      );
      if (self != null) {
        selectRunner(self.id, recenter: false, syncPicker: true);
        return;
      }
    }

    // Fallback to first runner
    selectRunner(userPositions.first.id, recenter: false, syncPicker: true);
  }

  void _handlePlaybackTick() {
    if (!timelineAvailable ||
        minTimestampMs.value == null ||
        maxTimestampMs.value == null) {
      return;
    }
    final span = maxTimestampMs.value! - minTimestampMs.value!;
    final prev = currentTimestampMs.value ?? minTimestampMs.value!;
    final next = minTimestampMs.value! + (span * _playbackController.value);
    currentTimestampMs.value = next;
    _maybeTriggerShowcase(prev, next);
  }

  Future<void> _hydrateLogos(List<UserTrack> users) async {
    for (final user in users) {
      if (userLogos.containsKey(user.id)) {
        continue;
      }
      final userData = await QueryUsers.querySingleUser(user.id);
      if (userData.isEmpty) continue;
      final logoUrl =
          userData.first[tableModel.hashersTableHelper.colPhoto] as String?;
      if (logoUrl != null && logoUrl.isNotEmpty) {
        userLogos[user.id] = logoUrl;
      }
      userNames[user.id] = _preferredDisplayName(userData.first);
    }
  }

  String _preferredDisplayName(Map<String, dynamic> record) {
    final hashName =
        record[tableModel.hashersTableHelper.colHashName] as String?;
    final dispName =
        record[tableModel.hashersTableHelper.colDispName] as String?;
    final firstName =
        record[tableModel.hashersTableHelper.colFirstName] as String?;
    final lastName =
        record[tableModel.hashersTableHelper.colLastName] as String?;

    String pick(String? value) =>
        (value != null && value.trim().isNotEmpty) ? value.trim() : '';

    final ordered = [
      pick(hashName),
      pick(dispName),
      [pick(firstName), pick(lastName)].where((p) => p.isNotEmpty).join(' '),
    ];

    return ordered.firstWhere(
      (name) => name.isNotEmpty,
      orElse: () => 'Runner',
    );
  }

  Polyline? _buildPolylineForUser(
    UserTrack user,
    double? cutoff, {
    double alpha = 0.85,
    double strokeWidth = 4.0,
  }) {
    final interpolated = _interpolatedTrackPoints(user, cutoff);
    if (interpolated.length < 2) {
      return null;
    }
    return Polyline(
      points: interpolated
          .map((pos) => latlng.LatLng(pos.lat, pos.lng))
          .toList(growable: false),
      strokeWidth: strokeWidth,
      color: _colorForUser(user.id).withValues(alpha: alpha.clamp(0.0, 1.0)),
    );
  }

  UserTrack? _runnerById(String? userId) {
    if (userId == null) return null;
    for (final runner in userPositions) {
      if (runner.id == userId) return runner;
    }
    return null;
  }

  void _moveToRunner(String userId) {
    if (selectedRunnerId.value != userId) return;
    _centerOnSelectedRunner();
  }

  int? _runnerIndex(String userId) {
    // Indexes into the *visible* list so the picker wheel and selection stay in
    // sync with what the trail-type filter is actually showing.
    final list = visibleRunners;
    for (var i = 0; i < list.length; i++) {
      if (list[i].id == userId) return i;
    }
    return null;
  }

  /// Centres the runner carousel on the current selection. With an equal
  /// half-viewport of leading/trailing padding, item `i` is centred at scroll
  /// offset `i * runnerTileExtent`. If the list isn't laid out yet (no clients),
  /// retries once on the next frame so the initial centring lands.
  void syncRunnerPickerToSelection({
    bool animated = false,
    bool onlyIfMismatch = false,
  }) {
    final selectedId = selectedRunnerId.value;
    if (selectedId == null) return;
    final index = _runnerIndex(selectedId);
    if (index == null) return;

    if (!runnerCarouselController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (runnerCarouselController.hasClients) {
          syncRunnerPickerToSelection(animated: false, onlyIfMismatch: true);
        }
      });
      return;
    }

    final target = index * runnerTileExtent;
    if (onlyIfMismatch &&
        (runnerCarouselController.offset - target).abs() < 1.0) {
      return;
    }

    if (animated) {
      unawaited(
        runnerCarouselController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        ),
      );
    } else {
      runnerCarouselController.jumpTo(target);
    }
  }

  /// Snaps the carousel to the nearest tile after a scroll gesture settles and
  /// selects that runner. Called from the widget's ScrollEndNotification.
  void onCarouselScrollEnd() {
    if (!runnerCarouselController.hasClients) return;
    final list = visibleRunners;
    if (list.isEmpty) return;
    final idx = (runnerCarouselController.offset / runnerTileExtent)
        .round()
        .clamp(0, list.length - 1);
    final target = idx * runnerTileExtent;
    if ((runnerCarouselController.offset - target).abs() > 0.5) {
      unawaited(
        runnerCarouselController.animateTo(
          target,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        ),
      );
    }
    final id = list[idx].id;
    if (selectedRunnerId.value != id) {
      selectRunner(id, recenter: true, syncPicker: false);
    }
  }

  // Follow-gated camera update — the automatic path (timeline ticks,
  // position refreshes). Explicit user actions call _centerOnSelectedRunner
  // directly so they work even with follow off.
  void _updateCameraForSelection() {
    if (!followRunner.value) return;
    _centerOnSelectedRunner();
  }

  void _centerOnSelectedRunner() {
    if (!_mapReady) return;
    final runner = _runnerById(selectedRunnerId.value);
    if (runner == null || runner.positions.isEmpty) return;
    final cutoff = timelineAvailable ? currentTimestampMs.value : null;
    final currentPoint = _interpolatedPosition(runner, cutoff);
    if (currentPoint == null) return;
    final target = latlng.LatLng(currentPoint.lat, currentPoint.lng);

    _animateCameraMove(target);
    _applyRunnerRotation(runner, cutoff);
  }

  void _animateCameraMove(latlng.LatLng target) {
    if (!_mapReady) return;
    final zoom = mapController.camera.zoom;
    mapController.move(target, zoom);
  }

  void _applyRunnerRotation(UserTrack runner, double? cutoff) {
    if (_trueNorthLock.value) {
      _lastRotationDeg = 0.0;
      return;
    }
    final heading = _runnerHeadingDegrees(runner, cutoff);
    if (heading == null) return;
    final desiredRotation = _normalizeDegrees(-heading);
    if (_lastRotationDeg != null &&
        (_lastRotationDeg! - desiredRotation).abs() < 1.0) {
      return;
    }
    mapController.rotate(desiredRotation);
    _lastRotationDeg = desiredRotation;
  }

  double? _runnerHeadingDegrees(UserTrack runner, double? cutoff) {
    if (runner.positions.length < 2) return null;
    final interpolated = _interpolatedPosition(runner, cutoff);
    if (interpolated == null) return null;

    final index = cutoff == null
        ? runner.positions.length - 1
        : _trackIndexAtTimestamp(runner, cutoff);
    if (index == null) return null;

    if (cutoff == null || index == runner.positions.length - 1) {
      if (runner.positions.length < 2) return null;
      final before = runner.positions[runner.positions.length - 2];
      final current = runner.positions.last;
      if (before.lat == current.lat && before.lng == current.lng) return null;
      return _bearingDegrees(before.lat, before.lng, current.lat, current.lng);
    }

    final prev = runner.positions[index];
    final prevLat = prev.lat;
    final prevLng = prev.lng;
    final targetLat = interpolated.lat;
    final targetLng = interpolated.lng;
    if (targetLat == prevLat && targetLng == prevLng) {
      if (index + 1 < runner.positions.length) {
        final next = runner.positions[index + 1];
        if (next.lat != prevLat || next.lng != prevLng) {
          return _bearingDegrees(prevLat, prevLng, next.lat, next.lng);
        }
      }
      if (index > 0) {
        final before = runner.positions[index - 1];
        if (before.lat != prevLat || before.lng != prevLng) {
          return _bearingDegrees(before.lat, before.lng, prevLat, prevLng);
        }
      }
      return null;
    }

    return _bearingDegrees(prevLat, prevLng, targetLat, targetLng);
  }

  int? _trackIndexAtTimestamp(UserTrack runner, double? cutoff) {
    if (runner.positions.isEmpty) return null;
    if (cutoff == null) return runner.positions.length - 1;
    for (var i = 0; i < runner.positions.length; i++) {
      final ts = runner.positions[i].timestampMs.toDouble();
      if (ts > cutoff) {
        return i == 0 ? 0 : i - 1;
      }
    }
    return runner.positions.length - 1;
  }

  List<_InterpolatedPoint> _interpolatedTrackPoints(
    UserTrack runner,
    double? cutoff,
  ) {
    if (runner.positions.isEmpty) return const [];
    if (cutoff == null) {
      final capped = <TrackPoint>[];
      for (final pos in runner.positions) {
        capped.add(pos);
        if (_isOnInn(pos.type)) break;
      }
      return capped
          .map(
            (pos) => _InterpolatedPoint(
              lat: pos.lat,
              lng: pos.lng,
              timestampMs: pos.timestampMs.toDouble(),
            ),
          )
          .toList(growable: false);
    }

    final results = <_InterpolatedPoint>[];
    for (final pos in runner.positions) {
      final ts = pos.timestampMs.toDouble();
      if (ts > cutoff) {
        break;
      }
      results.add(
        _InterpolatedPoint(lat: pos.lat, lng: pos.lng, timestampMs: ts),
      );
      if (_isOnInn(pos.type)) {
        break;
      }
    }
    if (results.isEmpty) {
      final first = runner.positions.first;
      results.add(
        _InterpolatedPoint(
          lat: first.lat,
          lng: first.lng,
          timestampMs: first.timestampMs.toDouble(),
        ),
      );
    }

    final interpolated = _interpolatedPosition(runner, cutoff);
    if (interpolated != null) {
      final last = results.isEmpty ? null : results.last;
      if (last == null ||
          last.lat != interpolated.lat ||
          last.lng != interpolated.lng) {
        results.add(interpolated);
      }
    }
    return results;
  }

  _InterpolatedPoint? _interpolatedPosition(UserTrack runner, double? cutoff) {
    if (runner.positions.isEmpty) return null;
    if (cutoff == null) {
      final last = runner.positions.last;
      return _InterpolatedPoint(
        lat: last.lat,
        lng: last.lng,
        timestampMs: last.timestampMs.toDouble(),
      );
    }
    final index = _trackIndexAtTimestamp(runner, cutoff);
    if (index == null) return null;
    final current = runner.positions[index];
    final currentTs = current.timestampMs.toDouble();
    if (index == runner.positions.length - 1 || cutoff <= currentTs) {
      return _InterpolatedPoint(
        lat: current.lat,
        lng: current.lng,
        timestampMs: cutoff,
      );
    }
    final next = runner.positions[index + 1];
    final nextTs = next.timestampMs.toDouble();
    if (nextTs <= currentTs) {
      return _InterpolatedPoint(
        lat: current.lat,
        lng: current.lng,
        timestampMs: cutoff,
      );
    }
    if (_isOnInn(current.type) || _isOnInn(next.type)) {
      return _InterpolatedPoint(
        lat: current.lat,
        lng: current.lng,
        timestampMs: cutoff,
      );
    }
    final ratio = ((cutoff - currentTs) / (nextTs - currentTs)).clamp(0.0, 1.0);
    return _InterpolatedPoint(
      lat: current.lat + (next.lat - current.lat) * ratio,
      lng: current.lng + (next.lng - current.lng) * ratio,
      timestampMs: cutoff,
    );
  }

  double _bearingDegrees(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) {
    final lat1 = _degToRad(fromLat);
    final lat2 = _degToRad(toLat);
    final dLon = _degToRad(toLng - fromLng);
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearing = math.atan2(y, x) * 180.0 / math.pi;
    return _normalizeDegrees(bearing);
  }

  double _degToRad(double value) => value * (math.pi / 180.0);

  double _normalizeDegrees(double value) {
    final normalized = value % 360.0;
    return normalized < 0 ? normalized + 360.0 : normalized;
  }

  /// True if [rawType] is a track terminator — the mark that ends the drawn
  /// polyline. New marks declare this via the `A=endRun` action; legacy marks
  /// are the On-Inn enum key. Named `_isOnInn` for historical call sites.
  bool _isOnInn(String? rawType) {
    final parsed = _parseCheckpointType(rawType);
    if (parsed == null) return false;
    return parsed.action == 'endRun' || parsed.type == HashRunPointTypes.onInn;
  }

  void _applyPlaybackDurationFromZoom({double? zoomOverride}) {
    final zoom = zoomOverride ?? _currentZoomForInterpolation();
    // Base (speed-1) duration drives the tilt ticker; the manual speed button
    // divides it for normal playback. Web applies the floor to the base and
    // lets speed scale freely below it, so no post-scale floor here.
    final base = _durationForZoom(zoom);
    _lastBaseDuration = base;
    final speed = playbackSpeed.value <= 0 ? 1.0 : playbackSpeed.value;
    final scaledMs = math.max(1, (base.inMilliseconds / speed).round());
    final newDuration = Duration(milliseconds: scaledMs);
    if (_lastPlaybackDuration == newDuration) return;

    final bool wasAnimating = _playbackController.isAnimating;
    final double currentProgress = _playbackController.value.clamp(0.0, 1.0);

    _lastPlaybackDuration = newDuration;
    _playbackController.duration = newDuration;

    if (wasAnimating) {
      // Restart from the same progress so speed matches the new duration.
      _playbackController.stop();
      unawaited(_playbackController.forward(from: currentProgress));
    }
  }

  Duration _durationForZoom(double zoom) {
    final km = _trailDistanceMeters() / 1000.0;
    final t = _zoomProgress(zoom);
    final msPerKm = _msPerKmFast + (_msPerKmSlow - _msPerKmFast) * t;
    final ms = (km * msPerKm).round();
    return ms > _minPlaybackDuration.inMilliseconds
        ? Duration(milliseconds: ms)
        : _minPlaybackDuration;
  }

  /// Total trail length in meters = the longest single runner's full track
  /// (OIN-terminated). Drives playback duration and is stable regardless of
  /// which runner is selected. Returns 0 before any track has loaded, which
  /// floors the duration; it is recomputed when playback starts (see
  /// [togglePlayback] → [_applyPlaybackDurationFromZoom]).
  double _trailDistanceMeters() {
    double max = 0.0;
    for (final runner in userPositions) {
      final d = _sumInterpolatedDistance(_interpolatedTrackPoints(runner, null));
      if (d > max) max = d;
    }
    return max;
  }

  double _currentPlaybackProgress() {
    if (!timelineAvailable ||
        minTimestampMs.value == null ||
        maxTimestampMs.value == null ||
        currentTimestampMs.value == null) {
      return 0.0;
    }
    final span = maxTimestampMs.value! - minTimestampMs.value!;
    if (span <= 0) return 0.0;
    final offset = (currentTimestampMs.value! - minTimestampMs.value!).clamp(
      0.0,
      span,
    );
    return offset / span;
  }

  bool _isAtTimelineEnd() {
    if (!timelineAvailable ||
        currentTimestampMs.value == null ||
        maxTimestampMs.value == null) {
      return false;
    }
    // Consider "at end" if within 100ms of max (handles floating point precision)
    const threshold = 100.0;
    return (maxTimestampMs.value! - currentTimestampMs.value!) <= threshold;
  }

  double _zoomProgress(double zoom) {
    if (zoom <= _zoomFastThreshold) return 0.0;
    if (zoom >= _zoomSlowThreshold) return 1.0;
    return (zoom - _zoomFastThreshold) /
        (_zoomSlowThreshold - _zoomFastThreshold);
  }

  double _currentZoomForInterpolation() {
    if (_mapReady) {
      return mapController.camera.zoom;
    }
    return initialZoom;
  }

  String _formatTimestamp(double? timestampMs) {
    if (timestampMs == null) return '--:--';
    final dt = DateTime.fromMillisecondsSinceEpoch(
      timestampMs.toInt(),
    ).toLocal();
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final dateLabel = '${dt.year}-${twoDigits(dt.month)}-${twoDigits(dt.day)}';
    final timeLabel =
        '${twoDigits(dt.hour)}:${twoDigits(dt.minute)}:${twoDigits(dt.second)}';
    return '$dateLabel $timeLabel';
  }
}

class _InterpolatedPoint {
  const _InterpolatedPoint({
    required this.lat,
    required this.lng,
    required this.timestampMs,
  });

  final double lat;
  final double lng;
  final double timestampMs;
}

/// A mark point paired with its parsed type and raw type string (the latter is
/// the dedup key in [RunTrackerMapController._dedupeNearbyMarks]).
typedef _MarkEntry = ({TrackPoint point, String type, _ParsedCheckpointType parsed});

class _ParsedCheckpointType {
  const _ParsedCheckpointType({
    this.type,
    this.slotIcon,
    this.glyphId,
    this.text,
    this.customLabel,
    this.action,
  }) : assert(
          type != null || slotIcon != null || glyphId != null || text != null,
        );

  final HashRunPointTypes? type; // legacy enum key
  final String? slotIcon; // legacy I-NNN.png filename
  final String? glyphId; // new GLY:: glyph id
  final String? text; // new TXT:: text (may contain spaces = newlines)
  final String? customLabel; // L= label (or legacy positional label)
  final String? action; // A= action, e.g. 'endRun'
}

/// A selected-runner photo cue: the timeline moment, the pin location the photo
/// grows out of, and its resolved image URL. Consumed by the photo showcase.
class PhotoCue {
  const PhotoCue({
    required this.timestampMs,
    required this.point,
    required this.url,
  });

  final int timestampMs;
  final latlng.LatLng point;
  final String url;
}

/// The photo currently being featured by the in-map showcase (its URL and the
/// map pin it grows from). The live 0→1 zoom progress is held separately in
/// [RunTrackerMapController.showcaseZoom] so the overlay animates without
/// rebuilding this object each frame.
class PhotoShowcaseState {
  const PhotoShowcaseState({required this.url, required this.point});

  final String url;
  final latlng.LatLng point;
}
