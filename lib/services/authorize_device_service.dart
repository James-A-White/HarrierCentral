import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:harrier_central/data_models/user_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';

import 'package:device_info/device_info.dart';
import 'package:http/http.dart' as http;

class AuthorizeDeviceService {
  Future<Map<String, String>> authorizeDevice(String scanText) async {
    String deviceId = 'unknown';

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.androidId.toUpperCase();
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor.toUpperCase();
    }

    final String accessToken = Utilities.generateToken(
        GUID_EMPTY, 'authorizeDevice');

    final String body = jsonEncode(<String, String>{
      'userId': GUID_EMPTY,
      'accessToken': accessToken,
      'scanText': scanText,
      'deviceId': deviceId
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'authorize_device',
            headers: <String, String>{'content-type': 'application/json'},
            body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return false;
      },
    );

    Map<String, String> resultMap = <String, String>{};
    try {
      final List<UserModel> results = UserModel.listFromJson(response.body);

      if (results.isEmpty) {
        resultMap = <String, String>{
          'result': 'failed',
          'message': 'Could not download profile. Check your QR code'
        };
      } else {
        setStringPref(StringPrefsEnum.profilePhotoUrl, results[0].photo);
        setStringPref(
            StringPrefsEnum.displayName, results[0].displayName);
        setStringPref(StringPrefsEnum.email, results[0].email);
        setStringPref(
            StringPrefsEnum.facebookId, results[0].facebookId);
        setStringPref(
            StringPrefsEnum.firstName, results[0].firstName);
        setStringPref(
            StringPrefsEnum.hashName, results[0].hashName);
        setStringPref(
            StringPrefsEnum.lastName, results[0].lastName);
        setStringPref(StringPrefsEnum.qrCode, results[0].qrCode);
        setStringPref(
            StringPrefsEnum.qrSecretCode, results[0].qrSecretCode);
        setStringPref(StringPrefsEnum.userId, results[0].hasherId);

        resultMap = <String, String>{
          'result': 'success',
          'message': 'Successfully loaded profile'
        };
      }
    } catch (e) {
      resultMap = <String, String>{
        'result': 'failed',
        'message': 'Error reading server data. Check your QR code'
      };
    }

    return resultMap;
  }
}
