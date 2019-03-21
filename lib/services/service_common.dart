import 'dart:async';

import 'package:flutter/material.dart';

import 'package:harrier_central/data_models/db_error_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/utilities.dart';

import 'package:http/http.dart' as http;

class ServiceCommon {
  static Future<String> sendRequest(BuildContext context, String requestBody) async {
    final http.Response response = await http
        .post(BASE_API_URL + 'add_user',
            headers: <String, String>{'content-type': 'application/json'},
            body: requestBody
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return ERROR_KEY;
      },
    );

    if (response.body.contains('"errorId"')) {
      final DbErrorModel result = DbErrorModel.itemFromJson(response.body);
      if (result != null) {
        await Utilities.showAlert(context, result.errorTitle,
            result.errorUserMessage, 'OK');
      }

      return ERROR_KEY;
    }

    return response.body;
  }
}
