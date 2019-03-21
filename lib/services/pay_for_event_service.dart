
import 'dart:async';
import 'dart:convert';

import 'package:harrier_central/data_models/pay_for_event_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';

import 'package:http/http.dart' as http;

class PayForEventService {

  Future<List<PayForEventModel>> payForEvent(
      String userIdWhoPaid,
      String eventId,
      String hasherEventMapId,
      int paymentType,
      num paymentAmount,
      int minimumAttendenceValue) async {
    final String userId = Preferences.getStringPref(StringPrefsEnum.userId);

    if ((userIdWhoPaid ?? '').isEmpty) userIdWhoPaid = '00000000-0000-0000-0000-000000000000';
    if ((hasherEventMapId ?? '').isEmpty) hasherEventMapId = '00000000-0000-0000-0000-000000000000';

    final String tokenParameterString = hasherEventMapId.toUpperCase() + '#' + userIdWhoPaid.toUpperCase() + '#' + paymentAmount.toInt().toString() + '#' + eventId.toUpperCase();

    final String accessToken = Utilities.generateToken(userId, 'payForEvent', paramString: tokenParameterString);

    final String body = jsonEncode(<String, String>{
      'userId': userId,
      'accessToken': accessToken,
      'userIdWhoPaid': userIdWhoPaid,
      'eventId': eventId,
      'hasherEventMapId': hasherEventMapId,
      'paymentType': paymentType.toString(),
      'paymentAmount': paymentAmount.toString(),
      'minimumAttendenceValue': minimumAttendenceValue.toString(),
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'pay_for_event',
            headers: <String, String>{'content-type': 'application/json'},
            body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return false;
      },
    );

    final List<PayForEventModel> itemList = <PayForEventModel>[];

    PayForEventModel item;
    json.decode(response.body).forEach(
      (dynamic items) {
        item = PayForEventModel(

            result: items['result'],
            waitingForCount: items['waitingForCount'],
            atHashCount: items['atHashCount'],
            onInCount: items['onInCount'],
            onTrailCount: items['onTrailCount'],
            paidCount: items['paidCount'],
            buttonState: items['buttonState'],
            totalRunsThisKennel: items['totalRunsThisKennel'],
            isPaid: items['isPaid'],
            hasherEventMapId: items['hasherEventMapId'],
            );

        itemList.add(item);
      },
    );

    return itemList;
  }
}
