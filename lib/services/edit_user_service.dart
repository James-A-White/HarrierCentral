import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/data_models/user_model.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/services/service_common.dart';
import 'package:harrier_central/util/constants.dart';

class EditUserService {
  Future<dynamic> editUser({
      BuildContext context,
      String targetUserId,
      String firstName,
      String lastName,
      String email,
      String hashName,
      String photo,}
  ) async {

    final String hcVersion = getStringPref(StringPrefsEnum.harrierCentralVersion);
    final String userId = getStringPref(StringPrefsEnum.userId);

    final String accessToken =
        Utilities.generateToken(userId.toUpperCase(), 'editUser',paramString: userId.toUpperCase());

    final String body = jsonEncode(<String, String>{
      'userId': userId,
      'accessToken': accessToken,
      'hcVersion' : hcVersion,
      'targetUserId' :targetUserId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'hashName': hashName,
      'photo': photo
    });

    final String responseBody =
        await ServiceCommon.sendRequest(context, 'edit_user', body);

    if (responseBody == ERROR_KEY) {
      return ERROR_KEY;
    } else {
      final List<UserModel> results = UserModel.listFromJson(responseBody);

      if (results.isEmpty) {
        return ERROR_KEY;
      }
      return results[0];
    }
  }
}
