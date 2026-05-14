import 'package:dart_ipify/dart_ipify.dart';
import 'package:harrier_central/imports.dart';
import 'package:geolocator/geolocator.dart';

class ApproveLoginService {
  /// Calls hcapp_approveLogin and returns the raw response body.
  ///
  /// Returns an empty string on timeout or user-elected offline mode.
  /// Returns ERROR_KEY_OK_BTN_PRESSED if the user acknowledged a hard server
  /// error via dialog. Any other ERROR_PREFIX string means a handled API error.
  Future<String> approveLogin() async {
    String? uid = getStringPref(StringPrefsEnum.userId);
    if ((uid ?? '').isEmpty) {
      uid = GUID_EMPTY;
    }

    final String userId = uid!;

    final PackageInfo p = await PackageInfo.fromPlatform();

    final String version = p.version;
    final String buildNumber = p.buildNumber;

    final DeviceInfoPlugin deviceInfoPlugIn = DeviceInfoPlugin();

    String deviceType = 'unknown';
    String deviceName = 'unknown';
    String systemName = 'unknown';
    String systemVersion = 'unknown';
    String manufacturer = 'unknown';

    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfoPlugIn.androidInfo;
      deviceType = '${androidInfo.model} / device: ${androidInfo.device}';
      deviceName = '<unknown>';
      systemName = androidInfo.host;
      systemVersion =
          '${androidInfo.version.sdkInt} / release: ${androidInfo.version.release} / security patch: ${androidInfo.version.securityPatch ?? '<no Android security patch'}';
      manufacturer = androidInfo.brand;
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfoPlugIn.iosInfo;
      deviceType = iosInfo.model;
      deviceName = iosInfo.name;
      systemName = iosInfo.systemName;
      systemVersion = iosInfo.systemVersion;
      manufacturer = 'Apple';
    }

    // Collect the device's public IP and coarse geo info for server-side analytics.
    String ipInfoJson;
    try {
      final String ipv4 = await Ipify.ipv4();
      final Response response = await get(
        Uri.parse('https://ipinfo.io/$ipv4?token=$IPINFO_API_TOKEN'),
      )
          .catchError((dynamic error) {
            if (kDebugMode) print(error.toString());
            return Response('<no ip information available>', 500);
          })
          .timeout(
            const Duration(milliseconds: 4000),
            onTimeout: () => Response('<no ip information available>', 500),
          );
      ipInfoJson = response.body;
    } on Exception catch (_) {
      ipInfoJson = '''{
  "ip": "0.0.0.0",
  "hostname": "Ipify error",
  "city": "none",
  "region": "none",
  "country": "XX",
  "loc": "51.9340,4.4325",
  "org": "none",
  "postal": "2252",
  "timezone": "Europe/Amsterdam"
}''';
    }

    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '<none>';

    final String accessToken = Utilities.generateToken(
      userId,
      'hcapp_approveLogin',
      paramString: deviceSecret,
    );

    Position? position;
    if (deviceId.isNotEmpty) {
      position = await getLastKnownLocation();
    }

    final Map<String, String?> body = <String, String?>{
      'queryType': 'approveLogin',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'deviceType': deviceType,
      'deviceName': deviceName,
      'systemName': systemName,
      'systemVersion': systemVersion,
      'manufacturer': manufacturer,
      'latitude': position?.latitude.toString() ??
          (deviceInfo.deviceLat ?? DEFAULT_LATITUDE).toString(),
      'longitude': position?.longitude.toString() ??
          (deviceInfo.deviceLon ?? DEFAULT_LONGITUDE).toString(),
      'hcVersion': version,
      'buildNumber': buildNumber,
      'usesLocSvcs': appModel.hasLocationPermissions ? '1' : '0',
      'screenWidth': deviceInfo.deviceWidth.toInt().toString(),
      'screenHeight': deviceInfo.deviceHeight.toInt().toString(),
      'ipInfo': ipInfoJson,
      'locale': Get.deviceLocale?.toString() ?? '',
    };

    // Report any splash sequence viewed in the previous session so the server
    // can suppress it from showing again on other devices for the same user.
    final DateTime? splashSequenceViewed =
        getDatePref(DatePrefsEnum.splashSequenceViewedAt);
    if (splashSequenceViewed != null) {
      body['splashSequenceViewed'] = splashSequenceViewed.toString();
      body['splashSequenceRootName'] = getStringPref(
        StringPrefsEnum.splashSequenceRootNameViewed,
      );
    }

    final Future<Response> futureResponse = post(
      Uri.parse(BASE_AF_API_URL),
      headers: <String, String>{'content-type': 'application/json'},
      body: jsonEncode(body),
    ).catchError((dynamic error) => Response('<http error>', 500));

    // Three-stage timeout with user prompts: 7s warning → 15s warning → hard timeout.
    // This flow uses manual timeout staging rather than ServiceCommon.sendHttpPost
    // because startup needs user-facing "slow network" dialogs with a cancel option.
    Response resp = await futureResponse.timeout(
      const Duration(seconds: LOGIN_IS_DELAYED_WARNING_1),
      onTimeout: () => Response('<timeout error>', 999),
    );

    if (resp.statusCode == 999) {
      final bool keepWaiting = await _onLoginDelayed(
        'Harrier Central is waiting for a response from the server. It appears as though the network is slow. Please stand by while we wait for a server response.',
      );

      if (!keepWaiting) {
        futureResponse.ignore();
        return '';
      }

      resp = await futureResponse.timeout(
        const Duration(seconds: LOGIN_IS_DELAYED_WARNING_2),
        onTimeout: () => Response('<timeout error>', 999),
      );

      if (resp.statusCode == 999) {
        final bool keepWaiting2 = await _onLoginDelayed(
          'Harrier Central is still waiting for a response from the server. Let\'s give it just a bit more time.',
        );

        if (!keepWaiting2) {
          futureResponse.ignore();
          return '';
        }

        resp = await futureResponse.timeout(
          const Duration(seconds: LOGIN_TIMEOUT),
          onTimeout: () => _onTimeout(),
        );
      }
    }

    if (resp.statusCode == 999) return '';

    return ServiceCommon.checkHttpPostResponse(resp, jsonEncode(body));
  }

  Future<Position?> getLastKnownLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return Geolocator.getLastKnownPosition();
  }

  Future<bool> _onLoginDelayed(String message) async {
    return await Utilities.showAlert(
          'Slow Network',
          message,
          'Wait',
          showCancelButton: true,
          cancelButtonText: 'Continue offline',
        ) ??
        false;
  }

  Future<Response> _onTimeout() async {
    await Utilities.showAlert(
      'Network Error',
      'Harrier Central was not able to contact the server. Please check your network connection.\r\n\r\nYou may continue using the app in Offline Mode with cached data. Press the \'Offline Mode\' ribbon to find out when the last time the data was updated.',
      'Use Offline',
    );
    return Response('<timeout error>', 999);
  }
}
