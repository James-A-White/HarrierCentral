// @dart=2.11
// ignore_for_file: constant_identifier_names

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
        case QR_PREFIX_SPECIFIC_RUN_END:
          scanType = qrScanTypeFlag_runEnd;
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

  static bool isValidUrl(String url) {
    if ((url == null) || (url.isEmpty)) {
      return false;
    }
    final Uri uri = Uri.tryParse(url);
    return uri != null && uri.hasAbsolutePath && uri.scheme.startsWith('http');
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
                Text('Please confirm that you are signing up to hare this run${(hareList == null) ? '.' : ' with $hareList'}'),
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

  static List<String> parseSearchTokens(String searchText, String token) {
    List<String> results = <String>[];

    if ((searchText != null) && (searchText.isNotEmpty)) {
      Pattern pattern = r"[" + token + r"]\w+(?:\s+\w+)*";
      final RegExp regex = RegExp(pattern, caseSensitive: false);
      if (regex.hasMatch(searchText)) {
        for (RegExpMatch match in regex.allMatches(searchText)) {
          results.add(match[0].replaceFirst(token.replaceFirst(r'\', ''), '').trim().toLowerCase());
        }
      }
    }
    return results;
  }

  static List<double> getLatLongFromString(List<String> values) {
    for (String value in values) {
      if ((value != null) && (value.isNotEmpty)) {
        const Pattern pattern = r'[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)';
        final RegExp regex = RegExp(pattern, caseSensitive: false);
        if (regex.hasMatch(value)) {
          final String numStr = regex.allMatches(value).elementAt(0).group(0);
          final List<String> str = numStr.split(',');
          return <double>[double.tryParse(str[0]), double.tryParse(str[1])];
        }
      }
    }
    return <double>[null, null];
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

  static int checkSpecialHaring(int haringCount) {
    haringCount ??= 0;
    int result = specialRunNo;

    if (haringCount == 1) {
      result = specialRunFirstRun;
    }

    if ((haringCount % 5 == 0) && (haringCount > 0)) {
      result = specialRunFifthRun;
    }

    if (haringCount % 100 == 69) {
      result = specialRun69;
    }

    return result;
  }

  static Widget getProfilePic(String image, num width, num height, BuildContext context, String pageTitle) {
    return GestureDetector(
        onTap: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (BuildContext context) => ZoomableImagePage2(
                  key: const Key('511203069'),
                  pageTitle: pageTitle,
                  imageUrl: image.startsWith('http') ? image : null,
                  assetImage: image.contains('bundle://') ? 'images/avatars/${image.replaceAll('bundle://', '')}.jpg' : null,
                  appBarBackgroundColor: themeAppBarBackground,
                  background: Backgrounds.defaultHcBackground(),
                  margin: 20.0),
            ),
          );
        },
        child: image.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: image,
                placeholder: (BuildContext context, String url) => SizedBox(
                    height: height + .0,
                    width: width + .0,
                    child: const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.0,
                        ),
                      ),
                    )),
                errorWidget: (BuildContext context, String url, Object error) => Icon(Icons.error, size: height, color: Colors.red),
                //fadeOutDuration:  Duration(seconds: 1),
                fadeInDuration: const Duration(milliseconds: 0),
                width: width + .0,
                height: height + .0,
                fit: BoxFit.fill)
            : image.startsWith('bundle')
                ? Image(
                    width: width + .0,
                    height: height + .0,
                    fit: BoxFit.fill,
                    image: AssetImage(('images/avatars/${image.toLowerCase().replaceFirst('bundle://', '')}.jpg').toLowerCase()),
                  )
                : Image(
                    width: width + .0,
                    height: height + .0,
                    fit: BoxFit.fill,
                    image: const AssetImage('images/avatars/avatar-2.jpg'),
                  ));
  }

  static int checkSpecialRun(int runCount) {
    runCount ??= 0;

    int result = specialRunNo;

    if (((runCount == 0) || (runCount == 1))) {
      result = specialRunFirstRun;
    } else if (runCount == 5) {
      result = specialRunFifthRun;
    } else if (runCount == 10) {
      result = specialRunTenthRun;
    } else if (runCount % 100 == 69) {
      result = specialRun69;
    } else if (runCount > 0) {
      if (runCount % 25 == 0) {
        result = specialRun25;
      }

      if (runCount % 100 == 0) {
        result = specialRun100;
      }

      if (runCount % 250 == 0) {
        result = specialRun250;
      }

      if (runCount % 1000 == 0) {
        result = specialRun1000;
      }
    }

    if ((result == specialRunNo) && (runCount > 10)) {
      final String s = runCount.toString();
      final String reversed = s.split('').reversed.join('');

      if (s == reversed) {
        result = specialRunPalindrome;
      }
    }

    return result;
  }

  static Future<bool> showAlert(BuildContext context, String title, String body, String buttonText, {bool showCancelButton = false, String cancelButtonText = 'Cancel'}) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  body,
                  textAlign: TextAlign.justify,
                  style: Theme.of(context).textTheme.titleMedium,
                )
              ],
            ),
          ),
          actions: <Widget>[
            showCancelButton == true
                ? TextButton(
                    child: Text(cancelButtonText),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  )
                : Container(),
            TextButton(
              child: Text(buttonText),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> checkForInternetConnection(bool reconnectAttempt) async {
    final InternetConnectionChecker checker = InternetConnectionChecker();

    while (!await checker.hasConnection) {
      final bool useOffline = await IveCoreUtilities.showAlert(
          navigatorKey.currentContext,
          'Check Network',
          'Harrier Central is unable to detect a network connection.\r\n\r\nPlease check the network connection on your phone and try again, or you can continue to use the app in Offline Mode.',
          'Use Offline',
          showCancelButton: true,
          cancelButtonText: 'Try again');
      if (useOffline) {
        break;
      }

      await Future<void>.delayed(const Duration(seconds: 2));
    }

    if (await checker.hasConnection) {
      G0<AppModel>().connectionStatus = EnumConnectionStatus.connected;

      final List<AddressCheckOptions> addressesToCheck = <AddressCheckOptions>[];

      final List<InternetAddress> hcAddress = await InternetAddress.lookup(BASE_URL);

      for (InternetAddress address in hcAddress) {
        final AddressCheckOptions aco = AddressCheckOptions(
          address: address,
          timeout: const Duration(milliseconds: 10000),
          port: 80,
        );
        addressesToCheck.add(aco);
      }

      checker.addresses = addressesToCheck;

      if (!await checker.hasConnection) {
        await IveCoreUtilities.showAlert(
            navigatorKey.currentContext,
            'Server Offline',
            'The Harrier Central App is able to access the network but is unable to connect to our backend server.\r\n\r\nThis can happen if there is a problem with the network or our service is down for maintenance.\r\n\r\nYou can use the app offline or close the app and try again later.',
            'OK');

        G0<AppModel>().connectionStatus = EnumConnectionStatus.not_connected;
      }
    } else {
      G0<AppModel>().connectionStatus = EnumConnectionStatus.not_connected;
    }
  }
}
