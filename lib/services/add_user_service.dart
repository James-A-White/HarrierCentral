import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/data_models/user_model.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/services/service_common.dart';

class AddUserService {
  Future<UserModel> addUser(
      GlobalKey<ScaffoldState> scaffoldKey,
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
    final String accessToken = Utilities.generateToken(
        '00000000-0000-0000-0000-000000000000', 'addUser');

    if ((eventId ?? '').isEmpty) {
      eventId = '00000000-0000-0000-0000-000000000000';
    }

    final String body = jsonEncode(<String, String>{
      'userId': '00000000-0000-0000-0000-000000000000',
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
      'attendenceState': attendenceState.value.toString()
    });

    final String responseBody = await ServiceCommon.sendRequest(scaffoldKey, body);

    final List<UserModel> results = UserModel.listFromJson(responseBody);

    if (results.isEmpty) {
      return null;
    }

    return results[0];
  }
}
