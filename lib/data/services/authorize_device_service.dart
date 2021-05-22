import 'package:harrier_central/imports.dart';

class AuthorizeDeviceService {
  Future<Map<String, String>> authorizeDevice(BuildContext context, String scanText, {num includeInGlobalHashDirectory = -1}) async {
    String deviceId = 'unknown';

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.androidId.toUpperCase();
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor.toUpperCase();
    }

    final String accessToken = IveCoreUtilities.generateToken(GUID_EMPTY, 'authorizeDevice');

    final String hcVersion = getStringPref(StringPrefsEnum.harrierCentralVersion);
    if ((hcVersion ?? '').isEmpty) {
      final PackageInfo p = await PackageInfo.fromPlatform();
      final String hcVersion = 'AppName: ${p.appName}, Version: ${p.version}, Build: ${p.buildNumber}';

      await setStringPref(StringPrefsEnum.harrierCentralVersion, hcVersion);
    }

    final String body = jsonEncode(<String, String>{
      'userId': GUID_EMPTY,
      'accessToken': accessToken,
      'hcVersion': getStringPref(StringPrefsEnum.harrierCentralVersion),
      'scanText': scanText,
      'deviceId': deviceId,
      'includeInGlobalHashDirectory': includeInGlobalHashDirectory.toString()
    });

    Map<String, String> resultMap = <String, String>{};

    try {
      final String responseBody = await ServiceCommon.sendRequest(context, 'hc3_authorize_device', body);
      if (responseBody == ERROR_KEY) {
        return <String, String>{'result': 'failed', 'message': 'Error calling authorize device'};
      } else {
        final List<dynamic> result = json.decode(responseBody);

        if ((result == null) || (result.isEmpty) || (result[0].isEmpty)) {
          resultMap = <String, String>{'result': 'failed', 'message': 'Could not download profile. Check your QR code'};
        } else {
          // Do not clear prefs, because then we clear the prefs that were set by authorize login upon app launch
          //await clearAllPrefs();
          setStringPref(StringPrefsEnum.profilePhotoUrl, result[0]['photo']);
          setStringPref(StringPrefsEnum.displayName, result[0]['displayName']);
          setStringPref(StringPrefsEnum.email, result[0]['email']);
          setStringPref(StringPrefsEnum.facebookId, result[0]['facebookId']);
          setStringPref(StringPrefsEnum.firstName, result[0]['firstName']);
          setStringPref(StringPrefsEnum.hashName, result[0]['hashName']);
          setStringPref(StringPrefsEnum.lastName, result[0]['lastName']);
          setStringPref(StringPrefsEnum.qrCode, result[0]['qrCode']);
          setStringPref(StringPrefsEnum.supportCode, result[0]['supportCode']);
          setStringPref(StringPrefsEnum.resetCode, result[0]['resetCode']);
          setStringPref(StringPrefsEnum.qrSecretCode, result[0]['qrSecretCode']);
          setStringPref(StringPrefsEnum.userId, result[0]['hasherId']);

          resultMap = <String, String>{'result': 'success', 'message': 'Successfully loaded profile'};
        }
      }
    } catch (e) {
      resultMap = <String, String>{'result': 'failed', 'message': 'Error reading server data. Check your QR code'};
    }

    return resultMap;
  }
}
