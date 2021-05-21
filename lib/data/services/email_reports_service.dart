import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:http/http.dart' as http;

import 'package:harrier_central/util/constants.dart';

import 'package:ive_flutter_core/util/core_utilities.dart';
import 'package:harrier_central/util/enums.dart';

class EmailReportsService {
  Future<Map<String, String>> sendKennelRunStatsReportByEmail(
      {String kennelId,
      String kennelName,
      int digitsAfterDecimal,
      String currencySymbol}) async {
    final String userId = getStringPref(StringPrefsEnum.userId);
    final String userName = getStringPref(StringPrefsEnum.displayName);
    final String emailAddress = getStringPref(StringPrefsEnum.email);

    final String accessToken =
        CoreUtilities.generateToken(userId, 'rptKennelRunStats');

    if ((emailAddress ?? '').isNotEmpty) {
      final String body = jsonEncode(<String, String>{
        'userId': userId,
        'accessToken': accessToken,
        'kennelId': kennelId,
        'kennelName': kennelName,
        'userName': userName,
        'emailAddress': emailAddress,
        'digitsAfterDecimal': digitsAfterDecimal.toString(),
        'currencySymbol': currencySymbol
      });

      final http.Response response = await http
          .post(EMAIL_KENNEL_RUN_STATS_API_URL,
              headers: <String, String>{'content-type': 'application/json'},
              body: body)
          .catchError(
        (dynamic error) {
          return <String, String>{'result': 'error', 'email': ''};
        },
      );

      return <String, String>{'result': response.body, 'email': emailAddress};
    }
    return <String, String>{
      'result': 'No valid email address found',
      'email': ''
    };
  }
}
