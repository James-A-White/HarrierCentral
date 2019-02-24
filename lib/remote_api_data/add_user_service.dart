
import 'dart:async';
import 'dart:convert';

import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/data_models/user_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/utilities.dart';

import 'package:http/http.dart' as http;

class AddUserService {

  Future<UserModel> addUser(String firstName, String lastName, String email,
      String hashName, String facebookId, String gender, String photo, String memberKennelId, String eventId, EnumHasherType<int> hasherType, {EnumAttendenceState<int> attendenceState = attndenceUnknown}) async {

    final String accessToken = Utilities.generateToken(
        '00000000-0000-0000-0000-000000000000', 'addUser');

    if ((eventId ?? '').isEmpty)
    {
      eventId = '00000000-0000-0000-0000-000000000000';
    }

    final String body = jsonEncode(<String,String>{
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
      'eventId' : eventId,
      'hasherType' : hasherType.value.toString(),
      'attendenceState' : attendenceState.value.toString()
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'add_user',
            headers: <String,String> {'content-type': 'application/json'}, body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return false;
      },
    );

    UserModel thisUser;

    json.decode(response.body).forEach(
      (dynamic user) {
        thisUser = UserModel(
          hasherId: user['userId'],
          qrCode: user['qr_code'],
          qrSecretCode: user['qr_secret_code'],
          displayName: user['displayName'],
          firstName: user['firstName'],
          lastName: user['lastName'],
          email: user['email'],
          //hasherKennelMapId: user['hasherKennelMapId'],
          hasherEventMapId: user['hasherEventMapId'],
          //memberCount: user['memberCount'],
        );
      },
    );

    return thisUser;
  }
}
