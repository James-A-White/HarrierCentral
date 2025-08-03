// ignore_for_file: constant_identifier_names

import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

import 'package:crypto/crypto.dart';

import 'package:map_launcher/map_launcher.dart' as maps;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:harrier_central/pages/top_level/select_run_page.dart';

// class LatLon {
//   num latitude;
//   num longitude;
// }

class Utilities {
  //   // this is an unused variable to suppress a LINT warning
  //   int suppressWarning = 0;

  static const int qrScanTypeFlag_user = 0x00000001;
  static const int qrScanTypeFlag_userSecretCode = 0x00000002;
  static const int qrScanTypeFlag_runStart = 0x00000004;
  static const int qrScanTypeFlag_runEnd = 0x00000008;
  static const int qrScanTypeFlag_kennelRunStart = 0x00000010;
  static const int qrScanTypeFlag_kennelRunEnd = 0x00000020;
  static const int qrScanTypeFlag_resetCode = 0x00000040;
  static const int qrScanTypeFlag_authenticateWebPortal = 0x00000080;

  //   static int logCounter = 0;

  static String generateToken(
    String userId,
    String procName, {
    String paramString = '',
    int? timeWindow,
  }) {
    timeWindow ??= getIntPref(IntPrefsEnum.timeWindow) ?? 30;
    final Duration difference = DateTime.now().toUtc().difference(
      DateTime.utc(1993, 7, 25, 15, 0, 0),
    );
    //final int timeBlocks = (difference.inSeconds / 5760).toInt();
    final int timeBlocks = difference.inSeconds ~/ timeWindow;
    if (paramString.isNotEmpty) {
      paramString = '#${paramString.toUpperCase()}';
    }
    final String accessString =
        '$userId#$procName#${timeBlocks.toString()}$paramString';
    final List<int> bytes = utf8.encode(
      accessString.toUpperCase(),
    ); // data being hashed
    final Digest digest = sha256.convert(bytes);
    return '$digest'.toUpperCase();
  }

  static Map<String, String> validateScan(
    String scanText,
    int allowedScanTypes,
  ) {
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
      result = <String, String>{
        'validScan': false.toString(),
        'prefix': '',
        'content': '',
      };
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

      result = <String, String>{
        'validScan': scanAllowed.toString(),
        'prefix': prefix,
        'content': content,
        'validHcQr': validHcQr.toString(),
      };
    }

    return result;
  }

  static Future<void> openMapsSheet(
    BuildContext context,
    String title,
    maps.Coords coords,
    String address,
    ValueNotifier<bool> saveUserMapPreference,
  ) async {
    try {
      final List<maps.AvailableMap> availableMaps =
          await maps.MapLauncher.installedMaps;

      await showModalBottomSheet<dynamic>(
        context: navigatorKey.currentContext!,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        builder: (BuildContext context) {
          return SizedBox(
            height: (availableMaps.length * 64.0) + 170,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 14.0, top: 14.0),
                    child: Center(
                      child: Text(
                        'Select map provider',
                        style: TextStyle(color: Colors.black, fontSize: 24.0),
                      ),
                    ),
                  ),
                  const Divider(height: 1.0, color: Colors.black87),
                  Expanded(
                    child: ListView(
                      children: <Widget>[
                        for (maps.AvailableMap map in availableMaps)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              onTap: () async {
                                if (saveUserMapPreference.value) {
                                  await setStringPref(
                                    StringPrefsEnum.mapPreference,
                                    map.mapName,
                                  );
                                }
                                Navigator.of(
                                  navigatorKey.currentContext!,
                                ).pop();

                                await Future<void>.delayed(
                                  const Duration(milliseconds: 200),
                                );

                                // BUG in plugin - doesn't work when sending a title with Google maps
                                await map.showMarker(
                                  coords: coords,
                                  title:
                                      map.mapName.contains('Google')
                                          ? ''
                                          : title,
                                  description: address,
                                );
                              },
                              title: Text(
                                map.mapName,
                                style: ts_titleLargeBlack,
                              ),
                              leading: SvgPicture.asset(
                                map.icon,
                                height: 60.0,
                                width: 60.0,
                              ),
                            ),
                          ),
                        const SizedBox(height: 30.0),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // MapSnackbar(saveUserMapPreference, (bool x) {
                      //   setState(() {
                      //     saveUserMapPreference.value = x;
                      //   });
                      // }),
                      MapSnackbar(saveUserMapPreference),
                      Text('Always use this option', style: ts_titleBlack),
                      const SizedBox(width: 20.0),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  static bool isValidUrl(String? url) {
    if ((url ?? '').isEmpty) {
      return false;
    }
    final Uri? uri = Uri.tryParse(url!);
    return uri != null && uri.hasAbsolutePath && uri.scheme.startsWith('http');
  }

  // static Future<bool?> promptForHare(BuildContext context, String? hareList) async {
  //   return await showDialog<bool?>(
  //     context: context,
  //     barrierDismissible: false, // user must tap button!
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Will you Hare this run?',
  //   style: ts_alertDialogTitle,
  // ),
  //         content: SingleChildScrollView(
  //           child: ListBody(
  //             children: <Widget>[
  //               Text('Please confirm that you are signing up to hare this run${((hareList == null) || (hareList.isEmpty)) ? '.' : ' with $hareList'}'),
  //             ],
  //           ),
  //         ),
  //         actions: <Widget>[
  //                       TextButton(
  //             child: const Text('No Thanks!'),
  //             onPressed: () {
  //               Navigator.of(context).pop(false);
  //             },
  //           ),
  //                       TextButton(
  //             child: const Text('Yes, I\'ll Hare!'),
  //             onPressed: () {
  //               Navigator.of(context).pop(true);
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // static Future<bool?> promptForHare(String? hareList) async {
  //   return await Get.dialog<bool?>(
  //     AlertDialog(
  //       title: Text(
  //         'Will you Hare this run?',
  //         style: ts_alertDialogTitle,
  //       ),
  //       content: SingleChildScrollView(
  //         child: ListBody(
  //           children: <Widget>[
  //             Text(
  //               'Please confirm that you are signing up to hare this run${((hareList == null) || (hareList.isEmpty)) ? '.' : ' with $hareList'}',
  //               style: ts_alertDialogBody,
  //             ),
  //           ],
  //         ),
  //       ),
  //       actions: <Widget>[
  //         TextButton(
  //           style: text_button_style,
  //           child: Text(
  //             'No Thanks!',
  //             style: ts_button,
  //           ),
  //           onPressed: () {
  //             Get.back<bool?>(result: false, canPop: true);
  //           },
  //         ),
  //         TextButton(
  //           style: text_button_style,
  //           child: Text(
  //             'Yes, I\'ll Hare!',
  //             style: ts_button,
  //           ),
  //           onPressed: () {
  //             Get.back<bool?>(result: true, canPop: true);
  //           },
  //         ),
  //       ],
  //     ),

  //     barrierDismissible: false, // user must tap button!
  //   );
  // }

  static bool isOpeeOrTuna() {
    bool isOpeeOrTuna = false;

    final String currentUserId =
        getStringPref(StringPrefsEnum.userId) ?? '<no user id>';

    if ((currentUserId == '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC') ||
        (currentUserId == 'D0B7EF01-C6E3-4723-9D2F-2AE864A59F1A')) {
      isOpeeOrTuna = true;
    }

    return isOpeeOrTuna;
  }

  // static Future<void> subscribeToGeoLocationStream() async {
  //   G0<DeviceInfo>().deviceLat =
  //       getDoublePref(NumPrefsEnum.currentDeviceLat) ?? DEFAULT_LATITUDE;
  //   G0<DeviceInfo>().deviceLon =
  //       getDoublePref(NumPrefsEnum.currentDeviceLon) ?? DEFAULT_LONGITUDE;

  //   IveCoreUtilities.logTiming(
  //     'Geostatus query start',
  //     G0<AppModel>().appStartTime,
  //   );
  //   final LocationPermission permission = await Geolocator.checkPermission();

  //   IveCoreUtilities.logTiming(
  //     'Geolocation query start',
  //     G0<AppModel>().appStartTime,
  //   );
  //   if ((permission == LocationPermission.always) ||
  //       (permission == LocationPermission.whileInUse)) {
  //     G0<AppModel>().geoLocationStream = Geolocator.getPositionStream(
  //       locationSettings: const LocationSettings(
  //         accuracy: BASE_APP_LOCATION_ACCURACY,
  //         distanceFilter: 50,
  //       ),
  //     ).listen((Position position) {
  //       G0<DeviceInfo>().deviceLat = position.latitude + 0.0;
  //       G0<DeviceInfo>().deviceLon = position.longitude + 0.0;
  //       setNumPref(NumPrefsEnum.currentDeviceLat, position.latitude + 0.0);
  //       setNumPref(NumPrefsEnum.currentDeviceLon, position.longitude + 0.0);
  //       setDatePref(DatePrefsEnum.lastLocationUpdate, DateTime.now());
  //       // var xxx = 0

  //       //print('>>>>>>>>>>> geoloc stream update' + (position == null ? 'Unknown' : position.latitude.toString() + ', ' + position.longitude.toString()));
  //     });

  //     // don't wait for the position to resolve to return from
  //     // this function because we want the app to start quickly.

  //     // ignore: unawaited_futures
  //     Geolocator.getCurrentPosition(
  //       locationSettings: const LocationSettings(
  //         accuracy: LocationAccuracy.lowest,
  //       ),
  //     ).then((Position position) {
  //       G0<DeviceInfo>().deviceLat = position.latitude;
  //       G0<DeviceInfo>().deviceLon = position.longitude;
  //       setNumPref(NumPrefsEnum.currentDeviceLat, position.latitude + 0.0);
  //       setNumPref(NumPrefsEnum.currentDeviceLon, position.longitude + 0.0);
  //       setDatePref(DatePrefsEnum.lastLocationUpdate, DateTime.now());

  //       //print('>>>>>>>>>>> geoloc one-time update' + (position == null ? 'Unknown' : position.latitude.toString() + ', ' + position.longitude.toString()));
  //     });
  //   }
  // }

  static Future<void> subscribeToGeoLocationStream() async {
    // Load saved location as fallback
    final storedLat =
        (getDoublePref(NumPrefsEnum.currentDeviceLat) ?? DEFAULT_LATITUDE)
            .toDouble();
    final storedLon =
        (getDoublePref(NumPrefsEnum.currentDeviceLon) ?? DEFAULT_LONGITUDE)
            .toDouble();
    final appModel = G0<AppModel>();
    final deviceInfo = G0<DeviceInfo>();

    deviceInfo.deviceLat = storedLat;
    deviceInfo.deviceLon = storedLon;

    //IveCoreUtilities.logTiming('Geostatus query start', appModel.appStartTime);

    final permission = await Geolocator.checkPermission();
    //IveCoreUtilities.logTiming('Geolocation query start', appModel.appStartTime);

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      // Start streaming location updates
      appModel.geoLocationStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: BASE_APP_LOCATION_ACCURACY,
          distanceFilter: 50,
        ),
      ).listen(_updateDeviceLocation);

      // One-time location fetch (low priority, non-blocking)
      Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.lowest,
        ),
      ).then(_updateDeviceLocation);
    }
  }

  static void _updateDeviceLocation(Position position) {
    final deviceInfo = G0<DeviceInfo>();
    final lat = position.latitude.toDouble();
    final lon = position.longitude.toDouble();

    deviceInfo.deviceLat = lat;
    deviceInfo.deviceLon = lon;

    //print('lat = $lat, lon = $lon');

    setNumPref(NumPrefsEnum.currentDeviceLat, lat);
    setNumPref(NumPrefsEnum.currentDeviceLon, lon);
    setDatePref(DatePrefsEnum.lastLocationUpdate, DateTime.now());
  }

  static String? validateEmail(String? value) {
    if ((value != null) && (value.isNotEmpty)) {
      const String pattern =
          r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?";
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

    if (searchText.isNotEmpty) {
      String pattern = r"[" + token + r"]\w+(?:\s+\w+)*";
      final RegExp regex = RegExp(pattern, caseSensitive: false);
      if (regex.hasMatch(searchText)) {
        for (RegExpMatch match in regex.allMatches(searchText)) {
          if (match[0] != null) {
            results.add(
              match[0]!
                  .replaceFirst(token.replaceFirst(r'\', ''), '')
                  .trim()
                  .toLowerCase(),
            );
          }
        }
      }
    }
    return results;
  }

  static List<double?> getLatLongFromString(List<String?> values) {
    for (String? value in values) {
      if ((value ?? '').isNotEmpty) {
        const String pattern =
            r'[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)';
        final RegExp regex = RegExp(pattern, caseSensitive: false);
        if (regex.hasMatch(value!)) {
          final String numStr =
              regex.allMatches(value).elementAt(0).group(0) ?? '';
          final List<String> strs = numStr.split(',');
          if (strs.length == 2) {
            return <double?>[
              double.tryParse(strs[0]),
              double.tryParse(strs[1]),
            ];
          }
        }
      }
    }
    return <double?>[null, null];
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

  static String getDistance(double meters, {bool isMetric = true}) {
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

  static Widget getProfilePic(
    String image,
    double width,
    double height,
    BuildContext context,
    String pageTitle,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder:
                (BuildContext context) => ZoomableImagePage2(
                  key: const Key('511203069'),
                  pageTitle: pageTitle,
                  imageUrl: image.startsWith('http') ? image : null,
                  assetImage:
                      image.contains('bundle://')
                          ? 'images/avatars/${image.replaceAll('bundle://', '')}.jpg'
                          : null,
                  appBarBackgroundColor: themeAppBarBackground,
                  background: Backgrounds.defaultHcBackground(),
                  margin: 20.0,
                ),
          ),
        );
      },
      child:
          image.startsWith('http')
              ? CachedNetworkImage(
                imageUrl: image,
                placeholder:
                    (BuildContext context, String url) => SizedBox(
                      height: height,
                      width: width,
                      child: const Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: HcCircularProgressIndicator(
                            key: Key('1396562'),
                          ),
                        ),
                      ),
                    ),
                errorWidget:
                    (BuildContext context, String url, dynamic error) =>
                        Icon(Icons.error, size: height, color: hc_red),
                //fadeOutDuration:  Duration(seconds: 1),
                fadeInDuration: const Duration(milliseconds: 0),
                width: width,
                height: height,
                fit: BoxFit.fill,
              )
              : image.startsWith('bundle')
              ? Image(
                width: width,
                height: height,
                fit: BoxFit.fill,
                image: AssetImage(
                  ('images/avatars/${image.toLowerCase().replaceFirst('bundle://', '')}.jpg')
                      .toLowerCase(),
                ),
              )
              : Image(
                width: width,
                height: height,
                fit: BoxFit.fill,
                image: const AssetImage('images/avatars/avatar-2.jpg'),
              ),
    );
  }

  static int checkSpecialRun(int runCount) {
    int result = specialRunNo;

    if ((runCount == 1)) {
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

  static Future<bool?> showAlert(
    String title,
    String body,
    String buttonText, {
    bool showCancelButton = false,
    String cancelButtonText = 'Cancel',
    TextAlign textAlign = TextAlign.left,
  }) async {
    return Get.dialog<bool?>(
      AlertDialog(
        title: Text(title, style: ts_alertDialogTitle),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(body, textAlign: textAlign, style: ts_alertDialogBody),
            ],
          ),
        ),
        actions: <Widget>[
          if (showCancelButton)
            TextButton(
              style: text_button_style,
              child: Text(cancelButtonText, style: ts_button),
              onPressed: () {
                Get.back(result: false, canPop: true);
              },
            )
          else
            Container(),
          TextButton(
            style: text_button_style,
            child: Text(buttonText, style: ts_button),
            onPressed: () {
              Get.back(result: true, canPop: true);
            },
          ),
        ],
      ),
      barrierDismissible: false, // user must tap button!
    );
  }

  static Future<bool?> showAlert2(
    String title,
    String body,
    String buttonText, {
    bool showCancelButton = false,
    String cancelButtonText = 'Cancel',
  }) async {
    return Get.dialog<bool?>(
      AlertDialog(
        title: Text(title, style: ts_alertDialogTitle),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                body,
                textAlign: TextAlign.justify,
                style: ts_alertDialogBody,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          showCancelButton == true
              ? TextButton(
                style: text_button_style,
                child: Text(cancelButtonText, style: ts_button),
                onPressed: () {
                  Get.back<bool?>(result: false, canPop: true);
                },
              )
              : Container(),
          TextButton(
            style: text_button_style,
            child: Text(buttonText, style: ts_button),
            onPressed: () {
              Get.back<bool?>(result: true, canPop: true);
            },
          ),
        ],
      ),
      barrierDismissible: false, // user must tap button!
    );
  }

  static Future<void> checkForInternetConnection(bool reconnectAttempt) async {
    final String? userId = getStringPref(StringPrefsEnum.userId);
    if (userId != null) {
      final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
      final String deviceSecret =
          getStringPref(StringPrefsEnum.deviceSecret) ?? '';

      // NOTE: Eventually refactor the internet connectivity checks into a GetX service

      // The first check should be a simple end-to-end check with the Harrier Central backend
      final String accessToken = Utilities.generateToken(
        userId,
        'hcapp_checkConnection',
        paramString: deviceSecret,
      );

      final Map<String, String?> bodyMap = <String, String?>{
        'queryType': 'checkConnection',
        'deviceId': deviceId,
        'accessToken': accessToken,
      };

      final String body = jsonEncode(bodyMap);

      final String responseBody = await ServiceCommon.sendHttpPostV2(
        body,
        bypassConnectionCheck: true,
      );

      if (!responseBody.startsWith(ERROR_PREFIX)) {
        if (jsonDecode(responseBody)[0][0]['result'] == 'Connected') {
          G0<AppModel>().connectionStatus = EnumConnectionStatus2.connected;
          // check against the Harrier Central backend succeeded
          return;
        }
      }
    }

    // check against the Harrier Central backend failed, let's check the internet connection
    // using the InternetConnection package

    final backendChecker = InternetConnection.createInstance(
      customCheckOptions: [
        InternetCheckOption(uri: Uri.parse(BASE_AF_CONNECTION_TEST_URL)),
      ],
    );

    bool backendAvailable = await backendChecker.hasInternetAccess;

    // Retry logic if Harrier Central server is unavailable
    while (!backendAvailable) {
      final fallbackChecker = InternetConnection.createInstance(
        customCheckOptions: [
          InternetCheckOption(
            uri: Uri.parse('https://www.google.com/generate_204'),
          ),
          InternetCheckOption(
            uri: Uri.parse('https://www.msftconnecttest.com/connecttest.txt'),
          ),
        ],
      );

      final internetAvailable = await fallbackChecker.hasInternetAccess;

      if (internetAvailable) {
        // Internet is up but our backend is down
        await Utilities.showAlert(
          'Server Offline',
          'The Harrier Central App is able to access the network but is unable to connect to our backend server.\n\nThis can happen if there is a problem with the network or our service is down for maintenance.\n\nYou can use the app offline or close the app and try again later.',
          'OK',
        );
        G0<AppModel>().connectionStatus = EnumConnectionStatus2.notConnected;
        return;
      } else {
        // No internet at all — retry dialog
        final bool? useOffline = await Utilities.showAlert(
          'Check Network',
          'Harrier Central is unable to detect a network connection.\n\nPlease check the network connection on your phone and try again, or you can continue to use the app in Offline Mode.',
          'Use Offline',
          showCancelButton: true,
          cancelButtonText: 'Try again',
        );
        if (useOffline ?? true) {
          G0<AppModel>().connectionStatus = EnumConnectionStatus2.notConnected;
          return;
        }

        await Future<void>.delayed(const Duration(seconds: 2));
        backendAvailable = await backendChecker.hasInternetAccess;
      }
    }

    // If we get here, everything is good
    G0<AppModel>().connectionStatus = EnumConnectionStatus2.connected;
  }

  static String getFullLatLong(EventModel evt) {
    String fullLatLon = '';

    double? lat = evt.hcLatitude;
    double? lon = evt.hcLongitude;

    if (evt.useFbLatLon != 0) {
      lat = evt.fbLatitude;
      lon = evt.fbLongitude;
    }
    if ((lat != null) && (lon != null)) {
      fullLatLon = '$lat, $lon';
    }
    return fullLatLon;
  }

  static String getUserFriendlyLocation(EventModel evt) {
    String s = '';

    if (getFullAddress(evt) != '') {
      s = getFullAddress(evt);
    } else if (getFullLatLong(evt) != '') {
      s = getFullLatLong(evt);
    } else if ((evt.locationOneLineDesc ?? '') != '') {
      s = evt.locationOneLineDesc ?? '';
    }

    return s;
  }

  static String getFullAddress(EventModel evt) {
    String s = '';

    if ((evt.locationStreet ?? '').isNotEmpty) {
      s = evt.locationStreet!;
    }

    if ((evt.locationCity ?? '').isNotEmpty) {
      if (s.isNotEmpty) {
        s += ', ';
      }
      s += evt.locationCity!;
    }

    if ((evt.locationSubRegion ?? '').isNotEmpty) {
      if (s.isNotEmpty) {
        s += ', ';
      }
      s += evt.locationSubRegion!;
    }

    if ((evt.locationRegion ?? '').isNotEmpty) {
      if (s.isNotEmpty) {
        s += ', ';
      }
      s += evt.locationRegion!;
    }

    if ((evt.locationCountry ?? '').isNotEmpty) {
      if (s.isNotEmpty) {
        s += ', ';
      }
      s += evt.locationCountry!;
    }

    if ((evt.locationPostCode ?? '').isNotEmpty) {
      if (s.isNotEmpty) {
        s += ', ';
      }
      s += evt.locationPostCode!;
    }

    return s;
  }

  static Future<void> checkAreWeAtRunStart({String? eventId}) async {
    //final Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.lowest);

    var lastRunStartCheck = getDatePref(DatePrefsEnum.lastRunStartCheck);
    if (lastRunStartCheck == null) {
      await setDatePref(DatePrefsEnum.lastRunStartCheck, DateTime(2000));
      lastRunStartCheck = DateTime(2000);
    }

    ////// TODO: Re-enable this before next release
    // if (DateTime.now().difference(lastRunStartCheck).inMinutes < 2) {
    //   return;
    // }

    await setDatePref(DatePrefsEnum.lastRunStartCheck, DateTime.now());

    final List<AreWeAtRunModel> resultList =
        await CommonQueries.areWeAtRunStart(eventId: eventId);
    final String userId = getStringPref(StringPrefsEnum.userId)!;

    if (resultList.length == 1) {
      final AreWeAtRunModel result = resultList[0];

      if (result.eventId != EMPTY_RESULT) {
        final ConfirmAutoCheckinPopup popup = ConfirmAutoCheckinPopup(
          title: 'Check-in to Run',
          areWeAtRunData: result,
          okButtonTitle: 'Yes',
          cancelButtonTitle: 'No',
        );

        final EnumCheckinOptions<int>? retVal =
            await showDialog<EnumCheckinOptions<int>>(
              context: navigatorKey.currentContext!,
              barrierDismissible: false, // user must tap button!
              builder: (BuildContext context) {
                return popup;
              },
            );

        if (retVal == enumCheckInOption_Yes) {
          await G0<TableModel>().hasherEventMapService.setEventAttendence(
            result.eventId,
            userId,
            AppDomainType.user,
            attendenceAtHash.value,
          );

          if (Get.isRegistered<FutureRunListPageController>()) {
            await Get.find<FutureRunListPageController>().refreshFromTable(
              true,
            );
          }
        } else if ((retVal == enumCheckInOption_YesAndPayByCredit) ||
            (retVal == enumCheckInOption_YesAndPayByBankXfer)) {
          final PaymentsService paySrv = PaymentsService();
          await paySrv.payForEvent(
            result.eventId,
            userId,
            GUID_EMPTY,
            retVal == enumCheckInOption_YesAndPayByCredit
                ? paymentHashCredit.value
                : paymentBankTransfer.value,
            result.membershipExpirationDate.isAfter(DateTime.now())
                ? result.memberPrice
                : result.nonMemberPrice,
            attendenceAtHash.value,
            payForRunOnly,
            AppDomainType.user,
          );
        } else if ((retVal == enumCheckInOption_YesAndPayPlusExtrasByCredit) ||
            (retVal == enumCheckInOption_YesAndPayPlusExtrasByBankXfer)) {
          final PaymentsService paySrv = PaymentsService();
          await paySrv.payForEvent(
            result.eventId,
            userId,
            GUID_EMPTY,
            retVal == enumCheckInOption_YesAndPayPlusExtrasByCredit
                ? paymentHashCredit.value
                : paymentBankTransfer.value,
            result.extrasCost +
                (result.membershipExpirationDate.isAfter(DateTime.now())
                    ? result.memberPrice
                    : result.nonMemberPrice),
            attendenceAtHash.value,
            payForRunAndExtras,
            AppDomainType.user,
          );
        }
      }
    } else if (resultList.length > 1) {
      // look through the list of runs and determine if this hasher is
      // at any of the runs on the list. If so, don't show the
      // selection view
      bool showRunList = true;
      final Map<String, bool> selectedRuns = <String, bool>{};

      for (AreWeAtRunModel result in resultList) {
        selectedRuns[result.eventId] =
            false; //prepare the selection result list
        if (result.attendenceState >= attendenceAtHash.value) {
          showRunList = false;
          break;
        }
      }

      if (showRunList) {
        var doCheckIn =
            await Get.to<bool?>(
              SelectRunPage(runList: resultList, selected: selectedRuns),
            ) ??
            false;

        if (doCheckIn) {
          for (AreWeAtRunModel result in resultList) {
            if ((selectedRuns.containsKey(result.eventId)) &&
                (selectedRuns[result.eventId] == true)) {
              await G0<TableModel>().hasherEventMapService.setEventAttendence(
                result.eventId,
                userId,
                AppDomainType.user,
                attendenceAtHash.value,
              );
            }
          }
        }
      }
    }
  }
}
