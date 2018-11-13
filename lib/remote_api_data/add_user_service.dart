import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:harrier_central/util/utilities.dart';

import 'package:harrier_central/data_models/add_user_model.dart';
import 'package:harrier_central/util/constants.dart';
//import 'package:harrier_central/util/constants.dart';

//import 'package:geolocator/geolocator.dart';

class AddUserService {

  Future<AddUserModel> addUser(String firstName, String lastName, String email,
      String hashName, String facebookId, String gender, String photo) async {

    final String accessToken = Utilities.generateToken(
        '00000000-0000-0000-0000-000000000000', 'addUser');

    final String body = jsonEncode(<String,String>{
      'userId': '00000000-0000-0000-0000-000000000000',
      'accessToken': accessToken,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'hashHandle': hashName,
      'facebookId': facebookId,
      'gender': gender,
      'photo': photo
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

    AddUserModel thisUser;

    json.decode(response.body).forEach(
      (dynamic user) {
        thisUser = AddUserModel(
          userId: user['userId'],
          qrCode: user['qr_code'],
          qrSecretCode: user['qr_secret_code'],
          displayName: user['displayName'],
          firstName: user['firstName'],
          lastName: user['lastName'],
          email: user['email'],
          hasherKennelMapId: user['hasherKennelMapId'],
          hasherEventMapId: user['hasherEventMapId'],
          memberCount: user['memberCount'],
        );
      },
    );

    return thisUser;
  }
}
