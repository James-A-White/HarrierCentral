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
      deviceId = androidInfo.androidId.toUpperCase();
      deviceType = '${androidInfo.model} / device: ${androidInfo.device}';
      deviceName = '<unknown>';
      systemName = androidInfo.host;
      systemVersion = '${androidInfo.version.sdkInt.toString()} / release: ${androidInfo.version.release} / security patch: ${androidInfo.version.securityPatch}';
      manufacturer = androidInfo.brand;
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

    Future<Response> response;

    response = post(Uri.parse(BASE_API_URL + 'hc3_approve_login'), headers: <String, String>{'content-type': 'application/json'}, body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        // TODO(James): Handle socketException
        response = null;
      },
    );

    if (response == null) {
      return null;
    }

    // if the response times out, show an error
    response.timeout(const Duration(seconds: LOGIN_TIMEOUT), onTimeout: () => _onTimeout(context));

    final Response resp = await response;

    if (resp == null) {
      return null;
    }

    final ApproveLoginModel loginResult = ApproveLoginModel.itemFromJson(resp.body);

    return loginResult;
  }

  Future<Response> _onTimeout(BuildContext context) {
    IveCoreUtilities.showAlert(
            context, 'Network Error', 'Harrier Central was not able to contact the server. Please try again later.\r\n\r\nPlease check your network connection.', 'Quit')
        .then((void dummy) async {
      await SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
    });

    return null;
  }
}
