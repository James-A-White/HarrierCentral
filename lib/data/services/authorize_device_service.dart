import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/data/services/service_common.dart';

import 'package:device_info/device_info.dart';

class AuthorizeDeviceService {
  Future<Map<String, String>> authorizeDevice(
      BuildContext context, String scanText) async {
    String deviceId = 'unknown';

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.androidId.toUpperCase();
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor.toUpperCase();
    }

    final String accessToken =
        Utilities.generateToken(GUID_EMPTY, 'authorizeDevice');

    final String body = jsonEncode(<String, String>{
      'userId': GUID_EMPTY,
      'accessToken': accessToken,
      'scanText': scanText,
      'deviceId': deviceId
    });

    Map<String, String> resultMap = <String, String>{};

    try {
      final String responseBody =
          await ServiceCommon.sendRequest(context, 'hc3_authorize_device', body);
      if (responseBody == ERROR_KEY) {
         return <String, String>{
            'result': 'failed',
            'message': 'Error calling authorize device'
          };
      } else {
        final List<dynamic> result = json.decode(responseBody);

        if ((result == null) || (result.isEmpty) || (result[0].isEmpty)) {
          resultMap = <String, String>{
            'result': 'failed',
            'message': 'Could not download profile. Check your QR code'
          };
        } else {
          await clearAllPrefs();
          setStringPref(StringPrefsEnum.profilePhotoUrl, result[0]['photo']);
          setStringPref(StringPrefsEnum.displayName, result[0]['displayName']);
          setStringPref(StringPrefsEnum.email, result[0]['email']);
          setStringPref(StringPrefsEnum.facebookId, result[0]['facebookId']);
          setStringPref(StringPrefsEnum.firstName, result[0]['firstName']);
          setStringPref(StringPrefsEnum.hashName, result[0]['hashName']);
          setStringPref(StringPrefsEnum.lastName, result[0]['lastName']);
          setStringPref(StringPrefsEnum.qrCode, result[0]['qrCode']);
          setStringPref(StringPrefsEnum.supportCode, result[0]['supportCode']);
          setStringPref(StringPrefsEnum.qrSecretCode, result[0]['qrSecretCode']);
          setStringPref(StringPrefsEnum.userId, result[0]['hasherId']);

          resultMap = <String, String>{
            'result': 'success',
            'message': 'Successfully loaded profile'
          };
        }
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
