import 'package:harrier_central/imports.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class LatLon {
  num latitude;
  num longitude;
}

class Utilities {
  static const int qrScanTypeFlag_user = 0x00000001;
  static const int qrScanTypeFlag_userSecretCode = 0x00000002;
  static const int qrScanTypeFlag_runStart = 0x00000004;
  static const int qrScanTypeFlag_runEnd = 0x00000008;
  static const int qrScanTypeFlag_kennelRunStart = 0x00000010;
  static const int qrScanTypeFlag_kennelRunEnd = 0x00000020;
  static const int qrScanTypeFlag_resetCode = 0x00000040;

  static int logCounter = 0;

  static Map<String, String> validateScan(String scanText, int allowedScanTypes) {
    Map<String, String> result;

    final int colonOffset = scanText.indexOf(':');
    if (colonOffset != 3) {
      result = <String, String>{'validScan': false.toString(), 'prefix': '', 'content': ''};
    } else {
      final String prefix = scanText.substring(0, colonOffset + 1);
      final String content = scanText.substring(4);

      int scanType = 0;
      bool validHcQr = true;

      switch (prefix.toUpperCase()) {
        case QR_PREFIX_USER_CODE:
          scanType = qrScanTypeFlag_user;
          break;
        case QR_PREFIX_USER_SECRET_CODE:
          scanType = qrScanTypeFlag_userSecretCode;
          break;
        case QR_PREFIX_USER_RESET_CODE:
          scanType = qrScanTypeFlag_resetCode;
          break;
        case QR_PREFIX_SPECIFIC_RUN_START:
          scanType = qrScanTypeFlag_runStart;
          break;
        case QR_PREFIX_SPECIFIC_RUN_END:
          scanType = qrScanTypeFlag_runEnd;
          break;
        case QR_PREFIX_KENNEL_GENERIC_RUN_START:
          scanType = qrScanTypeFlag_kennelRunStart;
          break;
        case QR_PREFIX_KENNEL_GENERIC_RUN_END:
          scanType = qrScanTypeFlag_kennelRunEnd;
          break;
        default:
          validHcQr = false;
          break;
      }

      final bool scanAllowed = (scanType & allowedScanTypes) != 0;

      result = <String, String>{'validScan': scanAllowed.toString(), 'prefix': prefix, 'content': content, 'validHcQr': validHcQr.toString()};
    }

    return result;
  }

  static Future<void> subscribeToGeoLocationStream() async {
    G0<DeviceInfo>().deviceLat = DEFAULT_LATITUDE;
    G0<DeviceInfo>().deviceLon = DEFAULT_LONGITUDE;

    final Geolocator geolocator = Geolocator();

    IveCoreUtilities.logTiming('Geostatus query start', G0<AppModel>().appStartTime);
    final GeolocationStatus status = await Geolocator().checkGeolocationPermissionStatus(locationPermission: GeolocationPermission.location);

    IveCoreUtilities.logTiming('Geolocation query start', G0<AppModel>().appStartTime);
    if (status == GeolocationStatus.granted) {
      const LocationOptions locationOptions = LocationOptions(accuracy: BASE_APP_LOCATION_ACCURACY, distanceFilter: 50);
      G0<AppModel>().geoLocationStream = geolocator.getPositionStream(locationOptions).listen((Position position) {
        if (position != null) {
          G0<DeviceInfo>().deviceLat = position.latitude;
          G0<DeviceInfo>().deviceLon = position.longitude;
        }
        print('>>>>>>>>>>> geoloc stream update' + (position == null ? 'Unknown' : position.latitude.toString() + ', ' + position.longitude.toString()));
      });

      // start with the lowest possible accuracy to ensure that the
      // app boots up quickly. As soon as the geoLocationStream resolves an accurate
      // location, it will correct the lat/long to be more accurate.
      final Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.lowest);
      G0<DeviceInfo>().deviceLat = position.latitude;
      G0<DeviceInfo>().deviceLon = position.longitude;
      print('>>>>>>>>>>> geoloc one-time update' + (position == null ? 'Unknown' : position.latitude.toString() + ', ' + position.longitude.toString()));
    }
  }

  static String getDistance(num meters, BuildContext context, {bool isMetric = true}) {
    if (!G0<AppModel>().hasLocationPermissions) {
      return '';
    }

    String result = '';

    if (isMetric) {
      if (meters < 1000) {
        result = '${NumberFormat('####').format(meters)} meters';
      } else if (meters < 10000) {
        result = '${NumberFormat('#####.0').format(meters / 1000.0)} km';
      } else {
        result = '${NumberFormat('#####').format(meters / 1000.0)} km';
      }
    } else {
      final num miles = meters * METERS_TO_MILES;

      if (miles < 3) {
        result = '${NumberFormat('#####.00').format(miles)} miles';
      } else if (miles < 10) {
        result = '${NumberFormat('#####.0').format(miles)} miles';
      } else {
        result = '${NumberFormat('#####').format(miles)} miles';
      }
    }

    return result;
  }
}
