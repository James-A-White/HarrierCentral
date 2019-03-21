import 'dart:async';
import 'dart:convert';

import 'package:harrier_central/data_models/user_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';

import 'package:http/http.dart' as http;

class GetPackService {

  Future<List<UserModel>> getPack(String eventId) async {

    final String userId = getStringPref(StringPrefsEnum.userId);

    final String accessToken = Utilities.generateToken(
        userId, 'getUsersByEvent');

    final String body = jsonEncode(<String,String>{
      'userId': userId,
      'accessToken': accessToken,
      'eventId': eventId
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'get_users_by_event',
            headers: <String,String> {'content-type': 'application/json'}, body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return false;
      },
    );

    final List<UserModel> packList =  <UserModel>[];

    UserModel packMember;
    json.decode(response.body).forEach(
      (dynamic pack) {
        packMember = UserModel(
          hasherId: pack['hasherId'],
          hasherEventMapId: pack['hasherEventMapId'],
          rsvpState: pack['rsvpState'],
          attendenceState: pack['attendenceState'],
          displayName: pack['displayName'],
          photo: pack['photo'],
          isHare: pack['isHare']
        );

        packList.add(packMember);
      },
    );

    return packList;
  }


}
