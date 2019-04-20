import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import 'package:harrier_central/data/models/user_model.dart';
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
          await ServiceCommon.sendRequest(context, 'authorize_device', body);
      if (responseBody == ERROR_KEY) {
         return <String, String>{
            'result': 'failed',
            'message': 'Error calling authorize device'
          };
      } else {
        final List<UserModel> results = UserModel.listFromJson(responseBody);

        if (results.isEmpty) {
          resultMap = <String, String>{
            'result': 'failed',
            'message': 'Could not download profile. Check your QR code'
          };
        } else {
          await clearAllPrefs();
          setStringPref(StringPrefsEnum.profilePhotoUrl, results[0].photo);
          setStringPref(StringPrefsEnum.displayName, results[0].displayName);
          setStringPref(StringPrefsEnum.email, results[0].email);
          setStringPref(StringPrefsEnum.facebookId, results[0].facebookId);
          setStringPref(StringPrefsEnum.firstName, results[0].firstName);
          setStringPref(StringPrefsEnum.hashName, results[0].hashName);
          setStringPref(StringPrefsEnum.lastName, results[0].lastName);
          setStringPref(StringPrefsEnum.qrCode, results[0].qrCode);
          setStringPref(StringPrefsEnum.supportCode, results[0].supportCode);
          setStringPref(StringPrefsEnum.qrSecretCode, results[0].qrSecretCode);
          setStringPref(StringPrefsEnum.userId, results[0].hasherId);

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
