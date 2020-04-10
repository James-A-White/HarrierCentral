import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:device_info/device_info.dart';

import 'package:harrier_central/data/models/approve_login_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:ive_flutter_core/util/core_utilities.dart';

import 'package:http/http.dart' as http;

class ApproveLoginService {
  Future<ApproveLoginModel> approveLogin(BuildContext context) async {
    String userId = getStringPref(StringPrefsEnum.userId);
    if ((userId ?? '').isEmpty) {
      userId = GUID_EMPTY;
    }

    final String hcVersion =
        getStringPref(StringPrefsEnum.harrierCentralVersion);

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
      systemVersion =
          '${androidInfo.version.sdkInt.toString()} / release: ${androidInfo.version.release} / security patch: ${androidInfo.version.securityPatch}';
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

    final String accessToken =
        CoreUtilities.generateToken(userId, 'approveLogin', paramString: deviceId);

    final String body = jsonEncode(<String, String>{
      'userId': userId,
      'accessToken': accessToken,
      'deviceId': deviceId,
      'deviceType': deviceType,
      'deviceName': deviceName,
      'systemName': systemName,
      'systemVersion': systemVersion,
      'manufacturer': manufacturer,
      'latitude': (deviceLat ?? DEFAULT_LATITUDE).toString(),
      'longitude': (deviceLon ?? DEFAULT_LONGITUDE).toString(),
      'hcVersion': hcVersion,
    });
    
    Future<http.Response> response;

    response = http
        .post(BASE_API_URL + 'hc3_approve_login',
            headers: <String, String>{'content-type': 'application/json'},
            body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        // TODO(James): Handle socketException
        response = null;
      },
    );

    if (response == null)
    {
        return null;
    }

    // if the response times out, show an error
    response.timeout(const Duration(seconds: LOGIN_TIMEOUT), onTimeout: () => _onTimeout(context));

    final http.Response resp = await response;

    if (resp == null)
    {
      return null;
    }

    final ApproveLoginModel loginResult =
        ApproveLoginModel.itemFromJson(resp.body);

    return loginResult;
  }

  Future<http.Response> _onTimeout(BuildContext context) {
    CoreUtilities.showAlert(context, 'Network Error', 'Harrier Central was not able to contact the server. Please try again later.\r\n\r\nPlease check your network connection.', 'Quit').then((void dummy) async {
        await SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
    });
    
    return null;
  }
}
