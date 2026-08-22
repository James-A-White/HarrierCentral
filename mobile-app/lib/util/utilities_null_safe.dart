// ignore_for_file: constant_identifier_names

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/top_level/select_run_page.dart';
import 'package:intl/intl.dart';
import 'package:map_launcher/map_launcher.dart' as maps;

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
                                  title: map.mapName.contains('Google')
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
                      //   setStateIfMounted(() {
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
        debugPrint('');
      }
    }
  }

  static bool isValidUrl(String? url) {
    if ((url ?? '').isEmpty) {
      return false;
    }
    final Uri? uri = Uri.tryParse(url!);
    return uri != null && uri.hasAbsolutePath && uri.scheme == 'https';
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
  //   deviceInfo.deviceLat =
  //       getDoublePref(NumPrefsEnum.currentDeviceLat) ?? DEFAULT_LATITUDE;
  //   deviceInfo.deviceLon =
  //       getDoublePref(NumPrefsEnum.currentDeviceLon) ?? DEFAULT_LONGITUDE;

  //   IveCoreUtilities.logTiming(
  //     'Geostatus query start',
  //     appModel.appStartTime,
  //   );
  //   final LocationPermission permission = await Geolocator.checkPermission();

  //   IveCoreUtilities.logTiming(
  //     'Geolocation query start',
  //     appModel.appStartTime,
  //   );
  //   if ((permission == LocationPermission.always) ||
  //       (permission == LocationPermission.whileInUse)) {
  //     appModel.geoLocationStream = Geolocator.getPositionStream(
  //       locationSettings: const LocationSettings(
  //         accuracy: BASE_APP_LOCATION_ACCURACY,
  //         distanceFilter: 50,
  //       ),
  //     ).listen((Position position) {
  //       deviceInfo.deviceLat = position.latitude + 0.0;
  //       deviceInfo.deviceLon = position.longitude + 0.0;
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
  //       deviceInfo.deviceLat = position.latitude;
  //       deviceInfo.deviceLon = position.longitude;
  //       setNumPref(NumPrefsEnum.currentDeviceLat, position.latitude + 0.0);
  //       setNumPref(NumPrefsEnum.currentDeviceLon, position.longitude + 0.0);
  //       setDatePref(DatePrefsEnum.lastLocationUpdate, DateTime.now());

  //       //print('>>>>>>>>>>> geoloc one-time update' + (position == null ? 'Unknown' : position.latitude.toString() + ', ' + position.longitude.toString()));
  //     });
  //   }
  // }

  // static Future<void> subscribeToGeoLocationStream() async {
  //   // Load saved location as fallback
  //   final storedLat =
  //       (getDoublePref(NumPrefsEnum.currentDeviceLat) ?? DEFAULT_LATITUDE)
  //           .toDouble();
  //   final storedLon =
  //       (getDoublePref(NumPrefsEnum.currentDeviceLon) ?? DEFAULT_LONGITUDE)
  //           .toDouble();

  //   deviceInfo.deviceLat = storedLat;
  //   deviceInfo.deviceLon = storedLon;

  //   //IveCoreUtilities.logTiming('Geostatus query start', appModel.appStartTime);

  //   final permission = await Geolocator.checkPermission();
  //   //IveCoreUtilities.logTiming('Geolocation query start', appModel.appStartTime);

  //   if (permission == LocationPermission.always ||
  //       permission == LocationPermission.whileInUse) {
  //     // Start streaming location updates
  //     appModel.geoLocationStream = Geolocator.getPositionStream(
  //       locationSettings: const LocationSettings(
  //         accuracy: BASE_APP_LOCATION_ACCURACY,
  //         distanceFilter: 50,
  //       ),
  //     ).listen(_updateDeviceLocation);

  //     // One-time location fetch (low priority, non-blocking)
  //     Geolocator.getCurrentPosition(
  //       locationSettings: const LocationSettings(
  //         accuracy: LocationAccuracy.lowest,
  //       ),
  //     ).then(_updateDeviceLocation);
  //   }
  // }

  // static void _updateDeviceLocation(Position position) {
  //   final lat = position.latitude.toDouble();
  //   final lon = position.longitude.toDouble();

  //   deviceInfo.deviceLat = lat;
  //   deviceInfo.deviceLon = lon;

  //   //print('lat = $lat, lon = $lon');

  //   setNumPref(NumPrefsEnum.currentDeviceLat, lat);
  //   setNumPref(NumPrefsEnum.currentDeviceLon, lon);
  //   setDatePref(DatePrefsEnum.lastLocationUpdate, DateTime.now());
  // }

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
    if (!appModel.hasLocationPermissions) {
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
      onTap: () async {
        await Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => ZoomableImagePage2(
              key: const Key('511203069'),
              pageTitle: pageTitle,
              imageUrl: blobUrlForPhoto(image),
              appBarBackgroundColor: themeAppBarBackground,
              background: Backgrounds.defaultHcBackground(),
              margin: 20.0,
            ),
          ),
        );
      },
      child: Image(
        width: width,
        height: height,
        fit: BoxFit.fill,
        image: avatarImageProvider(image),
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
    // Early boot: initServices runs before GetMaterialApp mounts, so there is
    // no overlay yet — Get.dialog would null-check crash, and an unhandled
    // throw there kills main() and leaves the app on the splash forever
    // (observed on Android with stale credentials, 2026-08-22). Log the
    // alert's content to the harvest and skip showing it.
    if (Get.context == null || Get.overlayContext == null) {
      BootLogger.logError(
        '[showAlert] suppressed — no overlay yet',
        '$title: $body',
        null,
      );
      return null;
    }
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

  static Future<bool> checkHcServer() async {
    const Duration hcServerTimeout = Duration(milliseconds: 5000);
    try {
      // hcapp_checkConnection has no parameters — no auth required.
      final Map<String, String?> bodyMap = <String, String?>{
        'queryType': 'checkConnection',
      };

      final String body = jsonEncode(bodyMap);

      final String responseBody = await ServiceCommon.sendHttpPost(
        () => body,
        bypassConnectionCheck: true,
      ).timeout(hcServerTimeout, onTimeout: () => '${ERROR_PREFIX}Timeout');

      if (!responseBody.startsWith(ERROR_PREFIX)) {
        final decoded = jsonDecode(responseBody);
        // Current API short-circuits the checkConnection ping and returns
        // {"connected": true} without touching the SP.
        if (decoded is Map && decoded['connected'] == true) {
          return true; // ✅ success
        }
        // Back-compat: older SP-shaped response [[{"result":"Connected"}]].
        if (decoded is List && decoded.isNotEmpty) {
          final row0 = decoded[0];
          if (row0 is List && row0.isNotEmpty) {
            final result = (row0[0] as Map<String, dynamic>?)?['result'];
            if (result == 'Connected') {
              return true; // ✅ success
            }
          }
        }
      } else {
        // print(
        //   'No HC server detected: ${DateTime.now().millisecondsSinceEpoch}',
        // );
        return false;
      }
    } catch (e) {
      debugPrint('[Utilities.checkHcServer] error: $e');
    }

    return false;
  }

  // Fast internet check: interface present + general reachability probe.
  // Does NOT check the HC backend — that full end-to-end check (API → SP → DB)
  // is done separately by checkHcServer() / NetworkService.backendReachable.
  static Future<bool> checkForInternetConnection() async {
    const Duration internetCheckTimeout = Duration(milliseconds: 3000);

    final connectivity = Connectivity();
    List<ConnectivityResult> interfaces = [];
    try {
      interfaces = await connectivity.checkConnectivity();
    } catch (_) {
      interfaces = [ConnectivityResult.none];
    }

    if (!interfaces.any((r) => r != ConnectivityResult.none)) return false;

    try {
      final checker = InternetConnection.createInstance(
        customCheckOptions: [
          InternetCheckOption(uri: Uri.parse(CONNECTION_TEST_GOOGLE_URL)),
          InternetCheckOption(uri: Uri.parse(CONNECTION_TEST_MSFT_URL)),
        ],
      );
      return await checker.hasInternetAccess.timeout(
        internetCheckTimeout,
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    }
  }

  static bool isConnected({
    bool showDialog = false,
    String? title,
    String? message,
  }) {
    final network = Get.find<NetworkService>();
    bool isConnected = network.isOnline();
    if (!isConnected && showDialog) {
      unawaited(
        Utilities.showAlert(
          title ?? 'Offline Mode',
          message ??
              'This feature is not available in offline mode. Please connect to the internet to use this feature',
          'OK',
        ),
      );
    }
    return isConnected;
  }

  static bool isNotConnected() {
    final network = Get.find<NetworkService>();
    return !network.isOnline();
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

  // Returns a map-resolvable location string for use in calendar invites and
  // similar contexts where the string must be parseable by a mapping service.
  //
  // Priority:
  //   1. Structured address — only when specific enough (postcode present, or
  //      street + city both present). Skips subRegion and omits street when
  //      neither city nor postcode is available.
  //   2. Coordinates — "lat,lon" decimal format, respecting useFbLatLon.
  //   3. locationOneLineDesc — human-readable fallback (may not be map-resolvable).
  //   4. null — nothing useful available; callers should treat as absent.
  static String? buildMapLocation(EventModel evt) {
    final street = (evt.locationStreet ?? '').trim();
    final city = (evt.locationCity ?? '').trim();
    final region = (evt.locationRegion ?? '').trim();
    final postCode = (evt.locationPostCode ?? '').trim();
    final country = (evt.locationCountry ?? '').trim();

    if (postCode.isNotEmpty || (street.isNotEmpty && city.isNotEmpty)) {
      final parts = <String>[];
      if (street.isNotEmpty && (city.isNotEmpty || postCode.isNotEmpty)) {
        parts.add(street);
      }
      if (city.isNotEmpty) parts.add(city);
      if (region.isNotEmpty) parts.add(region);
      if (postCode.isNotEmpty) parts.add(postCode);
      if (country.isNotEmpty) parts.add(country);
      if (parts.isNotEmpty) return parts.join(', ');
    }

    double? lat = evt.hcLatitude;
    double? lon = evt.hcLongitude;
    if (evt.useFbLatLon != 0) {
      lat = evt.fbLatitude;
      lon = evt.fbLongitude;
    }
    if (lat != null && lon != null) return '$lat,$lon';

    final oneLineDesc = (evt.locationOneLineDesc ?? '').trim();
    return oneLineDesc.isNotEmpty ? oneLineDesc : null;
  }

  static String getSqfliteTimeOffset({int offsetInMinutes = 0}) {
    // Local offset relative to UTC (can include half-hours, etc.)
    final tzOffsetMinutes =
        -(DateTime.now().timeZoneOffset.inMinutes + offsetInMinutes);
    final offsetFromGmtToLocal = tzOffsetMinutes >= 0
        ? '+$tzOffsetMinutes minutes'
        : '$tzOffsetMinutes minutes';
    return offsetFromGmtToLocal;
  }

  // Guards the passive check against overlapping runs. Boot, resume and
  // screen-unlock can all fire near-simultaneously; without this, each would
  // launch its own GPS read + query (and potentially stack a second dialog).
  static bool _isAtRunStartRunning = false;

  static Future<void> isAtRunStart({String? eventId}) async {
    debugPrint('[BOOT] Utilities.isAtRunStart: start, eventId=${eventId ?? "null"}: ${DateTime.now().millisecondsSinceEpoch}ms');
    //final Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.lowest);

    // A notification tap passes an explicit eventId — deliberate user intent
    // that must never be throttled or dropped by the concurrency guard. The
    // throttle and guard apply only to the passive (eventId == null) path that
    // fires on boot, resume and screen-unlock.
    final bool passive = eventId == null;

    if (passive) {
      if (_isAtRunStartRunning) {
        debugPrint('[BOOT] Utilities.isAtRunStart: already running, skipping: ${DateTime.now().millisecondsSinceEpoch}ms');
        return;
      }

      var lastRunStartCheck = getDatePref(DatePrefsEnum.lastRunStartCheck);
      if (lastRunStartCheck == null) {
        await setDatePref(DatePrefsEnum.lastRunStartCheck, DateTime(2000));
        lastRunStartCheck = DateTime(2000);
      }

      final minutesSinceLastCheck =
          DateTime.now().difference(lastRunStartCheck).inMinutes;
      if (minutesSinceLastCheck < 2) {
        debugPrint('[BOOT] Utilities.isAtRunStart: throttled (${minutesSinceLastCheck}min since last check): ${DateTime.now().millisecondsSinceEpoch}ms');
        return;
      }
      debugPrint('[BOOT] Utilities.isAtRunStart: throttle passed (${minutesSinceLastCheck}min), querying: ${DateTime.now().millisecondsSinceEpoch}ms');

      _isAtRunStartRunning = true;
    }

    try {
      final List<AreWeAtRunModel> resultList = await CommonQueries.isAtRunStart(
        eventId: eventId,
      );

      // Stamp the throttle only AFTER the (GPS-bound, up to ~20s) query has
      // actually run. Stamping up-front burned the 2-minute window on attempts
      // that failed because GPS was still warming up, locking out the next
      // trigger before it had a chance to succeed.
      if (passive) {
        await setDatePref(DatePrefsEnum.lastRunStartCheck, DateTime.now());
      }
      debugPrint('[BOOT] Utilities.isAtRunStart: query returned ${resultList.length} candidate run(s): ${DateTime.now().millisecondsSinceEpoch}ms');
      final String userId = currentUserId;

      if (resultList.length == 1) {
      final AreWeAtRunModel result = resultList[0];

      final String blockAutoCheckinForThisEventId =
          getStringPref(StringPrefsEnum.blockAutoCheckinForThisEventId) ?? '';

      if (blockAutoCheckinForThisEventId == result.eventId) {
        debugPrint('[BOOT] Utilities.isAtRunStart: auto check-in blocked for this event, returning: ${DateTime.now().millisecondsSinceEpoch}ms');
        // user has previously declined auto check-in for this event
        return;
      }

      if (result.eventId != EMPTY_RESULT) {
        debugPrint('[BOOT] Utilities.isAtRunStart: showing check-in dialog for "${result.eventName}": ${DateTime.now().millisecondsSinceEpoch}ms');
        final ConfirmAutoCheckinPopup popup = ConfirmAutoCheckinPopup(
          title: 'Check-in to Run',
          areWeAtRunData: result,
          okButtonTitle: 'Yes',
          cancelButtonTitle: 'No',
        );

        final EnumCheckinOptions? retVal = await showDialog<EnumCheckinOptions>(
          context: navigatorKey.currentContext!,
          barrierDismissible: false, // user must tap button!
          builder: (BuildContext context) {
            return popup;
          },
        );
        debugPrint('[BOOT] Utilities.isAtRunStart: dialog dismissed, retVal=$retVal: ${DateTime.now().millisecondsSinceEpoch}ms');

        if (retVal == enumCheckInOption_Cancel) {
          // user decided not to check in automatically. Let's take note of this so we don't show the popup again.
          await setStringPref(
            StringPrefsEnum.blockAutoCheckinForThisEventId,
            result.eventId,
          );
        } else if (retVal == enumCheckInOption_Yes) {
          final adHoc = await tableModel.hasherEventMapService.setEventAttendence(
            result.eventId,
            userId,
            AppDomainType.user,
            attendenceAtHash.value,
          );

          if (adHoc.isEmpty) {
            showHcSnackbar(
              'Check-in failed — please check your connection and try again.',
              isError: true,
            );
          } else {
            showHcSnackbar('Checked in to ${result.eventName}!');
            if (Get.isRegistered<FutureRunListPageController>()) {
              await Get.find<FutureRunListPageController>().refreshFromTable(
                true,
              );
            }
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

        // The user picked a "Yes" option (checked in). Clear any prior
        // "don't ask again" block for this event — a one-time "No" should not
        // suppress the prompt for this event permanently. ("No"/Cancel still
        // sets the block above, as intended.)
        if (retVal != null && retVal != enumCheckInOption_Cancel) {
          await setStringPref(
            StringPrefsEnum.blockAutoCheckinForThisEventId,
            '',
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
        final Map<String, bool>? selections = await Get.to<Map<String, bool>?>(
          SelectRunPage(runList: resultList, selected: selectedRuns),
        );

        // null = Cancel tapped — no writes, dialog may appear again
        if (selections != null) {
          final List<String> checkInIds = selections.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList();
          final List<String> rsvpNoIds = selections.entries
              .where((e) => !e.value)
              .map((e) => e.key)
              .toList();

          final List<dynamic> adHoc =
              await tableModel.hasherEventMapService.setMultiRunRsvpAndCheckin(
            checkInEventIds: checkInIds,
            rsvpNoEventIds: rsvpNoIds,
          );

          if (adHoc.isEmpty) {
            showHcSnackbar(
              'Save failed — please check your connection and try again.',
              isError: true,
            );
          } else {
            if (checkInIds.isNotEmpty) {
              showHcSnackbar(
                checkInIds.length == 1
                    ? 'Checked in!'
                    : 'Checked in to ${checkInIds.length} runs!',
              );
            }
            if (Get.isRegistered<FutureRunListPageController>()) {
              await Get.find<FutureRunListPageController>().refreshFromTable(true);
            }
          }
        }
      }
    }
    } finally {
      if (passive) {
        _isAtRunStartRunning = false;
      }
    }
  }

  static String describeDayOffset(int dayOffset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = today.add(Duration(days: dayOffset));

    final differenceDays = eventDate.difference(today).inDays;

    // --- Short, natural phrasing first ---
    if (differenceDays == 0) return 'Today';
    if (differenceDays == 1) return 'Tomorrow';
    if (differenceDays == -1) return 'Yesterday';

    // Handle near-term (under a month) as "weeks and days"
    if (differenceDays.abs() < 30) {
      final absDays = differenceDays.abs();
      final weeks = absDays ~/ 7;
      final days = absDays % 7;

      final parts = <String>[];
      if (weeks > 0) parts.add('$weeks ${weeks == 1 ? "week" : "weeks"}');
      if (days > 0) parts.add('$days ${days == 1 ? "day" : "days"}');

      final phrase = parts.join(', ');
      return differenceDays > 0 ? 'in $phrase' : '$phrase ago';
    }

    // --- Longer spans (months/years/days) ---
    bool isFuture = differenceDays > 0;
    DateTime earlier = isFuture ? today : eventDate;
    DateTime later = isFuture ? eventDate : today;

    int years = later.year - earlier.year;
    int months = later.month - earlier.month;
    int days = later.day - earlier.day;

    // Adjust for negative day/month rollover
    if (days < 0) {
      final prevMonth = DateTime(later.year, later.month, 0);
      days += prevMonth.day;
      months -= 1;
    }

    if (months < 0) {
      months += 12;
      years -= 1;
    }

    final parts = <String>[];
    if (years > 0) parts.add('$years ${years == 1 ? "yr" : "yrs"}');
    if (months > 0) parts.add('$months ${months == 1 ? "m" : "m"}');
    if (days > 0 || parts.isEmpty) {
      parts.add('$days ${days == 1 ? "day" : "days"}');
    }

    final phrase = parts.join(', ');
    return isFuture ? 'in $phrase' : '$phrase ago';
  }
}
