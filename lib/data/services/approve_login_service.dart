import 'package:dart_ipify/dart_ipify.dart';
import 'package:harrier_central/imports.dart';
import 'package:geolocator/geolocator.dart';

class ApproveLoginService {
  Future<String> approveLogin(
    BuildContext context,
    String? facebookAccessToken,
  ) async {
    String? uid = getStringPref(StringPrefsEnum.userId);
    if ((uid ?? '').isEmpty) {
      uid = GUID_EMPTY;
    }

    String userId = uid!;

    final PackageInfo p = await PackageInfo.fromPlatform();

    final String version = p.version;
    final String buildNumber = p.buildNumber;

    //String deviceInfoDeviceId = 'unknown';
    String deviceType = 'unknown';
    String deviceName = 'unknown';
    String systemName = 'unknown';
    String systemVersion = 'unknown';
    String manufacturer = 'unknown';

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      //deviceInfoDeviceId = androidInfo.id.toUpperCase();
      deviceType = '${androidInfo.model} / device: ${androidInfo.device}';
      deviceName = '<unknown>';
      systemName = androidInfo.host;
      systemVersion =
          '${androidInfo.version.sdkInt.toString()} / release: ${androidInfo.version.release} / security patch: ${androidInfo.version.securityPatch ?? '<no Android security patch'}';
      manufacturer = androidInfo.brand;
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      // deviceInfoDeviceId =
      //     (iosInfo.identifierForVendor ?? '<no vendor id>').toUpperCase();
      deviceType = iosInfo.model;
      deviceName = iosInfo.name;
      systemName = iosInfo.systemName;
      systemVersion = iosInfo.systemVersion;
      manufacturer = 'Apple';
    }

    String responseBody;

    try {
      //TODO (James): Make this timeout gracefullly.
      final String ipv4 = await Ipify.ipv4();

      final String uri = 'https://ipinfo.io/$ipv4?token=1c7e5ada20ad08';

      final Response response = await get(Uri.parse(uri))
          .catchError((dynamic error) {
            if (kDebugMode) {
              print(error.toString());
            }
            return Response('<no ip information available>', 500);
          })
          .timeout(
            const Duration(milliseconds: 4000),
            onTimeout: () {
              return Response('<no ip information available>', 500);
            },
          );
      responseBody = response.body;
    } on Exception catch (_) {
      responseBody = '''{
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

    //final String userId = getStringPref(StringPrefsEnum.userId)!;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '<none>';

    final String accessToken = Utilities.generateToken(
      userId,
      'hcapp_approveLogin',
      paramString: deviceSecret,
    );

    Position? position;

    if (deviceId != '') {
      position = await getLastKnownLocation();
    }

    final String body = jsonEncode(<String, String?>{
      'queryType': 'approveLogin',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'deviceType': deviceType,
      'deviceName': deviceName,
      'systemName': systemName,
      'systemVersion': systemVersion,
      'manufacturer': manufacturer,
      'latitude':
          position?.latitude.toString() ??
          (G0<DeviceInfo>().deviceLat ?? DEFAULT_LATITUDE).toString(),
      'longitude':
          position?.longitude.toString() ??
          (G0<DeviceInfo>().deviceLon ?? DEFAULT_LONGITUDE).toString(),
      'hcVersion': version,
      'buildNumber': buildNumber,
      'fbToken': facebookAccessToken,
      'usesLocSvcs': (G0<AppModel>().hasLocationPermissions) ? '1' : '0',
      'screenWidth': (G0<DeviceInfo>().deviceWidth).toInt().toString(),
      'screenHeight': (G0<DeviceInfo>().deviceHeight).toInt().toString(),
      'ipInfo': responseBody,
    });

    Future<Response> futureResponse;

    futureResponse = post(
      Uri.parse(BASE_AF_API_URL),
      headers: <String, String>{'content-type': 'application/json'},
      body: body,
      // Send authorization headers to your backend
      //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
    ).catchError((dynamic error) {
      return Response('<http error>', 500);
    });

    //final Future<void> delay = Future<void>.delayed(const Duration(seconds: 25));

    // wait 7 seconds then issue the first warning
    Response resp = await futureResponse.timeout(
      const Duration(seconds: LOGIN_IS_DELAYED_WARNING_1),
      onTimeout: () {
        return Response('<timeout error>', 999);
      },
    );

    if (resp.statusCode == 999) {
      final bool keepWaiting = await _onLoginDelayed(
        navigatorKey.currentContext!,
        'Harrier Central is waiting for a response from the server. It appears as though the network is slow. Please stand by while we wait for a server response.',
      );

      if (!keepWaiting) {
        futureResponse.ignore();
        //delay.ignore();
        return '';
      }

      // wait 15 more seconds then issue another warning
      resp = await futureResponse.timeout(
        const Duration(seconds: LOGIN_IS_DELAYED_WARNING_2),
        onTimeout: () {
          return Response('<timeout error>', 999);
        },
      );

      if (resp.statusCode == 999) {
        final bool keepWaiting = await _onLoginDelayed(
          navigatorKey.currentContext!,
          'Harrier Central is still waiting for a response from the server. Let\'s give it just a bit more time.',
        );

        if (!keepWaiting) {
          futureResponse.ignore();
          //delay.ignore();
          return '';
        }

        if (resp.statusCode == 999) {
          // finally, if the response times out again, continue with offline mode
          resp = await futureResponse.timeout(
            const Duration(seconds: LOGIN_TIMEOUT),
            onTimeout: () => _onTimeout(navigatorKey.currentContext!),
          );
        }
      }
    }

    if (resp.statusCode == 999) {
      return '';
    }

    String returnValue = await ServiceCommon.checkHttpPostResponse(resp);

    return returnValue;
  }

  Future<Position?> getLastKnownLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // 2. Check permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // 3. Get current position (with desired accuracy)
    return await Geolocator.getLastKnownPosition(
      // desiredAccuracy: LocationAccuracy.high,
      // timeLimit: Duration(seconds: 5),
    );
  }

  Future<bool> _onLoginDelayed(BuildContext context, String message) async {
    final bool isWait =
        await Utilities.showAlert(
          'Slow Network',
          message,
          'Wait',
          showCancelButton: true,
          cancelButtonText: 'Continue offline',
        ) ??
        false;
    if (!isWait) {
      // return an empty response to indicate that the user wants to continue offline.
      return false;
    }
    return true;
  }

  Future<Response> _onTimeout(BuildContext context) async {
    await Utilities.showAlert(
      'Network Error',
      'Harrier Central was not able to contact the server. Please check your network connection.\r\n\r\nYou may continue using the app in Offline Mode with cached data. Press the \'Offline Mode\' ribbon to find out when the last time the data was updated.',
      'Use Offline',
    );
    return Response('<timeout error>', 999);
  }
}
