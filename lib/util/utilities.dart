// @dart=2.11
import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class LatLon {
  num latitude;
  num longitude;
}

class Utilities {
  // this is an unused variable to suppress a LINT warning
  int suppressWarning = 0;

  static const int qrScanTypeFlag_user = 0x00000001;
  static const int qrScanTypeFlag_userSecretCode = 0x00000002;
  static const int qrScanTypeFlag_runStart = 0x00000004;
  static const int qrScanTypeFlag_runEnd = 0x00000008;
  static const int qrScanTypeFlag_kennelRunStart = 0x00000010;
  static const int qrScanTypeFlag_kennelRunEnd = 0x00000020;
  static const int qrScanTypeFlag_resetCode = 0x00000040;
  static const int qrScanTypeFlag_authenticateWebPortal = 0x00000080;
  static const int qrScanTypeFlag_runStartV2 = 0x00000100;
  static const int qrScanTypeFlag_runEndV2 = 0x00000200;

  static int logCounter = 0;

  static Map<String, String> validateScan(String scanText, int allowedScanTypes) {
    Map<String, String> result;

    if (scanText.contains(BASE_HCWEB_MOBILE_URL)) {
      scanText = scanText.replaceAll(BASE_HCWEB_MOBILE_URL, '');
    }

    if (scanText.contains(BASE_HASHRUNS_DOT_ORG_URL)) {
      scanText = scanText.replaceAll(BASE_HASHRUNS_DOT_ORG_URL, '');
    }

    String prefix = '';
    String content = '';

    // this first option is for HC QR codes that are not URLs
    if (scanText.indexOf(':') == 3) {
      prefix = scanText.substring(0, 4).toUpperCase();
      content = scanText.substring(4);
    } else if (scanText.startsWith(QR_PREFIX_HASHRUNS_DOT_ORG_RUN_START)) {
      // these conditions cover HC QR codes that are also URLs
      prefix = QR_PREFIX_HASHRUNS_DOT_ORG_RUN_START;
      content = scanText.replaceAll(QR_PREFIX_HASHRUNS_DOT_ORG_RUN_START, '');
    } else if (scanText.startsWith(QR_PREFIX_HASHRUNS_DOT_ORG_RUN_END)) {
      prefix = QR_PREFIX_HASHRUNS_DOT_ORG_RUN_END;
      content = scanText.replaceAll(QR_PREFIX_HASHRUNS_DOT_ORG_RUN_END, '');
    }

    if (prefix.isEmpty) {
      result = <String, String>{'validScan': false.toString(), 'prefix': '', 'content': ''};
    } else {
      int scanType = 0;
      bool validHcQr = true;

      switch (prefix) {
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
        case QR_PREFIX_HASHRUNS_DOT_ORG_RUN_START:
          scanType = qrScanTypeFlag_runStartV2;
          break;
        case QR_PREFIX_SPECIFIC_RUN_END:
          scanType = qrScanTypeFlag_runEnd;
          break;
        case QR_PREFIX_HASHRUNS_DOT_ORG_RUN_END:
          scanType = qrScanTypeFlag_runEndV2;
          break;
        case QR_PREFIX_KENNEL_GENERIC_RUN_START:
          scanType = qrScanTypeFlag_kennelRunStart;
          break;
        case QR_PREFIX_KENNEL_GENERIC_RUN_END:
          scanType = qrScanTypeFlag_kennelRunEnd;
          break;
        case QR_PREFIX_AUTHENTICATE_WEB_PORTAL_LOGIN:
          scanType = qrScanTypeFlag_authenticateWebPortal;
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

  static Future<bool> promptForHare(BuildContext context, String hareList) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Will you Hare this run?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Please confirm that you are signing up to hare this run' + ((hareList == null) ? '.' : ' with ' + hareList)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No Thanks!'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Yes, I\'ll Hare!'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  static bool isOpeeOrTuna() {
    bool isOpeeOrTuna = false;

    final String currentUserId = getStringPref(StringPrefsEnum.userId) ?? '<no user id>';

    if ((currentUserId == '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC') || (currentUserId == 'D0B7EF01-C6E3-4723-9D2F-2AE864A59F1A')) {
      isOpeeOrTuna = true;
    }

    return isOpeeOrTuna;
  }

  static Future<void> subscribeToGeoLocationStream() async {
    G0<DeviceInfo>().deviceLat = getNumPref(NumPrefsEnum.currentDeviceLat) ?? DEFAULT_LATITUDE;
    G0<DeviceInfo>().deviceLon = getNumPref(NumPrefsEnum.currentDeviceLon) ?? DEFAULT_LONGITUDE;

    IveCoreUtilities.logTiming('Geostatus query start', G0<AppModel>().appStartTime);
    final LocationPermission permission = await Geolocator.checkPermission();

    IveCoreUtilities.logTiming('Geolocation query start', G0<AppModel>().appStartTime);
    if ((permission == LocationPermission.always) || (permission == LocationPermission.whileInUse)) {
      G0<AppModel>().geoLocationStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: BASE_APP_LOCATION_ACCURACY, distanceFilter: 50),
      ).listen((Position position) {
        if (position != null) {
          G0<DeviceInfo>().deviceLat = position.latitude + 0.0;
          G0<DeviceInfo>().deviceLon = position.longitude + 0.0;
          setNumPref(NumPrefsEnum.currentDeviceLat, position.latitude + 0.0);
          setNumPref(NumPrefsEnum.currentDeviceLon, position.longitude + 0.0);
          setDatePref(DatePrefsEnum.lastLocationUpdate, DateTime.now());
        }
        //print('>>>>>>>>>>> geoloc stream update' + (position == null ? 'Unknown' : position.latitude.toString() + ', ' + position.longitude.toString()));
      });

      // don't wait for the position to resolve to return from
      // this function because we want the app to start quickly.

      // ignore: unawaited_futures
      Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.lowest).then((Position position) {
        G0<DeviceInfo>().deviceLat = position.latitude;
        G0<DeviceInfo>().deviceLon = position.longitude;
        setNumPref(NumPrefsEnum.currentDeviceLat, position.latitude + 0.0);
        setNumPref(NumPrefsEnum.currentDeviceLon, position.longitude + 0.0);
        setDatePref(DatePrefsEnum.lastLocationUpdate, DateTime.now());

        //print('>>>>>>>>>>> geoloc one-time update' + (position == null ? 'Unknown' : position.latitude.toString() + ', ' + position.longitude.toString()));
      });
    }
  }

  static String validateEmail(String value) {
    if ((value != null) && (value.isNotEmpty)) {
      const Pattern pattern = r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?";
      final RegExp regex = RegExp(pattern, caseSensitive: false);
      if (!regex.hasMatch(value)) {
        return 'Please enter a valid email';
      } else {
        return null;
      }
    }
    return 'Please enter an email address';
  }

  static String getEventScopeText(int eventGeographicScope) {
    String s = 'Special event';

    switch (eventGeographicScope) {
      case 0:
        s = 'Not specified';
        break;
      case 1:
        s = 'Normal run';
        break;
      case 2:
        s = 'Special local event';
        break;
      case 3:
        s = 'Special regional / state event';
        break;
      case 4:
        s = 'Nash Hash / national event';
        break;
      case 5:
        s = 'Interhash / continental event';
        break;
      case 6:
        s = 'World Interhash / global event';
        break;
      case 7:
        s = 'Other special event';
        break;
    }

    return s;
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
