

import 'dart:async';
import 'dart:convert';

import 'package:harrier_central/data_models/single_result_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';

import 'package:http/http.dart' as http;

class GetResetCodeService {

  Future<SingleResultModel> getResetCode(String supportCode) async {

    final String userId = getStringPref(StringPrefsEnum.userId);

    final String accessToken = Utilities.generateToken(
        userId, 'getResetCode');

    final String body = jsonEncode(<String,String>{
      'userId': userId,
      'accessToken': accessToken,
      'supportCode': supportCode
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'get_reset_code',
            headers: <String,String> {'content-type': 'application/json'}, body: body
            )
        .catchError(
      (dynamic error) {
        return false;
      },
    );

    SingleResultModel result;

    json.decode(response.body).forEach(
      (dynamic item) {
        result = SingleResultModel(
          result: item['result']
        );
      },
    );

    return result;
  }
}
