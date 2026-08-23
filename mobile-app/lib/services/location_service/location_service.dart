// ignore_for_file: constant_identifier_names

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'on_inn_auto_stop.dart';
import 'run_point_buffer.dart';
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/util/track_point_filter.dart';

// Constants (replace with your actual constants)

String pad19(int epochMs) => epochMs.toString().padLeft(19, '0');

/// A slot mark captured at tap time but not yet committed to the track.
/// Holds everything needed to record the point later, exactly as it was at
/// the moment of the tap. See [LocationService.captureSlotMark] /
/// [LocationService.commitSlotMark].
class PendingSlotMark {
  const PendingSlotMark({
    required this.position,
    required this.tsMs,
    required this.rawType,
  });

  final Position position;
  final int tsMs;
  final String rawType;
}

// Tracking quality tiers — chosen by the user in preferences.
// 0 = Power Saver, 1 = Balanced, 2 = Best
// When unset (null pref), Best is the default.
LocationAccuracy _trackingAccuracy() {
  switch (getIntPref(IntPrefsEnum.trackingQuality) ?? 2) {
    case 0:
      return LocationAccuracy.medium;
    case 1:
      return LocationAccuracy.high;
    default:
      return LocationAccuracy.bestForNavigation;
  }
}

int _trackingDistanceFilter() {
  switch (getIntPref(IntPrefsEnum.trackingQuality) ?? 2) {
    case 0:
      return 20; // Power Saver: coarse track
    case 1:
      return 10; // Balanced: moderate
    default:
      return 5; // Best: fine-grained
  }
}

// Android update interval per tracking tier. Set explicitly (rather than derived
// from the distance filter) so the tiers get a real cadence progression
// 15s → 1min → 15min instead of the old 15s / 15s / 15min.
Duration _trackingAndroidInterval() {
  switch (getIntPref(IntPrefsEnum.trackingQuality) ?? 2) {
    case 0:
      return const Duration(minutes: 15); // Power Saver
    case 1:
      return const Duration(minutes: 1); // Balanced
    default:
      return const Duration(seconds: 15); // Best
  }
}

class LocationService extends GetxService {
  // Rx variable to hold the latest position, making it reactive
  final Rx<Position?> lastKnownPosition = Rx<Position?>(null);
  final Rx<DateTime> lastKnownPositionRead = Rx<DateTime>(DateTime(2000));
  final RxInt locationUpdateCount = 0.obs;

  final RxBool joinRunTracking = false.obs;
  String? eventId;
  String? userId;

  RunPointBuffer? _runBuffer;
  DateTime _lastFlushTime = DateTime.now();

  // Armed by [seedSessionTrack] on a stop→restart; consumed when the live
  // buffer is next touched, which forwards it as `resumed: true` on the
  // first batch that reaches the server (terminator cleanup).
  bool _resumedCleanupPending = false;

  // Throttle for the memory-usage breadcrumb emitted while tracking (~60s).
  DateTime? _lastMemLogTime;
  // Throttle for the on-disk lastLocationUpdate pref (~60s). The only reader
  // (CommonQueries.isAtRunStart) treats a fix as fresh within 15 min, so we
  // don't need to write GetStorage on every single position event.
  DateTime? _lastLocationPrefTime;
  // Throttle for the O(n) session-distance recompute (~10s). Filtering the whole
  // growing track on every point is O(n²) over a run; the distance readout does
  // not need per-point precision.
  DateTime? _lastSessionDistanceTime;

  // Filtered distance for the current tracking session.
  // Updated on every GPS point using the same TrackPointFilter as the map view.
  final RxDouble filteredSessionDistanceMeters = 0.0.obs;
  final List<TrackPoint> _sessionTrack = [];
  final TrackPointFilter _sessionFilter = TrackPointFilter();

  // Auto-pause state. When true, GPS is monitored at a finer interval but
  // no points are recorded. Tracking resumes automatically once the device
  // has moved >= _autoPauseResumeDistanceMeters from the pause point.
  final RxBool isPaused = false.obs;
  static const double _autoPauseResumeDistanceMeters = 100.0;
  latlng.LatLng? _pausePoint;
  // Prevents the ever(joinRunTracking) worker from resetting the session track
  // when transitioning from paused → tracking (vs. a fresh start).
  bool _isResumingFromPause = false;
  // Set when Start is pressed on a run that already holds a stored track (the
  // app was closed or tracking stopped mid-run). Tells the tracking-start
  // worker to keep the seeded session track instead of clearing it, so the
  // live distance HUD continues from where it left off instead of restarting
  // at zero. See [seedSessionTrack].
  bool _isResumingExistingTrack = false;
  Worker? _trackingWorker;

  // Last-known GPS coordinates held in memory only — not persisted to disk.
  // Used as a fallback position before the first live GPS fix is received.
  // Storing coordinates in plain GetStorage (unencrypted) is unnecessary as
  // the OS already provides getLastKnownPosition() at cold start.
  double? _cachedLat;
  double? _cachedLon;

  /// Reactive property that is true if the location has been updated in the last 60 seconds.
  /// Note: To make this indicator automatically turn OFF after 60 seconds,
  /// the consuming widget must be inside a timed mechanism (e.g., a periodic GetX worker)
  /// or simply listen via Obx.
  bool get isLocationFresh {
    if (lastKnownPosition.value == null) return false;

    // Check if the last recorded time is within the last 60 seconds
    return lastKnownPositionRead.value.isAfter(
      DateTime.now().subtract(const Duration(minutes: 1)),
    );
  }

  // Stream subscription to manage the location stream
  StreamSubscription<Position>? _geoLocationStreamSubscription;

  // --- GetX Service Lifecycle ---

  // Prompts "Are you On Inn?" when the runner sits stationary at the pack's
  // On-Inn cluster with tracking still on (docs/packtrack_auto_stop_plan.md).
  late final OnInnAutoStopMonitor _onInnAutoStop = OnInnAutoStopMonitor(this);

  // Epoch-ms of the most recent deliberate tracking start/resume — the
  // staleness guard for the remote "tracking ended" flag.
  int _lastTrackingStartMs = 0;

  /// A StorePositions response said an admin ended tracking for this run
  /// (EndEventTracking flag). Stop the loop — unless the runner deliberately
  /// (re)started tracking AFTER the flag was stamped, which means they know
  /// the run is "over" and are tracking anyway (e.g. a straggler still out on
  /// trail); their choice wins. No On-Inn is placed: the server doesn't know
  /// where the runner is in the trail, only that the run is over.
  void _onRemoteTrackingEnded(String endedAtMs) {
    if (!joinRunTracking.value && !isPaused.value) return;
    final endedMs = int.tryParse(endedAtMs) ?? 0;
    if (endedMs > 0 && endedMs < _lastTrackingStartMs) return;
    BootLogger.logBreadcrumb(
      'PackTrack: remote stop — admin ended tracking for this run',
    );
    unawaited(stopTracking());
    Get.snackbar(
      'Run ended',
      'A kennel admin marked this run as finished, so tracking has '
          'stopped. Press Start Run Tracking again if you are still out '
          'on trail.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: hc_blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 8),
    );
  }

  @override
  void onInit() {
    super.onInit();
    // Call the subscription logic on initialization
    unawaited(onInitAsync());
    _onInnAutoStop.init();

    _trackingWorker = ever<bool>(joinRunTracking, (value) async {
      if (value) {
        // Any deliberate start/resume re-stamps the session: a remote
        // "tracking ended" flag OLDER than this stamp is ignored, so a runner
        // who restarts after an admin ended the run is not immediately
        // re-stopped (see _onRemoteTrackingEnded).
        _lastTrackingStartMs = DateTime.now().millisecondsSinceEpoch;
        // Starting or resuming tracking. Only reset the session track on a
        // fresh start — resuming from pause OR seeding an existing stored track
        // (app closed mid-run) both continue the same session.
        if (!_isResumingFromPause && !_isResumingExistingTrack) {
          _sessionTrack.clear();
          filteredSessionDistanceMeters.value = 0.0;
        }
        _isResumingFromPause = false;
        _isResumingExistingTrack = false;

        final locationSettings = getLocSettings(
          _trackingDistanceFilter(),
          _trackingAccuracy(),
          true,
          false,
          androidInterval: _trackingAndroidInterval(),
        );
        await _geoLocationStreamSubscription?.cancel();
        _geoLocationStreamSubscription =
            Geolocator.getPositionStream(
              locationSettings: locationSettings,
            ).listen(
              updateDeviceLocation,
              onError: (error) {
                if (kDebugMode) debugPrint('LocationStream Error: $error');
                BootLogger.logBreadcrumb(
                  'PackTrack: location stream error while TRACKING: $error',
                );
              },
            );
        BootLogger.logBreadcrumb(
          'PackTrack: run tracking STARTED '
          '(distanceFilter=${_trackingDistanceFilter()}m, '
          'accuracy=${_trackingAccuracy()}) ${BootLogger.memInfo()}',
        );
        if (kDebugMode) debugPrint('LocationService: Started run tracking.');
      } else if (isPaused.value) {
        // Paused — keep monitoring at a finer interval so auto-resume can
        // fire when the device moves >= _autoPauseResumeDistanceMeters.
        final locationSettings = getLocSettings(
          15, // fine enough to detect 100m movement reliably
          LocationAccuracy.high,
          true,
          false,
          androidInterval: const Duration(seconds: 15),
        );
        await _geoLocationStreamSubscription?.cancel();
        _geoLocationStreamSubscription =
            Geolocator.getPositionStream(
              locationSettings: locationSettings,
            ).listen(
              updateDeviceLocation,
              onError: (error) {
                if (kDebugMode) debugPrint('LocationStream Error: $error');
                BootLogger.logBreadcrumb(
                  'PackTrack: location stream error while PAUSED: $error',
                );
              },
            );
        BootLogger.logBreadcrumb(
          'PackTrack: run tracking AUTO-PAUSED (monitoring for resume)',
        );
        if (kDebugMode) {
          debugPrint('LocationService: Auto-paused. Monitoring for resume.');
        }
      } else {
        // Fully stopped — drop back to the idle stream (or the precise
        // viewer stream if a map/compass surface is holding a boost).
        await _runBuffer?.flush();
        _lastFlushTime = DateTime.now();
        await _subscribeIdleStream();
        BootLogger.logBreadcrumb(
          'PackTrack: run tracking STOPPED (idle stream, '
          'preciseRequests=$_preciseStreamRequests)',
        );
        if (kDebugMode) debugPrint('LocationService: Stopped run tracking.');
      }
    });
  }

  Future<void> onInitAsync() async {
    // Any async initialization logic can go here
    await subscribeToGeoLocationStream();
  }

  @override
  void onClose() {
    _trackingWorker?.dispose();
    unawaited(_geoLocationStreamSubscription?.cancel());
    _runBuffer?.dispose();
    _runBuffer = null;
    super.onClose();
  }

  // --- Location Logic ---

  Future<void> subscribeToGeoLocationStream() async {
    // 1. Load in-memory cached location as fallback (or default if not yet set).
    // GPS coordinates are no longer persisted to disk — the OS provides
    // getLastKnownPosition() at cold start, making persistent storage redundant.
    final storedLat = _cachedLat ?? DEFAULT_LATITUDE;
    final storedLon = _cachedLon ?? DEFAULT_LONGITUDE;

    // 2. Update the shared DeviceInfoService immediately.
    // Guard: AppLifecycleController.onResumed() can trigger LocationService.onInit()
    // between await points in initServices(), before DeviceInfo is registered.
    if (Get.isRegistered<DeviceInfo>()) {
      deviceInfo.deviceLat = storedLat.toDouble();
      deviceInfo.deviceLon = storedLon.toDouble();
    }

    // 3. Check permissions
    final permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      final requestedPermission = await Geolocator.requestPermission();
      if ((requestedPermission == LocationPermission.denied) ||
          (requestedPermission == LocationPermission.deniedForever)) {
        if (kDebugMode) {
          debugPrint('Location permission denied by user.');
        }
        return;
      }
    }

    // 4. Start streaming location updates (equivalent to your .listen)

    var locationSettings = getLocSettings(
      250, // distanceFilter in meters
      LocationAccuracy.lowest,
      false, // allowBackgroundLocationUpdates
      true, // pauseLocationUpdatesAutomatically
    );

    _geoLocationStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          updateDeviceLocation,

          onError: (error) {
            if (kDebugMode) {
              debugPrint('LocationStream Error: $error');
            }
            // Handle specific errors like service being disabled
          },
        );

    // 5. One-time location fetch (low accuracy, non-blocking initial read)
    unawaited(
      Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.lowest,
        ),
      ).then(updateDeviceLocation).catchError((Object e) {
        if (kDebugMode) {
          debugPrint('Initial Location Fetch Error: $e');
        }
        return null;
      }),
    );
  }

  LocationSettings getLocSettings(
    int distanceFilter,
    LocationAccuracy accuracy,
    bool allowBackgroundLocationUpdates,
    bool pauseLocationUpdatesAutomatically, {
    Duration androidInterval = const Duration(minutes: 15),
  }) {
    final LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android update cadence is set explicitly per mode via the androidInterval
      // param (not derived from distance). Tracking tiers use
      // _trackingAndroidInterval() — Best 15s / Balanced 1min / Power Saver 15min;
      // the pause monitor passes 15s for responsive auto-resume; idle/stopped
      // streams use the 15-minute default to save battery.
      locationSettings = AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        intervalDuration: androidInterval,
        forceLocationManager: false,
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'Harrier Central',
          notificationText: 'Tracking run in progress',
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      locationSettings = AppleSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        activityType: ActivityType.fitness,
        allowBackgroundLocationUpdates: allowBackgroundLocationUpdates,
        pauseLocationUpdatesAutomatically: pauseLocationUpdatesAutomatically,
      );
    } else {
      locationSettings = LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      );
    }

    return locationSettings;
  }

  // ── Precision boost ───────────────────────────────────────────────────────
  // Ref-counted request from UI surfaces that need a live viewer position
  // while the user is NOT run-tracking — the PackTrack map's blue dot and the
  // lost-compass dialog. Without it those surfaces get the idle stream:
  // lowest accuracy, a fix only every 100 m.
  //
  // A surface CANNOT just open its own Geolocator stream with finer settings:
  // geolocator caches the platform position stream with the FIRST
  // subscriber's settings and silently ignores later subscribers' settings
  // (method_channel_geolocator.dart — `if (_positionStream != null) return`).
  // This service's always-on stream subscribes first, so the only way to
  // change fidelity is to reconfigure THE shared stream here.
  int _preciseStreamRequests = 0;

  /// Call when a surface needing a live position opens; pair with
  /// [releasePreciseStream] when it closes. While run tracking (or the pause
  /// monitor) is active the stream is already fine-grained, so this only
  /// re-subscribes in the idle state.
  void requestPreciseStream() {
    _preciseStreamRequests++;
    if (_preciseStreamRequests == 1 &&
        !joinRunTracking.value &&
        !isPaused.value) {
      unawaited(_subscribeIdleStream());
    }
  }

  void releasePreciseStream() {
    if (_preciseStreamRequests > 0) _preciseStreamRequests--;
    if (_preciseStreamRequests == 0 &&
        !joinRunTracking.value &&
        !isPaused.value) {
      unawaited(_subscribeIdleStream());
    }
  }

  /// (Re)subscribes the shared stream for the not-tracking state: precise
  /// viewer settings while any boost is held, low-power idle otherwise.
  Future<void> _subscribeIdleStream() async {
    final bool precise = _preciseStreamRequests > 0;
    final LocationSettings settings = precise
        ? getLocSettings(
            5,
            LocationAccuracy.best,
            false,
            false,
            androidInterval: const Duration(seconds: 15),
          )
        : getLocSettings(100, LocationAccuracy.lowest, false, true);
    await _geoLocationStreamSubscription?.cancel();
    _geoLocationStreamSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
          updateDeviceLocation,
          onError: (error) {
            if (kDebugMode) debugPrint('LocationStream Error: $error');
            BootLogger.logBreadcrumb(
              'PackTrack: location stream error while '
              '${precise ? 'PRECISE-idle' : 'STOPPED/idle'}: $error',
            );
          },
        );
  }

  // Pauses tracking: records the pause point, switches to low-power monitoring,
  // and flushes any buffered points. The session track is preserved so distance
  // continues accumulating correctly on resume.
  // isPaused must be set BEFORE joinRunTracking so the ever worker sees the
  // correct state when it fires.
  Future<void> pauseTracking() async {
    if (!joinRunTracking.value) return;
    final pos = lastKnownPosition.value;
    if (pos != null) {
      _pausePoint = latlng.LatLng(pos.latitude, pos.longitude);
    }
    isPaused.value = true;
    joinRunTracking.value =
        false; // ever worker: isPaused==true → monitoring settings
    await _runBuffer?.flush();
    _lastFlushTime = DateTime.now();
  }

  // Resumes tracking after a pause (manual or auto). Continues the same
  // session — distance and elapsed time keep accumulating without a reset.
  // _isResumingFromPause must be set BEFORE joinRunTracking so the ever
  // worker skips the session-track reset.
  void resumeTracking() {
    if (!isPaused.value) return;
    _pausePoint = null;
    _isResumingFromPause = true;
    isPaused.value = false;
    joinRunTracking.value =
        true; // ever worker: _isResumingFromPause==true → no reset
  }

  /// Seeds the in-memory session track from an already-stored track so the live
  /// distance HUD continues from where it left off instead of restarting at
  /// zero when a runner reopens the app and resumes a run.
  ///
  /// Must be called BEFORE setting [joinRunTracking] true — it sets a flag the
  /// tracking-start worker checks so the seeded points survive the fresh-start
  /// reset. Distance is recomputed with the same [TrackPointFilter] the live
  /// accumulator and the map view use, so all three agree.
  void seedSessionTrack(List<TrackPoint> existing) {
    _sessionTrack
      ..clear()
      ..addAll(existing);
    final filtered = _sessionFilter.filterAndInterpolate(_sessionTrack);
    filteredSessionDistanceMeters.value =
        TrackPointFilter.cumulativeDistanceMeters(filtered);
    _isResumingExistingTrack = true;
    // This is a stop→restart of an existing track: the first batch that
    // reaches the server carries resumed=true so it deletes any prior
    // terminator (On Inn) rows — backstop for the client-side strip, which
    // can race a still-in-flight terminator batch and miss it.
    _resumedCleanupPending = true;
  }

  /// Snapshot of the locally-recorded session track, but only when it belongs
  /// to [forEventId] — the session list survives a stop (it is only cleared on
  /// the next fresh start), so callers must say which run they are asking
  /// about or they could be handed another run's points.
  ///
  /// This is the lost-compass's offline data source: every recorded point is
  /// in here regardless of whether its upload batch has reached the server
  /// yet, so a runner with no signal at all can still be pointed back along
  /// their own track.
  List<TrackPoint> sessionTrackFor(String forEventId) {
    final ownEventId = eventId;
    if (ownEventId == null ||
        normalizeUuid(ownEventId) != normalizeUuid(forEventId)) {
      return const <TrackPoint>[];
    }
    return List<TrackPoint>.of(_sessionTrack);
  }

  // Fully ends the session regardless of current state (tracking or paused).
  Future<void> stopTracking() async {
    _pausePoint = null;
    _isResumingFromPause = false;
    final wasPaused = isPaused.value;
    if (wasPaused) isPaused.value = false;
    if (joinRunTracking.value) {
      joinRunTracking.value = false; // ever worker handles flush + idle stream
    } else if (wasPaused) {
      // Was paused: joinRunTracking is already false so the ever worker won't
      // fire — manually restore the idle (or boosted) stream settings.
      await _subscribeIdleStream();
    }
  }

  Future<void> markPoint(HashRunPointTypes pointType, {String? label}) async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    );
    await updateDeviceLocation(
      position,
      forceFlush: true,
      pointType: pointType,
      label: label,
    );
  }

  /// Two-phase slot mark, phase 1 — CAPTURE. Fixes the position and timestamp
  /// at the moment of the tap, but records nothing. The caller holds the
  /// returned [PendingSlotMark] while the confirmation card is up: dismissal
  /// commits it via [commitSlotMark]; Undo simply drops it (nothing was ever
  /// queued or uploaded, so there is nothing to delete).
  Future<PendingSlotMark> captureSlotMark(TrailSlot slot, {String? label}) async {
    final tsMs = DateTime.now().millisecondsSinceEpoch;
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    );
    return PendingSlotMark(
      position: position,
      tsMs: tsMs,
      // Self-describing track type: GLY::<id> / TXT::<text> [::L=label] [::A=action].
      rawType: slot.trackType(label: label),
    );
  }

  /// Two-phase slot mark, phase 2 — COMMIT. Queues the captured mark on the
  /// track buffer (stamped with its capture-time timestamp, not now) and
  /// force-flushes. Returns the recorded timestamp, or null if nothing was
  /// recorded (paused, buffer resetting).
  Future<int?> commitSlotMark(PendingSlotMark mark) {
    return updateDeviceLocation(
      mark.position,
      forceFlush: true,
      rawType: mark.rawType,
      atTsMs: mark.tsMs,
    );
  }

  /// Emits a trail-type declaration point (`TRL::<value>`) at the current
  /// position, tagging the runner's track with the lane they're running.
  /// One-shot and force-flushed. Like other typed marks it is never drawn or
  /// counted toward distance — it's metadata the map reads to label/filter the
  /// track. No-ops if tracking isn't active (the point would have nowhere to go).
  Future<void> declareTrailType(int trailValue) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      await updateDeviceLocation(
        position,
        forceFlush: true,
        rawType: 'TRL::$trailValue',
      );
    } catch (e) {
      // Non-fatal: a missed declaration just means the track falls back to
      // Normal on read. Never let a fire-and-forget call crash the caller.
      if (kDebugMode) debugPrint('declareTrailType failed: $e');
    }
  }

  /// Places a single track point with an explicit [timestampMs] — used for
  /// photos taken before or after the run where [DateTime.now()] would put
  /// the marker in the wrong place on the timeline.
  ///
  /// The GPS position is the real current position (where the photo was taken).
  /// If tracking is active the existing buffer is used; otherwise a one-shot
  /// flush is made directly to StorePositions.
  /// Stores a typed mark at [timestampMs] for the given event/user.
  ///
  /// Set [immediate] for marks that must reach the server now rather than ride
  /// the next batch (distress marks). That path sends a one-point batch out of
  /// band, so it never queues behind the shared buffer's in-flight upload —
  /// which on a bad link can block for over a minute. If the out-of-band send
  /// fails after its retries, the point is handed to the live buffer so the
  /// ordinary flush cycle keeps trying rather than dropping it.
  ///
  /// Returns true when the point is confirmed stored (always true on the
  /// non-[immediate] path, which only guarantees it was queued).
  Future<bool> markPointAt({
    required HashRunPointTypes pointType,
    required int timestampMs,
    required String overrideEventId,
    required String overrideUserId,
    String? label,
    bool immediate = false,
    // Explicit position for marks that belong somewhere other than where the
    // device is standing — e.g. importing a photo taken earlier in the run,
    // whose marker must land where the PHOTO was taken, not at the sofa the
    // user is importing it from. Both must be supplied to take effect.
    double? atLat,
    double? atLng,
  }) async {
    final Position position;
    if (atLat != null && atLng != null) {
      position = Position(
        latitude: atLat,
        longitude: atLng,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    } else {
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
          ),
        );
      } catch (e) {
        // No fix available (services off, permission revoked, hardware timeout).
        // Never let this throw out of an unawaited call.
        if (kDebugMode) {
          debugPrint('LocationService: markPointAt got no GPS fix: $e');
        }
        return false;
      }
    }

    String? pointStr = pointType.key;
    if (label != null) pointStr += '::$label';

    final point = UserEventLocation(
      ts: pad19(timestampMs),
      lat: double.parse(position.latitude.toStringAsFixed(5)),
      lng: double.parse(position.longitude.toStringAsFixed(5)),
      acc: double.parse(position.accuracy.toStringAsFixed(2)),
      alt: double.parse(position.altitude.toStringAsFixed(2)),
      type: pointStr,
    );
    // Live echo + session stats: photo (PHO) and distress marks placed via
    // this path must reach the same listeners as ordinary slot marks.
    _notifyTypedPointListeners(point, timestampMs, overrideEventId);

    if (immediate) {
      final buf = RunPointBuffer(
        apiUrl: STORE_POSITIONS_URL,
        eventId: overrideEventId,
        userId: overrideUserId,
      );
      bool ok = false;
      try {
        ok = await buf.sendNow(<UserEventLocation>[point]);
      } finally {
        buf.dispose();
      }
      // Last resort: let the live track's own flush cycle keep retrying.
      if (!ok && _runBuffer != null) _runBuffer!.enqueue(point);
      return ok;
    }

    if (_runBuffer != null) {
      _runBuffer!.enqueue(point);
      await _runBuffer!.flush();
    } else {
      final buf = RunPointBuffer(
        apiUrl: STORE_POSITIONS_URL,
        eventId: overrideEventId,
        userId: overrideUserId,
      );
      buf.enqueue(point);
      await buf.flush();
      buf.dispose();
    }
    return true;
  }

  /// Stores an admin time-boundary marker (AST = Official Start, AEN = Official
  /// End) at [timestampMs] for the given event/user. Unlike [markPointAt] this
  /// does NOT read GPS: a boundary marker's position is irrelevant — only its
  /// timestamp matters — so an admin can set it during replay, away from the
  /// run. All clients and GetPositions treat data before AST / after AEN as
  /// out-of-bounds. Reversible: move = drop a newer marker (newest wins);
  /// clear = delete it via DeletePositions.
  Future<void> markBoundaryAt({
    required HashRunPointTypes boundaryType,
    required int timestampMs,
    required String overrideEventId,
    required String overrideUserId,
    double lat = 0.0,
    double lng = 0.0,
  }) async {
    assert(
      boundaryType == HashRunPointTypes.adminStart ||
          boundaryType == HashRunPointTypes.adminEnd,
      'markBoundaryAt is only for AST/AEN boundary markers',
    );
    final point = UserEventLocation(
      ts: pad19(timestampMs),
      lat: double.parse(lat.toStringAsFixed(5)),
      lng: double.parse(lng.toStringAsFixed(5)),
      acc: 0.0,
      alt: 0.0,
      type: boundaryType.key,
    );
    // Always a one-shot buffer (never the live tracking buffer) so it works
    // whether or not this device is currently tracking the run.
    final buf = RunPointBuffer(
      apiUrl: STORE_POSITIONS_URL,
      eventId: overrideEventId,
      userId: overrideUserId,
    );
    buf.enqueue(point);
    await buf.flush();
    buf.dispose();
  }

  // Private method to handle location updates from the stream/one-time fetch.
  // Returns the epoch-ms timestamp of the point it recorded to the tracking
  // buffer (the undo handle for marks), or null when nothing was recorded.
  /// Live-echo listeners keyed by owner (a map controller registers itself
  /// on open, removes itself on close). Fired the moment a typed mark is
  /// queued for upload so an open map draws it immediately instead of
  /// waiting for the next server poll.
  final Map<Object, void Function(String eventId, TrackPoint point)>
      typedPointListeners = {};

  void _notifyTypedPointListeners(UserEventLocation p, int tsMs, String? evId) {
    if (typedPointListeners.isEmpty) return;
    if (evId == null) return;
    final tp = TrackPoint(
      lat: p.lat,
      lng: p.lng,
      acc: p.acc,
      alt: p.alt,
      timestampMs: tsMs,
      type: p.type,
    );
    for (final listener in List.of(typedPointListeners.values)) {
      try {
        listener(evId, tp);
      } catch (e) {
        BootLogger.logError('[LocationService] typed-point listener', e, null);
      }
    }
  }

  Future<int?> updateDeviceLocation(
    Position position, {
    bool forceFlush = false,
    HashRunPointTypes? pointType,
    String? rawType,
    String? label,
    int? atTsMs,
  }) async {
    int? recordedTsMs;
    final lat = position.latitude.toDouble();
    final lon = position.longitude.toDouble();
    final accuracy = position.accuracy.toDouble();
    final altitude = position.altitude.toDouble();

    // 1. Update the reactive variable within this service
    lastKnownPosition.value = position;
    lastKnownPositionRead.value = DateTime.now();

    // 2. Cache the coordinates in memory (not persisted to disk).
    // The OS provides getLastKnownPosition() at cold start, so writing
    // GPS coordinates to plain unencrypted GetStorage is unnecessary.
    _cachedLat = lat;
    _cachedLon = lon;
    // Persist the fix time at most ~once a minute (see _lastLocationPrefTime),
    // instead of a disk write on every position event.
    final nowPref = DateTime.now();
    if (_lastLocationPrefTime == null ||
        nowPref.difference(_lastLocationPrefTime!).inSeconds >= 60) {
      _lastLocationPrefTime = nowPref;
      await setDatePref(DatePrefsEnum.lastLocationUpdate, nowPref);
    }

    // 3. Update the shared state in DeviceInfoService — but only if it's
    // registered. A background location callback can fire after the app was
    // suspended, when DeviceInfo has been torn down and not yet re-registered;
    // the unguarded `deviceInfo` getter would throw on every such callback (a
    // 340+×-per-user error storm in the harvest). Skip the cache write instead —
    // the GPS point is still buffered/uploaded below.
    final di = deviceInfoOrNull;
    if (di != null) {
      di.deviceLat = lat;
      di.deviceLon = lon;
      di.deviceAccuracy = accuracy;
      di.deviceAltitude = altitude;
    }

    // Auto-resume: if paused and device has moved far enough, resume tracking.
    // Falls through to the joinRunTracking block below so the resuming position
    // is recorded as the first point of the resumed segment.
    if (isPaused.value) {
      final pausePt = _pausePoint;
      if (pausePt != null) {
        final distMeters = const latlng.Distance()(
          pausePt,
          latlng.LatLng(lat, lon),
        );
        if (distMeters >= _autoPauseResumeDistanceMeters) {
          resumeTracking();
        }
      }
      if (isPaused.value) return null; // still paused — don't record
    }

    if (joinRunTracking.value) {
      // Throttled memory heartbeat (~every 60s while tracking) so the harvest
      // shows the app's RSS trend across a run — a steady climb toward the
      // device limit is the signature of an out-of-memory (jetsam) kill.
      final nowMem = DateTime.now();
      if (_lastMemLogTime == null ||
          nowMem.difference(_lastMemLogTime!).inSeconds >= 60) {
        _lastMemLogTime = nowMem;
        BootLogger.logBreadcrumb(
          'PackTrack: tracking heartbeat ${BootLogger.memInfo()}',
        );
      }

      if ((_runBuffer != null) && (_runBuffer!.eventId != eventId)) {
        // Reset buffer if eventId/userId changed
        await _runBuffer?.flush();
        _runBuffer?.dispose();

        if (kDebugMode) {
          debugPrint('LocationService: Flushed old run buffer.');
        }
        _runBuffer = null;
        // wait for next location update to re-initialize
        return null;
      }

      _runBuffer ??= RunPointBuffer(
        apiUrl: STORE_POSITIONS_URL,
        eventId: eventId!,
        userId: userId!,
        onRemoteTrackingEnded: _onRemoteTrackingEnded,
      );
      // Hand a pending resume-cleanup to the live buffer (it may be a
      // fresh instance or the pre-stop one — either carries the flag).
      if (_resumedCleanupPending) {
        _runBuffer!.markResumed();
        _resumedCleanupPending = false;
      }

      String? pointStr;

      if (rawType != null) {
        // Already a fully-formed type string (e.g. 'TRL::3') — used verbatim.
        pointStr = rawType;
      } else if (pointType != null) {
        pointStr = pointType.key;
        if (label != null) {
          pointStr += '::$label';
        }
      }

      if (pointStr != null) {
        if (kDebugMode) {
          debugPrint(pointStr);
        }
      }

      // A deferred-commit mark carries its capture-time timestamp so it lands
      // on the timeline at the moment of the tap, not the card's dismissal.
      final tsMs = atTsMs ?? DateTime.now().millisecondsSinceEpoch;
      final point = UserEventLocation(
        ts: pad19(tsMs),
        lat: double.parse(lat.toStringAsFixed(5)),
        lng: double.parse(lon.toStringAsFixed(5)),
        acc: double.parse(accuracy.toStringAsFixed(2)),
        alt: double.parse(altitude.toStringAsFixed(2)),
        type: pointStr,
      );
      _runBuffer?.enqueue(point);
      recordedTsMs = tsMs;
      locationUpdateCount.value++;
      if (pointStr != null) _notifyTypedPointListeners(point, tsMs, eventId);

      // Append to the local session track and recompute filtered distance.
      // Uses the same TrackPointFilter as the map view so both displays agree.
      _sessionTrack.add(
        TrackPoint(
          lat: double.parse(lat.toStringAsFixed(5)),
          lng: double.parse(lon.toStringAsFixed(5)),
          acc: double.parse(accuracy.toStringAsFixed(2)),
          alt: double.parse(altitude.toStringAsFixed(2)),
          timestampMs: tsMs,
        ),
      );
      // Recompute the filtered distance at most ~every 10s (or on a forced flush
      // — mark/stop), not on every point, to avoid an O(n²) refilter over the run.
      final nowDist = DateTime.now();
      if (forceFlush ||
          _lastSessionDistanceTime == null ||
          nowDist.difference(_lastSessionDistanceTime!).inSeconds >= 10) {
        _lastSessionDistanceTime = nowDist;
        final filtered = _sessionFilter.filterAndInterpolate(_sessionTrack);
        filteredSessionDistanceMeters.value =
            TrackPointFilter.cumulativeDistanceMeters(filtered);
      }
    }

    if (kDebugMode) {
      debugPrint('LocationService: Updated to Lat: $lat, Lon: $lon');
    }

    if ((forceFlush) ||
        (_lastFlushTime.isBefore(
          DateTime.now().subtract(const Duration(minutes: 1)),
        ))) {
      await _runBuffer?.flush();
      _lastFlushTime = DateTime.now();
    }

    return recordedTsMs;
  }
}
