// ignore_for_file: constant_identifier_names

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'run_point_buffer.dart';
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/util/track_point_filter.dart';

// Constants (replace with your actual constants)

String pad19(int epochMs) => epochMs.toString().padLeft(19, '0');

const int DISTANCE_BETWEEN_APP_WAKEUPS = 5; // distanceFilter in meters
const LocationAccuracy LOCATION_ACCURACY = LocationAccuracy.bestForNavigation;

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
  Worker? _trackingWorker;

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

  @override
  void onInit() {
    super.onInit();
    // Call the subscription logic on initialization
    unawaited(onInitAsync());

    _trackingWorker = ever<bool>(joinRunTracking, (value) async {
      if (value) {
        // Starting or resuming tracking. Only reset the session track on a
        // fresh start — resuming from pause continues the same session.
        if (!_isResumingFromPause) {
          _sessionTrack.clear();
          filteredSessionDistanceMeters.value = 0.0;
        }
        _isResumingFromPause = false;

        final locationSettings = getLocSettings(
          DISTANCE_BETWEEN_APP_WAKEUPS,
          LOCATION_ACCURACY,
          true,
          false,
        );
        await _geoLocationStreamSubscription?.cancel();
        _geoLocationStreamSubscription = Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen(
          updateDeviceLocation,
          onError: (error) {
            if (kDebugMode) debugPrint('LocationStream Error: $error');
          },
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
        );
        await _geoLocationStreamSubscription?.cancel();
        _geoLocationStreamSubscription = Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen(
          updateDeviceLocation,
          onError: (error) {
            if (kDebugMode) debugPrint('LocationStream Error: $error');
          },
        );
        if (kDebugMode) debugPrint('LocationService: Auto-paused. Monitoring for resume.');

      } else {
        // Fully stopped — drop back to low-power idle stream.
        final locationSettings = getLocSettings(
          100,
          LocationAccuracy.lowest,
          false,
          true,
        );
        await _geoLocationStreamSubscription?.cancel();
        await _runBuffer?.flush();
        _lastFlushTime = DateTime.now();
        _geoLocationStreamSubscription = Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen(
          updateDeviceLocation,
          onError: (error) {
            if (kDebugMode) debugPrint('LocationStream Error: $error');
          },
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
    // 1. Load saved location as fallback
    final storedLat =
        getNumPref(NumPrefsEnum.currentDeviceLat) ?? DEFAULT_LATITUDE;
    final storedLon =
        getNumPref(NumPrefsEnum.currentDeviceLon) ?? DEFAULT_LONGITUDE;

    // 2. Update the shared DeviceInfoService immediately
    deviceInfo.deviceLat = storedLat.toDouble();
    deviceInfo.deviceLon = storedLon.toDouble();

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
      ).then(updateDeviceLocation).catchError((e) {
        if (kDebugMode) {
          debugPrint('Initial Location Fetch Error: $e');
        }
      }),
    );
  }

  LocationSettings getLocSettings(
    int distanceFilter,
    LocationAccuracy accuracy,
    bool allowBackgroundLocationUpdates,
    bool pauseLocationUpdatesAutomatically,
  ) {
    final LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        intervalDuration: Duration(minutes: 15),
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
    joinRunTracking.value = false; // ever worker: isPaused==true → monitoring settings
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
    joinRunTracking.value = true; // ever worker: _isResumingFromPause==true → no reset
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
      // fire — manually restore idle stream settings.
      final settings = getLocSettings(100, LocationAccuracy.lowest, false, true);
      await _geoLocationStreamSubscription?.cancel();
      _geoLocationStreamSubscription = Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
        updateDeviceLocation,
        onError: (error) {
          if (kDebugMode) debugPrint('LocationStream Error: $error');
        },
      );
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

  // Private method to handle location updates from the stream/one-time fetch
  Future<void> updateDeviceLocation(
    Position position, {
    bool forceFlush = false,
    HashRunPointTypes? pointType,
    String? label,
  }) async {
    final lat = position.latitude.toDouble();
    final lon = position.longitude.toDouble();
    final accuracy = position.accuracy.toDouble();
    final altitude = position.altitude.toDouble();

    // 1. Update the reactive variable within this service
    lastKnownPosition.value = position;
    lastKnownPositionRead.value = DateTime.now();

    // 2. Update the persistent storage
    await setNumPref(NumPrefsEnum.currentDeviceLat, lat);
    await setNumPref(NumPrefsEnum.currentDeviceLon, lon);
    await setNumPref(NumPrefsEnum.currentDeviceAltitude, altitude);
    await setDatePref(DatePrefsEnum.lastLocationUpdate, DateTime.now());

    // 3. Update the shared state in DeviceInfoService
    deviceInfo.deviceLat = lat;
    deviceInfo.deviceLon = lon;
    deviceInfo.deviceAccuracy = accuracy;
    deviceInfo.deviceAltitude = altitude;

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
      if (isPaused.value) return; // still paused — don't record
    }

    if (joinRunTracking.value) {
      if ((_runBuffer != null) && (_runBuffer!.eventId != eventId)) {
        // Reset buffer if eventId/userId changed
        await _runBuffer?.flush();
        _runBuffer?.dispose();

        if (kDebugMode) {
          debugPrint('LocationService: Flushed old run buffer.');
        }
        _runBuffer = null;
        // wait for next location update to re-initialize
        return;
      }

      _runBuffer ??= RunPointBuffer(
        apiUrl: STORE_POSITIONS_URL,
        eventId: eventId!,
        userId: userId!,
      );

      String? pointStr;

      if (pointType != null) {
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

      final tsMs = DateTime.now().millisecondsSinceEpoch;
      final point = UserEventLocation(
        ts: pad19(tsMs),
        lat: double.parse(lat.toStringAsFixed(5)),
        lng: double.parse(lon.toStringAsFixed(5)),
        acc: double.parse(accuracy.toStringAsFixed(2)),
        alt: double.parse(altitude.toStringAsFixed(2)),
        type: pointStr,
      );
      _runBuffer?.enqueue(point);
      locationUpdateCount.value++;

      // Append to the local session track and recompute filtered distance.
      // Uses the same TrackPointFilter as the map view so both displays agree.
      _sessionTrack.add(TrackPoint(
        lat: double.parse(lat.toStringAsFixed(5)),
        lng: double.parse(lon.toStringAsFixed(5)),
        acc: double.parse(accuracy.toStringAsFixed(2)),
        alt: double.parse(altitude.toStringAsFixed(2)),
        timestampMs: tsMs,
      ));
      final filtered = _sessionFilter.filterAndInterpolate(_sessionTrack);
      filteredSessionDistanceMeters.value =
          TrackPointFilter.cumulativeDistanceMeters(filtered);
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

    return;
  }
}
