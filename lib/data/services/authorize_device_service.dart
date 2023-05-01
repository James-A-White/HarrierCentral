import 'package:harrier_central/imports.dart';

class AuthorizeDeviceService {
  Future<Map<String, String>> authorizeDevice(BuildContext context, String scanText, {num includeInGlobalHashDirectory = -1}) async {
    String deviceId = 'unknown';

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceId = (androidInfo.id).toUpperCase();
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? '<no vendor ID>'.toUpperCase();
    }

    final String accessToken = IveCoreUtilities.generateToken(GUID_EMPTY, 'authorizeDevice');

    final String hcVersion = getStringPref(StringPrefsEnum.harrierCentralVersion) ?? '<no HC version>';
    if (hcVersion.isEmpty) {
      final PackageInfo p = await PackageInfo.fromPlatform();
      final String hcVersion = 'AppName: ${p.appName}, Version: ${p.version}, Build: ${p.buildNumber}';

      await setStringPref(StringPrefsEnum.harrierCentralVersion, hcVersion);
    }

    final String body = jsonEncode(<String, String>{
      'userId': GUID_EMPTY,
      'accessToken': accessToken,
      'hcVersion': getStringPref(StringPrefsEnum.harrierCentralVersion) ?? '<no HC version>',
      'scanText': scanText,
      'deviceId': deviceId,
      'includeInGlobalHashDirectory': includeInGlobalHashDirectory.toString(),
      'isLoggingOutOfFacebook': (getIntPref(IntPrefsEnum.isLoggingOutOfFacebook) ?? 0).toString(),
    });

    Map<String, String> resultMap = <String, String>{};

    try {
      final String responseBody = await ServiceCommon.sendHttpPost('hc3_authorize_device', body);

      if (!responseBody.startsWith(ERROR_PREFIX)) {
        final List<dynamic> result = json.decode(responseBody);

        if ((result.isEmpty) || (result[0].isEmpty)) {
          resultMap = <String, String>{'result': 'failed', 'message': 'Could not download profile. Check your QR code'};
        } else {
          // Do not clear prefs, because then we clear the prefs that were set by authorize login upon app launch
          //await clearAllPrefs();
          await setStringPref(StringPrefsEnum.profilePhotoUrl, result[0]['photo']);
          await setStringPref(StringPrefsEnum.displayName, result[0]['displayName']);
          await setStringPref(StringPrefsEnum.email, result[0]['email']);
          //await setStringPref(StringPrefsEnum.facebookId, result[0]['facebookId']);
          await setStringPref(StringPrefsEnum.firstName, result[0]['firstName']);
          await setStringPref(StringPrefsEnum.hashName, result[0]['hashName']);
          await setStringPref(StringPrefsEnum.lastName, result[0]['lastName']);
          await setStringPref(StringPrefsEnum.qrCode, result[0]['qrCode']);
          await setStringPref(StringPrefsEnum.supportCode, result[0]['supportCode']);
          await setStringPref(StringPrefsEnum.resetCode, result[0]['resetCode']);
          await setStringPref(StringPrefsEnum.qrSecretCode, result[0]['qrSecretCode']);
          await setStringPref(StringPrefsEnum.userId, result[0]['hasherId']);
          await setStringPref(StringPrefsEnum.homeKennelId, result[0]['homeKennelId']);
          await setIntPref(IntPrefsEnum.isBetaTester, result[0]['isBetaTester']);
          final int preferences = result[0]['preferences'] ?? 0;
          await setIntPref(IntPrefsEnum.hasherPreferences, preferences);

          await setStringPref(StringPrefsEnum.thirdPartyAccessToken, result[0]['thirdPartyAccessToken']);
          await setStringPref(StringPrefsEnum.thirdPartyAuthorizationCode, result[0]['thirdPartyAuthorizationCode']);
          await setStringPref(StringPrefsEnum.thirdPartyEmail, result[0]['thirdPartyEmail']);
          await setStringPref(StringPrefsEnum.thirdPartyLoginEmail, result[0]['thirdPartyEmail']);
          await setStringPref(StringPrefsEnum.thirdPartyForceTokenRefresh, result[0]['thirdPartyForceTokenRefresh']);
          await setStringPref(StringPrefsEnum.thirdPartyLoginType, result[0]['thirdPartyLoginType']);
          await setStringPref(StringPrefsEnum.thirdPartyUserId, result[0]['thirdPartyUserId']);

          resultMap = <String, String>{'result': 'success', 'message': 'Successfully loaded profile'};
        }
      } else {
        return <String, String>{'result': 'failed', 'message': 'Error calling authorize device'};
      }
    } catch (e) {
      resultMap = <String, String>{'result': 'failed', 'message': 'Error reading server data. Check your QR code'};
    }

    return resultMap;
  }
}
