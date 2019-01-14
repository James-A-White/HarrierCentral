
import 'dart:async';
import 'dart:convert';

import 'package:harrier_central/data_models/pack_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';

import 'package:http/http.dart' as http;

class GetPack {

  Future<List<PackModel>> getUsersByEvent(String eventId, String targetUserId) async {

    final String userId = Preferences.getStringPref(StringPrefsEnum.userId);

    final String accessToken = Utilities.generateToken(
        userId, 'getUsersByEventForAdmin');

    final String body = jsonEncode(<String,String>{
      'userId': userId,
      'accessToken': accessToken,
      'eventId': eventId,
      'targetUserId' : targetUserId
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'get_users_by_event_for_admin',
            headers: <String,String> {'content-type': 'application/json'}, body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return false;
      },
    );

    final List<PackModel> usersList =  List<PackModel>();

    PackModel item;
    json.decode(response.body).forEach(
      (dynamic jsonItem) {
        item = PackModel(

        eventId: jsonItem['eventId'],
        hasherId: jsonItem['userId'],
        isFollowing: jsonItem['isFollowing'],
        isMember: jsonItem['isMember'],
        isRsvped: jsonItem['isRsvped'],
        hasherEventMapId: jsonItem['hasherEventMapId'],
        isHare: jsonItem['isHare'],
        virginVisitorType: jsonItem['virginVisitorType'],
        userStartEvent: DateTime.parse(jsonItem['userStartEvent'] ?? '2000-01-01 19:00:00'),
        userEndEvent: DateTime.parse(jsonItem['userEndEvent'] ?? '2000-01-01 19:00:00'),
        rsvpState: jsonItem['rsvpState'],        
        attendenceState: jsonItem['attendenceState'],
        isPaid: jsonItem['isPaid'],
        displayName: jsonItem['displayName'],
        photo: jsonItem['photo'],
        userRunCount: jsonItem['userRunCount'],
        waitingForCount: jsonItem['waitingForCount'],
        atHashCount: jsonItem['atHashCount'],
        onInCount: jsonItem['onInCount'],
        onTrailCount: jsonItem['onTrailCount'],
        paidCount: jsonItem['paidCount'],
        eventPrice: jsonItem['eventPrice'] * 1.0,
        eventLocale: jsonItem['eventLocale'],
        allowNegativeCredit: jsonItem['allowNegativeCredit'],
        credit: jsonItem['credit'] * 1.0,
        currencySymbol: jsonItem['currencySymbol'],
        digitsAfterDecimal: jsonItem['digitsAfterDecimal'],

        );

        usersList.add(item);
      },
    );

    return usersList;
  }


}
