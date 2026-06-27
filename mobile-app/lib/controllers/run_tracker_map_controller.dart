import 'dart:math' as math;

import 'package:harrier_central/imports.dart';
import 'package:harrier_central/util/track_point_filter.dart';
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
  }) : _trueNorthLock = trueNorthLock.obs,
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
  // time: the zoomed-out rate is 1 s/km (a 28 km run plays in 28 s, a 5 km run
  // in 5 s), and zooming in slows that down toward 8 s/km so detail is
  // watchable. The rate is interpolated by zoom between the two thresholds.
  static const double _msPerKmFast = 1000.0; // 1 s/km — fully zoomed out (≤ 15)
  static const double _msPerKmSlow = 8000.0; // 8 s/km — fully zoomed in (≥ 22)
  static const Duration _minPlaybackDuration =
      Duration(seconds: 3); // floor so a very short trail doesn't flash past
  static const Duration _autoUpdateInterval = Duration(seconds: 15);

  final MapController mapController = MapController();
  final FixedExtentScrollController runnerPickerController =
      FixedExtentScrollController();

  late final AnimationController _playbackController;
  bool _mapReady = false;
  bool _isVisible = false;
  double? _lastRotationDeg;
  Duration? _lastPlaybackDuration;
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

  // Trail-type filtering: the kennel's config (bundled by GetPositions on the
  // full fetch), the set of lanes currently shown, and the lanes ever seen so
  // newly-appearing lanes default to visible while user deselections persist.
  final RxnString trailTypesConfigJson = RxnString();
  final RxSet<int> selectedTrailValues = <int>{}.obs;
  final Set<int> _knownTrailValues = {};

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
      final logo = userLogos[user.id];
      if (logo == null || logo.isEmpty) continue;
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

  List<Marker> get checkpointMarkers => _buildCheckpointMarkers(photosOnly: false);
  List<Marker> get photoCheckpointMarkers => _buildCheckpointMarkers(photosOnly: true);

  List<Marker> _buildCheckpointMarkers({required bool photosOnly}) {
    if (userPositions.isEmpty) return const [];
    final cutoff = timelineAvailable ? currentTimestampMs.value : null;

    // Gather the mark points that belong on this layer (checkpoints vs photos).
    final entries = <_MarkEntry>[];
    for (final point in userPositions.expand((user) => user.positions)) {
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

  String get formattedTimelineLabel =>
      _formatTimestamp(currentTimestampMs.value);
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
    unawaited(loadPositions());
    unawaited(_loadPhotoCache());
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAutoUpdateTimer();
    _timelineWorker?.dispose();
    _selectionWorker?.dispose();
    unawaited(_mapEventsSub?.cancel());
    runnerPickerController.dispose();
    _playbackController.dispose();
    _positionsApi.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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
      if (updated) update();
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
      );
      _afterTimestampMs = data.latestServerTimestampMs;
      // Trail-type config arrives on the full fetch only; cache it (incremental
      // polls return null, so don't clobber the cached value).
      if (data.trailTypesConfigJson != null) {
        trailTypesConfigJson.value = data.trailTypesConfigJson;
      }
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
      // Immediately refresh when becoming visible
      unawaited(loadPositions());
    } else {
      _stopAutoUpdateTimer();
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
    if (_playbackController.isAnimating) {
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
    unawaited(_playbackController.forward());
  }

  void seekTo(double value) {
    if (_playbackController.isAnimating) {
      _playbackController.stop();
      isPlaying.value = false;
    }
    currentTimestampMs.value = value;
    _startAutoUpdateTimer();
  }

  void pausePlayback() {
    if (_playbackController.isAnimating) {
      _playbackController.stop();
    }
    isPlaying.value = false;
    _startAutoUpdateTimer();
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
    if (syncPicker && runnerPickerController.hasClients) {
      final index = _runnerIndex(userId);
      if (index != null) {
        unawaited(
          runnerPickerController.animateToItem(
            index,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
          ),
        );
      }
    }
  }

  Color _colorForUser(String id) {
    final colors = Colors.primaries;
    return colors[id.hashCode.abs() % colors.length];
  }

  Widget _buildRunnerMarker(String logo, {required bool isHighlighted}) {
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
              child: Image.network(logo, fit: BoxFit.cover),
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

    final customLabel = parts.length > 1
        ? parts.sublist(1).join('::').trim()
        : null;

    final label = (customLabel != null && customLabel.isNotEmpty)
        ? customLabel
        : null;

    // New-style slot icon (e.g. 'I-100.png') — use asset filename directly.
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

  Widget _buildCheckpointMarker(_ParsedCheckpointType parsed) {
    final type = parsed.type;
    final customLabel = parsed.customLabel;

    // PHO markers: customLabel is the blob sub-path, not a display label.
    if (type == HashRunPointTypes.photo) {
      return _buildPhotoMarker(customLabel ?? '');
    }

    final bool showLabel = customLabel != null && customLabel.isNotEmpty;
    final bool isCaution = type == HashRunPointTypes.caution;

    final icon = parsed.slotIcon != null
        ? _buildSlotCheckpointIcon(parsed.slotIcon!)
        : _buildCheckpointIcon(type!);

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
    currentTimestampMs.value =
        minTimestampMs.value! + (span * _playbackController.value);
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
    _updateCameraForSelection();
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

  void syncRunnerPickerToSelection({
    bool animated = false,
    bool onlyIfMismatch = false,
  }) {
    final selectedId = selectedRunnerId.value;
    if (selectedId == null) return;
    final index = _runnerIndex(selectedId);
    if (index == null) return;
    if (!runnerPickerController.hasClients) return;

    if (onlyIfMismatch && runnerPickerController.selectedItem == index) {
      return;
    }

    if (animated) {
      unawaited(
        runnerPickerController.animateToItem(
          index,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        ),
      );
    } else {
      runnerPickerController.jumpToItem(index);
    }
  }

  void _updateCameraForSelection() {
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

  bool _isOnInn(String? rawType) {
    final parsed = _parseCheckpointType(rawType);
    return parsed?.type == HashRunPointTypes.onInn;
  }

  void _applyPlaybackDurationFromZoom({double? zoomOverride}) {
    final zoom = zoomOverride ?? _currentZoomForInterpolation();
    final newDuration = _durationForZoom(zoom);
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
  const _ParsedCheckpointType({this.type, this.slotIcon, this.customLabel})
      : assert(type != null || slotIcon != null);

  final HashRunPointTypes? type;
  final String? slotIcon;
  final String? customLabel;
}
