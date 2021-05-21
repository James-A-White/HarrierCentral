import 'dart:async';
import 'dart:convert';

import 'package:harrier_central/data/models/single_result_model.dart';
import 'package:harrier_central/util/constants.dart';

import 'package:ive_flutter_core/util/core_utilities.dart';
import 'package:ive_flutter_core/util/connection.dart';
import 'package:harrier_central/util/enums.dart';

import 'package:http/http.dart' as http;

class GetResetCodeService {
  Future<SingleResultModel> getResetCode(String supportCode) async {
    if (globalConnectionStatus == connectionStatus_notConnected) {
      return null;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId);

    final String accessToken =
        CoreUtilities.generateToken(userId, 'getResetCode');

    final String body = jsonEncode(<String, String>{
      'userId': userId,
      'accessToken': accessToken,
      'supportCode': supportCode
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'hc3_get_reset_code',
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
