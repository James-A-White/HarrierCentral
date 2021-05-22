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

    final String hcVersion = await SecurePrefs.getStringPref(StringPrefsEnum.harrierCentralVersion);
    if ((hcVersion ?? '').isEmpty) {
      final PackageInfo p = await PackageInfo.fromPlatform();
      final String hcVersion = 'AppName: ${p.appName}, Version: ${p.version}, Build: ${p.buildNumber}';

      await SecurePrefs.setPref(StringPrefsEnum.harrierCentralVersion, hcVersion);
    }

    final String body = jsonEncode(<String, String>{
      'userId': GUID_EMPTY,
      'accessToken': accessToken,
      'hcVersion': await SecurePrefs.getStringPref(StringPrefsEnum.harrierCentralVersion),
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
          SecurePrefs.setPref(StringPrefsEnum.profilePhotoUrl, result[0]['photo']);
          SecurePrefs.setPref(StringPrefsEnum.displayName, result[0]['displayName']);
          SecurePrefs.setPref(StringPrefsEnum.email, result[0]['email']);
          SecurePrefs.setPref(StringPrefsEnum.facebookId, result[0]['facebookId']);
          SecurePrefs.setPref(StringPrefsEnum.firstName, result[0]['firstName']);
          SecurePrefs.setPref(StringPrefsEnum.hashName, result[0]['hashName']);
          SecurePrefs.setPref(StringPrefsEnum.lastName, result[0]['lastName']);
          SecurePrefs.setPref(StringPrefsEnum.qrCode, result[0]['qrCode']);
          SecurePrefs.setPref(StringPrefsEnum.supportCode, result[0]['supportCode']);
          SecurePrefs.setPref(StringPrefsEnum.resetCode, result[0]['resetCode']);
          SecurePrefs.setPref(StringPrefsEnum.qrSecretCode, result[0]['qrSecretCode']);
          SecurePrefs.setPref(StringPrefsEnum.userId, result[0]['hasherId']);

          resultMap = <String, String>{'result': 'success', 'message': 'Successfully loaded profile'};
        }
      }
    } catch (e) {
      resultMap = <String, String>{'result': 'failed', 'message': 'Error reading server data. Check your QR code'};
    }

    return resultMap;
  }
}
