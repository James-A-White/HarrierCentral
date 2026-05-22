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
  static const Duration _playbackFastDuration = Duration(seconds: 10);
  static const Duration _playbackSlowDuration = Duration(seconds: 480);
  static const Duration _autoUpdateInterval = Duration(seconds: 15);

  final MapController mapController = MapController();
  final FixedExtentScrollController runnerPickerController =
      FixedExtentScrollController();
  final PageController timelineCarouselController = PageController();
  final RxInt timelineCarouselIndex = 0.obs;

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
  final latlng.Distance _distanceCalculator = const latlng.Distance();
  final String? _currentUserId = getStringPref(StringPrefsEnum.userId);

  // Reused across loadPositions() calls to avoid creating a new http.Client each time.
  final GetPositionsApi _positionsApi = GetPositionsApi();

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

    return userPositions
        .where((user) => !hasSelection || user.id != selectedId)
        .map((user) => _buildPolylineForUser(user, cutoff, alpha: baseAlpha))
        .whereType<Polyline>()
        .toList(growable: false);
  }

  Polyline? get highlightedPolyline {
    final runner = _runnerById(selectedRunnerId.value);
    if (runner == null) return null;
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

    for (final user in userPositions) {
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

  List<Marker> get checkpointMarkers {
    if (userPositions.isEmpty) return const [];
    final cutoff = timelineAvailable ? currentTimestampMs.value : null;

    return userPositions
        .expand((user) => user.positions)
        .where((point) {
          if ((point.type ?? '').trim().isEmpty) return false;
          if (cutoff != null && point.timestampMs.toDouble() > cutoff) {
            return false;
          }
          return true;
        })
        .map((point) {
          final parsedType = _parseCheckpointType(point.type);
          if (parsedType == null) return null;

          final bool hasAttachedLabel =
              (parsedType.customLabel?.isNotEmpty ?? false) &&
              (parsedType.type == HashRunPointTypes.customLabel ||
                  parsedType.type == HashRunPointTypes.caution);

          final double scale = _markerScale();
          const double baseIconSize = 72.0; // 60% of the prior 120 size
          const double baseLabelWidth = 140.0;
          const double baseLabelHeight = 140.0;

          final double markerWidth = hasAttachedLabel
              ? baseLabelWidth * scale
              : baseIconSize * scale;
          final double markerHeight = hasAttachedLabel
              ? baseLabelHeight * scale
              : baseIconSize * scale;

          return Marker(
            width: markerWidth,
            height: markerHeight,
            point: latlng.LatLng(point.lat, point.lng),
            alignment: Alignment.topCenter,
            child: _buildCheckpointMarker(
              parsedType.type,
              customLabel: parsedType.customLabel,
            ),
          );
        })
        .whereType<Marker>()
        .toList(growable: false);
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
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAutoUpdateTimer();
    _timelineWorker?.dispose();
    _selectionWorker?.dispose();
    unawaited(_mapEventsSub?.cancel());
    runnerPickerController.dispose();
    timelineCarouselController.dispose();
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

  void goToTimelinePage(int index) {
    if (index < 0 || index > 1) return;
    if (timelineCarouselController.hasClients) {
      unawaited(
        timelineCarouselController.animateToPage(
          index,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        ),
      );
    }
    timelineCarouselIndex.value = index;
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
      _initializeTimelineBounds();
      _ensureSelection();
      syncRunnerPickerToSelection(onlyIfMismatch: true, animated: false);
    } catch (error) {
      debugPrint('Error fetching positions: $error');
    }
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
    final customLabel = parts.length > 1
        ? parts.sublist(1).join('::').trim()
        : null;

    try {
      final type = HashRunPointTypes.fromKey(typeKey);
      if (type == null) return null;
      return _ParsedCheckpointType(
        type: type,
        customLabel: (customLabel != null && customLabel.isNotEmpty)
            ? customLabel
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildCheckpointMarker(HashRunPointTypes type, {String? customLabel}) {
    // PHO markers: the customLabel is the blob sub-path, not a display label.
    if (type == HashRunPointTypes.photo) {
      return _buildPhotoMarker(customLabel ?? '');
    }

    final bool showLabel =
        (type == HashRunPointTypes.customLabel ||
            type == HashRunPointTypes.caution) &&
        customLabel != null &&
        customLabel.isNotEmpty;

    final icon = _buildCheckpointIcon(type);

    if (!showLabel) return icon;

    final bool isCaution = type == HashRunPointTypes.caution;
    final double scale = _markerScale();
    const double baseIconSize = 72.0;
    // const double baseLabelWidth = 140.0;
    // const double baseLabelHeight = 140.0;
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

  Widget _buildPhotoMarker(String photoUrl) {
    final double scale = _markerScale();
    const double baseSize = 72.0;
    final double size = baseSize * scale;

    if (photoUrl.isEmpty || !photoUrl.startsWith('http')) {
      return Icon(
        HashRunPointTypes.photo.iconData,
        color: HashRunPointTypes.photo.color,
        size: size * 0.8,
      );
    }

    return CameraPhotoMarker(photoUrl: photoUrl, size: size);
  }

  double _markerScale() {
    final double zoom = _mapReady ? mapController.camera.zoom : initialZoom;
    final double ratio = zoom / initialZoom;
    final double scaled = ratio / 1.5; // reduce size by ~150% relative to zoom
    return scaled.clamp(0.10, 3.0);
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
    minTimestampMs.value = timestamps.first.toDouble();
    maxTimestampMs.value = timestamps.last.toDouble();
    currentTimestampMs.value = maxTimestampMs.value;
    pausePlayback();
    _playbackController.value = 1.0;
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
    for (var i = 0; i < userPositions.length; i++) {
      if (userPositions[i].id == userId) return i;
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
    final t = _zoomProgress(zoom);
    return _lerpDuration(_playbackFastDuration, _playbackSlowDuration, t);
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

  Duration _lerpDuration(Duration a, Duration b, double t) {
    final lerpedMs =
        (a.inMilliseconds + ((b.inMilliseconds - a.inMilliseconds) * t))
            .round();
    return Duration(milliseconds: lerpedMs);
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

class _ParsedCheckpointType {
  const _ParsedCheckpointType({required this.type, this.customLabel});

  final HashRunPointTypes type;
  final String? customLabel;
}
