import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:device_info/device_info.dart';

import 'package:harrier_central/data_models/approve_login_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';

import 'package:http/http.dart' as http;

class ApproveLoginService {
  Future<ApproveLoginModel> approveLogin() async {
    String userId = Preferences.getStringPref(StringPrefsEnum.userId);
    if ((userId ?? '').isEmpty) {
      userId = '00000000-0000-0000-0000-000000000000';
    }

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceId = 'unknown';
    String deviceType = 'unknown';
    String deviceName = 'unknown';
    String systemName = 'unknown';
    String systemVersion = 'unknown';
    String manufacturer = 'unknown';

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceId =androidInfo.androidId.toUpperCase();
      deviceType = androidInfo.model;
      deviceName =androidInfo.hardware;
      systemName = androidInfo.host;
      systemVersion =androidInfo.version.toString();
      manufacturer =androidInfo.manufacturer;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceId =iosInfo.identifierForVendor.toUpperCase();
      deviceType = iosInfo.model;
      deviceName =iosInfo.name;
      systemName = iosInfo.systemName;
      systemVersion =iosInfo.systemVersion;
      manufacturer = 'Apple';
    }

      final String accessToken = Utilities.generateToken(userId, 'approveLogin', paramString: deviceId);

    final LatLon latLon = await Utilities.getLatLong();

    final String body = jsonEncode(<String,String>{
      'userId': userId,
      'accessToken': accessToken,
      'deviceId': deviceId,
      'deviceType': deviceType,
      'deviceName': deviceName,
      'systemName': systemName,
      'systemVersion': systemVersion,
      'manufacturer': manufacturer,
      'latitude':latLon.latitude.toString(),
      'longitude':latLon.longitude.toString()
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'approve_login',
            headers: <String,String> {'content-type': 'application/json'}, body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return false;
      },
    );

  ApproveLoginModel loginResult = ApproveLoginModel.itemFromJson(response.body);


    return null;
  }
}
