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

    final deviceIdUuid = Uuid();
    final String deviceId = deviceIdUuid.v4();

    Map<String, String> params = (<String, String>{
      'queryType': 'authorizeDevice',
      'deviceId': deviceId,
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

      if (apnsToken != null) {
        apnsToken = apnsToken.trim();
        params.addAll({'apnsToken': apnsToken});
        String? fcmToken = await messaging.getToken();

        if (fcmToken != null) {
          params.addAll({'fcmToken': fcmToken});
        }
      }
    }

    Map<String, String> resultMap = <String, String>{};

    try {
      final String responseBody = await ServiceCommon.sendHttpPost(() {
        // timeWindow: 30 — device secret not yet known at authorizeDevice time
        params['accessToken'] = Utilities.generateToken(
          GUID_EMPTY,
          'hcapp_authorizeDevice',
          timeWindow: 30,
        );
        return jsonEncode(params);
      });

      if (!responseBody.startsWith(ERROR_PREFIX)) {
        final List<dynamic> result = json.decode(responseBody);

        if ((result.isEmpty) || (result[0].isEmpty) || (result[0][0].isEmpty)) {
          resultMap = <String, String>{
            'result': 'failed',
            'message': 'Could not download profile. Check your QR code',
          };
        } else {
          // HC6: rowset 0 is the write SP success envelope; profile data is at rowset 1.
          if (result.length < 2 || result[1] is! List || (result[1] as List).isEmpty) {
            resultMap = <String, String>{
              'result': 'failed',
              'message': 'Server returned an unexpected response',
            };
            return resultMap;
          }
          Map<String, dynamic> items = result[1][0];
          // Do not clear prefs, because then we clear the prefs that were set by authorize login upon app launch
          //await clearAllPrefs();
          await setStringPref(StringPrefsEnum.deviceId, deviceId);
          await setStringPref(
            StringPrefsEnum.deviceSecret,
            items['deviceSecret'],
          );
          await setIntPref(IntPrefsEnum.timeWindow, items['timeWindow']);
          await setStringPref(StringPrefsEnum.profilePhotoUrl, items['photo']);
          await setStringPref(
            StringPrefsEnum.displayName,
            items['displayName'],
          );
          await setStringPref(StringPrefsEnum.email, items['email']);

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
          //await setIntPref(IntPrefsEnum.isBetaTester, items['isBetaTester']);
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
            StringPrefsEnum.betaFeaturesEnabled,
            items['betaFeaturesEnabled'],
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
