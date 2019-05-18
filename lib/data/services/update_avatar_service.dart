import 'dart:async';
import 'dart:convert';

import 'package:harrier_central/data/models/single_result_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/globals.dart';

import 'package:http/http.dart' as http;

class UpdateProfilePhotoService {
  Future<SingleResultModel> updateProfilePhoto(
      String avatarUrl, String profilePhotoUserId) async {

    
    if (globalConnectionStatus == connectionStatus_notConnected)
    {
      return null;
      // TODO(James): fix this so we can return a bool
      //return false;
    }



    final String userId = getStringPref(StringPrefsEnum.userId);

    final String accessToken = Utilities.generateToken(userId, 'updateAvatar');

    final String body = jsonEncode(<String, String>{
      'userId': userId,
      'accessToken': accessToken,
      'avatarUrl': avatarUrl,
      'avatarUserId': profilePhotoUserId
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'update_avatar',
            headers: <String, String>{'content-type': 'application/json'},
            body: body)
        .catchError(
      (dynamic error) {
        return false;
      },
    );

    SingleResultModel result;

    json.decode(response.body).forEach(
      (dynamic item) {
        result = SingleResultModel(result: item['result']);
      },
    );

    return result;
  }
}
