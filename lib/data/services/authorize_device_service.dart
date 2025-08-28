import 'package:harrier_central/imports.dart';

class AuthorizeDeviceService {
  Future<Map<String, String>> authorizeDevice({
    String? scanText,
    String? userId,
  }) async {
    String deviceDataJson = '{"error":"device data error"}';

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceDataJson = jsonEncode(androidInfo.data);
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceDataJson = jsonEncode(iosInfo.data);
    }

    final String accessToken = Utilities.generateToken(
      GUID_EMPTY,
      'hcapp_authorizeDevice',
      timeWindow:
          30, // since the device secret and time window have not yet been created, default to 30 for the time window and don't pass a device secret
    );

    final String hcVersion =
        getStringPref(StringPrefsEnum.harrierCentralVersionAndBuild) ??
        '<no HC version>';

    if (hcVersion.isEmpty) {
      final PackageInfo p = await PackageInfo.fromPlatform();
      final String hcVersion =
          'AppName: ${p.appName}, Version: ${p.version}, Build: ${p.buildNumber}';

      await setStringPref(
        StringPrefsEnum.harrierCentralVersionAndBuild,
        hcVersion,
      );
    }

    var deviceIdUuid = Uuid();
    String deviceId = deviceIdUuid.v4(); // Generate a random GUID

    Map<String, String> params = (<String, String>{
      'queryType': 'authorizeDevice',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'hcVersion':
          getStringPref(StringPrefsEnum.harrierCentralVersionAndBuild) ??
          '<no HC version>',
      'deviceData': deviceDataJson,
    });

    if (scanText != null) {
      params['scanText'] = scanText;
    }

    if (userId != null) {
      params['userId'] = userId;
    }

    if (Firebase.apps.isNotEmpty) {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      // Ensure APNs token is set
      String? apnsToken = await messaging.getAPNSToken();
      String? fcmToken = await messaging.getToken();

      if (apnsToken != null) {
        params.addAll({'apnsToken': apnsToken});
      }

      if (fcmToken != null) {
        params.addAll({'fcmToken': fcmToken});
      }
    }

    final String body = jsonEncode(params);

    Map<String, String> resultMap = <String, String>{};

    try {
      final String responseBody = await ServiceCommon.sendHttpPostV2(body);

      if (!responseBody.startsWith(ERROR_PREFIX)) {
        final List<dynamic> result = json.decode(responseBody);

        if ((result.isEmpty) || (result[0].isEmpty) || (result[0][0].isEmpty)) {
          resultMap = <String, String>{
            'result': 'failed',
            'message': 'Could not download profile. Check your QR code',
          };
        } else {
          Map<String, dynamic> items = result[0][0];
          // Do not clear prefs, because then we clear the prefs that were set by authorize login upon app launch
          //await clearAllPrefs();
          await setStringPref(StringPrefsEnum.deviceId, deviceId);
          await setStringPref(
            StringPrefsEnum.deviceSecret,
            items['iconDataBase64'],
          ); // a bit of security through obscurity here
          await setIntPref(
            IntPrefsEnum.timeWindow,
            items['colorPaletteIndex'],
          ); // a bit of security through obscurity here
          await setStringPref(StringPrefsEnum.profilePhotoUrl, items['photo']);
          await setStringPref(
            StringPrefsEnum.displayName,
            items['displayName'],
          );
          await setStringPref(StringPrefsEnum.email, items['email']);
          //await setStringPref(StringPrefsEnum.facebookId, items['facebookId']);
          await setStringPref(StringPrefsEnum.firstName, items['firstName']);
          await setStringPref(StringPrefsEnum.hashName, items['hashName']);
          await setStringPref(StringPrefsEnum.lastName, items['lastName']);
          await setStringPref(StringPrefsEnum.qrCode, items['qrCode']);
          await setStringPref(
            StringPrefsEnum.supportCode,
            items['supportCode'],
          );
          await setStringPref(StringPrefsEnum.resetCode, items['resetCode']);
          await setStringPref(
            StringPrefsEnum.qrSecretCode,
            items['qrSecretCode'],
          );
          await setStringPref(StringPrefsEnum.userId, items['hasherId']);
          await setStringPref(
            StringPrefsEnum.publicHasherId,
            items['publicHasherId'],
          );
          await setStringPref(
            StringPrefsEnum.homeKennelId,
            items['homeKennelId']?.toLowerCase(),
          );
          await setIntPref(IntPrefsEnum.isBetaTester, items['isBetaTester']);
          final int preferences = items['preferences'] ?? 0;
          await setIntPref(IntPrefsEnum.hasherPreferences, preferences);

          await setStringPref(
            StringPrefsEnum.thirdPartyAccessToken,
            items['thirdPartyAccessToken'],
          );
          await setStringPref(
            StringPrefsEnum.thirdPartyAuthorizationCode,
            items['thirdPartyAuthorizationCode'],
          );
          await setStringPref(
            StringPrefsEnum.thirdPartyEmail,
            items['thirdPartyEmail'],
          );
          await setStringPref(
            StringPrefsEnum.thirdPartyLoginEmail,
            items['thirdPartyEmail'],
          );
          await setStringPref(
            StringPrefsEnum.thirdPartyForceTokenRefresh,
            items['thirdPartyForceTokenRefresh'],
          );
          await setStringPref(
            StringPrefsEnum.thirdPartyLoginType,
            items['thirdPartyLoginType'],
          );
          await setStringPref(
            StringPrefsEnum.thirdPartyUserId,
            items['thirdPartyUserId'],
          );

          resultMap = <String, String>{
            'result': 'success',
            'message': 'Successfully loaded profile',
          };
        }
      } else {
        return <String, String>{
          'result': 'failed',
          'message': 'Error calling authorize device',
        };
      }
    } catch (e) {
      resultMap = <String, String>{
        'result': 'failed',
        'message': 'Error reading server data. Check your QR code',
      };
    }

    return resultMap;
  }
}
