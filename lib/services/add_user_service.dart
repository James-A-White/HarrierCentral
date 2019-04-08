import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/data_models/user_model.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/services/service_common.dart';
import 'package:harrier_central/util/constants.dart';

class AddUserService {
  Future<UserModel> addUser(
      BuildContext context,
      String firstName,
      String lastName,
      String email,
      String hashName,
      String facebookId,
      String gender,
      String photo,
      String memberKennelId,
      String eventId,
      EnumHasherType<int> hasherType,
      {EnumAttendenceState<int> attendenceState = attndenceUnknown}) async {
    final String accessToken = Utilities.generateToken(GUID_EMPTY, 'addUser');

    if ((eventId ?? '').isEmpty) {
      eventId = GUID_EMPTY;
    }

    final String hcVersion =
        getStringPref(StringPrefsEnum.harrierCentralVersion);

    final String body = jsonEncode(<String, String>{
      'userId': GUID_EMPTY,
      'accessToken': accessToken,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'hashHandle': hashName,
      'facebookId': facebookId,
      'gender': gender,
      'photo': photo,
      'memberKennelId': memberKennelId,
      'eventId': eventId,
      'hasherType': hasherType.value.toString(),
      'attendenceState': attendenceState.value.toString(),
      'hcVersion': hcVersion
    });

    final String responseBody =
        await ServiceCommon.sendRequest(context, 'add_user', body);

    if (responseBody == ERROR_KEY) {
      return Future<UserModel>(null);
    } else {
      final List<UserModel> results = UserModel.listFromJson(responseBody);

      if (results.isEmpty) {
        return Future<UserModel>(null);
      }

      return results[0];
    }
  }
}
