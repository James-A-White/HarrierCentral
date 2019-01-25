
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
      num paymentAmount) async {
    final String userId = Preferences.getStringPref(StringPrefsEnum.userId);

    final String accessToken = Utilities.generateToken(userId, 'payForEvent');

    final String body = jsonEncode(<String, String>{
      'userId': userId,
      'accessToken': accessToken,
      'userIdWhoPaid': userIdWhoPaid,
      'eventId': eventId,
      'hasherEventMapId': hasherEventMapId,
      'paymentType': paymentType.toString(),
      'paymentAmount': paymentAmount.toString(),
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

    final List<PayForEventModel> itemList = List<PayForEventModel>();

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
            isPaid: items['isPaid']);

        itemList.add(item);
      },
    );

    return itemList;
  }
}
