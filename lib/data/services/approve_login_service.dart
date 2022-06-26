// @dart=2.11
import 'package:harrier_central/imports.dart';

class ApproveLoginService {
  Future<ApproveLoginModel> approveLogin(BuildContext context, String facebookAccessToken) async {
    String userId = getStringPref(StringPrefsEnum.userId);
    if ((userId ?? '').isEmpty) {
      userId = GUID_EMPTY;
    }

    final String hcVersion = getStringPref(StringPrefsEnum.harrierCentralVersion);

    String deviceId = 'unknown';
    String deviceType = 'unknown';
    String deviceName = 'unknown';
    String systemName = 'unknown';
    String systemVersion = 'unknown';
    String manufacturer = 'unknown';

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceId = (androidInfo.androidId ?? '<no Android ID>').toUpperCase();
      deviceType = '${androidInfo.model ?? '<no Android model>'} / device: ${androidInfo.device ?? '<no Android device'}';
      deviceName = '<unknown>';
      systemName = androidInfo.host ?? '<no Android system name>';
      systemVersion =
          '${androidInfo.version.sdkInt.toString()} / release: ${androidInfo.version.release ?? '<no Android release>'} / security patch: ${androidInfo.version.securityPatch ?? '<no Android security patch'}';
      manufacturer = androidInfo.brand ?? '<no Android brand>';
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor.toUpperCase();
      deviceType = iosInfo.model;
      deviceName = iosInfo.name;
      systemName = iosInfo.systemName;
      systemVersion = iosInfo.systemVersion;
      manufacturer = 'Apple';
    }

    final String accessToken = IveCoreUtilities.generateToken(userId, 'approveLogin', paramString: deviceId);

    final String body = jsonEncode(<String, String>{
      'userId': userId,
      'accessToken': accessToken,
      'deviceId': deviceId,
      'deviceType': deviceType,
      'deviceName': deviceName,
      'systemName': systemName,
      'systemVersion': systemVersion,
      'manufacturer': manufacturer,
      'latitude': (G0<DeviceInfo>().deviceLat ?? DEFAULT_LATITUDE).toString(),
      'longitude': (G0<DeviceInfo>().deviceLon ?? DEFAULT_LONGITUDE).toString(),
      'hcVersion': hcVersion,
      'fbToken': facebookAccessToken,
    });

    Future<Response> futureResponse;

    futureResponse = post(Uri.parse(BASE_API_URL + 'hc3_approve_login'), headers: <String, String>{'content-type': 'application/json'}, body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        // TODO(James): Handle socketException
        futureResponse = null;
      },
    );

    if (futureResponse == null) {
      return null;
    }

    //final Future<void> delay = Future<void>.delayed(const Duration(seconds: 25));

    // wait 7 seconds then issue the first warning
    Response resp = await futureResponse.timeout(const Duration(seconds: LOGIN_IS_DELAYED_WARNING_1), onTimeout: () {
      return null;
    });

    if (resp == null) {
      final bool keepWaiting = await _onLoginDelayed(
        context,
        'Harrier Central is waiting for a response from the server. It appears as though the network is slow. Please stand by while we wait for a server response.',
      );

      if (!keepWaiting) {
        futureResponse.ignore();
        //delay.ignore();
        return null;
      }
    }

    // wait 15 more seconds then issue another warning
    resp ??= await futureResponse.timeout(const Duration(seconds: LOGIN_IS_DELAYED_WARNING_2), onTimeout: () {
      return null;
    });

    if (resp == null) {
      final bool keepWaiting = await _onLoginDelayed(
        context,
        'Harrier Central is still waiting for a response from the server. Let\'s give it just a bit more time.',
      );

      if (!keepWaiting) {
        futureResponse.ignore();
        //delay.ignore();
        return null;
      }
    }

    // finally, if the response times out again, continue with offline mode
    resp ??= await futureResponse.timeout(const Duration(seconds: LOGIN_TIMEOUT), onTimeout: () => _onTimeout(context));

    if ((resp == null) || (resp.body == null) || (resp.body.length < 10) || ((resp.statusCode < 200) && (resp.statusCode >= 300))) {
      return null;
    }

    final ApproveLoginModel loginResult = ApproveLoginModel.itemFromJson(resp.body);

    return loginResult;
    //return null;
  }

  Future<bool> _onLoginDelayed(BuildContext context, String message) async {
    final bool isWait = await IveCoreUtilities.showAlert(
      context,
      'Slow Network',
      message,
      'Wait',
      showCancelButton: true,
      cancelButtonText: 'Continue offline',
    );
    if (!isWait) {
      // return an empty response to indicate that the user wants to continue offline.
      return false;
    }
    return true;
  }

  Future<Response> _onTimeout(BuildContext context) async {
    await IveCoreUtilities.showAlert(
        context,
        'Network Error',
        'Harrier Central was not able to contact the server. Please check your network connection.\r\n\r\nYou may continue using the app in Offline Mode with cached data. Press the \'Offline Mode\' ribbon to find out when the last time the data was updated.',
        'Use Offline');
    return null;
  }
}
