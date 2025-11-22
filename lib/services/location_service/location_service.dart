import 'package:geolocator/geolocator.dart';
import 'run_point_buffer.dart';
import 'package:harrier_central/imports.dart'; // Assume this is imported in your main project

// Constants (replace with your actual constants)
// ignore: constant_identifier_names
//const LocationAccuracy BASE_APP_LOCATION_ACCURACY = LocationAccuracy.best;

String pad19(int epochMs) => epochMs.toString().padLeft(19, '0');

class LocationService extends GetxService {
  // Rx variable to hold the latest position, making it reactive
  final Rx<Position?> lastKnownPosition = Rx<Position?>(null);
  final Rx<DateTime> lastKnownPositionRead = Rx<DateTime>(DateTime(2000));

  final RxBool joinRunTracking = false.obs;
  String? eventId;
  String? userId;

  RunPointBuffer? _runBuffer;
  DateTime _lastFlushTime = DateTime.now();

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
    subscribeToGeoLocationStream();
  }

  @override
  void onClose() {
    // Cancel the stream subscription when the service is closed
    _geoLocationStreamSubscription?.cancel();
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

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      // 4. Start streaming location updates (equivalent to your .listen)
      final LocationSettings locationSettings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
          intervalDuration: Duration(seconds: 15),
          forceLocationManager: false,
          foregroundNotificationConfig: ForegroundNotificationConfig(
            notificationTitle: 'Harrier Central',
            notificationText: 'Tracking run in progress',
            enableWakeLock: true,
          ),
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
          activityType: ActivityType.fitness,
          allowBackgroundLocationUpdates: true,
          pauseLocationUpdatesAutomatically: false,
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: BASE_APP_LOCATION_ACCURACY,
          distanceFilter: 15,
        );
      }

      _geoLocationStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            _updateDeviceLocation,

            onError: (error) {
              print('LocationStream Error: $error');
              // Handle specific errors like service being disabled
            },
          );

      // 5. One-time location fetch (low accuracy, non-blocking initial read)
      Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.lowest,
        ),
      ).then(_updateDeviceLocation).catchError((e) {
        print('Initial Location Fetch Error: $e');
      });
    } else {
      print('Location permission not granted: $permission');
      // Optionally request permission here or notify user
    }
  }

  // Private method to handle location updates from the stream/one-time fetch
  void _updateDeviceLocation(Position position) {
    final lat = position.latitude.toDouble();
    final lon = position.longitude.toDouble();
    final accuracy = position.accuracy.toDouble();
    final altitude = position.altitude.toDouble();

    // 1. Update the reactive variable within this service
    lastKnownPosition.value = position;
    lastKnownPositionRead.value = DateTime.now();

    // 2. Update the persistent storage
    setNumPref(NumPrefsEnum.currentDeviceLat, lat);
    setNumPref(NumPrefsEnum.currentDeviceLon, lon);
    setNumPref(NumPrefsEnum.currentDeviceAltitude, altitude);
    setDatePref(DatePrefsEnum.lastLocationUpdate, DateTime.now());

    // 3. Update the shared state in DeviceInfoService
    deviceInfo.deviceLat = lat;
    deviceInfo.deviceLon = lon;
    deviceInfo.deviceAccuracy = accuracy;
    deviceInfo.deviceAltitude = altitude;

    if (joinRunTracking.value) {
      if ((_runBuffer != null) && (_runBuffer!.eventId != eventId)) {
        // Reset buffer if eventId/userId changed
        _runBuffer?.flush().then((_) {
          print('LocationService: Flushed old run buffer.');
          _runBuffer = null;
          // wait for next location update to re-initialize
          return;
        });
      }

      _runBuffer ??= RunPointBuffer(
        apiUrl: STORE_POSITIONS_URL,
        eventId: eventId!,
        userId: userId!,
      );

      final tsMs = DateTime.now().millisecondsSinceEpoch;
      final point = UserEventLocation(
        ts: pad19(tsMs),
        lat: lat,
        lng: lon,
        acc: accuracy,
        alt: altitude,
      );
      _runBuffer?.enqueue(point);
    }

    print('LocationService: Updated to Lat: $lat, Lon: $lon');

    if (_lastFlushTime.isBefore(
      DateTime.now().subtract(const Duration(minutes: 1)),
    )) {
      _runBuffer?.flush();
      _lastFlushTime = DateTime.now();
      print('LocationService: Flushed run buffer.');
    }

    return;
  }
}
