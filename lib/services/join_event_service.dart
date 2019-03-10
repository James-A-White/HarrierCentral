import 'dart:async';
import 'dart:convert';

import 'package:harrier_central/data_models/join_event_model.dart';
import 'package:harrier_central/data_models/user_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/utilities.dart';

import 'package:http/http.dart' as http;



class JoinEventService {

    Future<UserModel> joinEventAsVisitor(
      String eventId, EnumVirginVisitor virginVisitor, EnumAttendenceState attendenceState, String name, String email, String phoneNumber) async {
    final String userId = Preferences.getStringPref(StringPrefsEnum.userId);

    final String accessToken =
        Utilities.generateToken(userId.toUpperCase(), 'joinEventAsVisitor');

    int virginVisitorType = 1;
    if (virginVisitor == EnumVirginVisitor.visitor) 
    {
      virginVisitorType = 2;
    }

    final String body = jsonEncode(<String, Object>{
      'userId': userId,
      'accessToken': accessToken,
      'eventId': eventId,
      'displayName': name,
      'virginVisitorType': virginVisitorType,
      'attendenceState' :attendenceState.value,
      'email' : email,
      'phoneNumber':phoneNumber
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'join_event_as_visitor',
            headers: <String, String>{'content-type': 'application/json'},
            body: body,
            //encoding: const Utf8Codec()
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
      (dynamic jsonItem) {
        thisUser = UserModel(
          eventId: jsonItem['eventId'],
          hasherId: jsonItem['userId'],
          isFollowing: jsonItem['isFollowing'],
          isMember: jsonItem['isMember'],
          // isRsvped: jsonItem['isRsvped'],
          hasherEventMapId: jsonItem['hasherEventMapId'],
          isHare: jsonItem['isHare'],
          virginVisitorType: jsonItem['virginVisitorType'],
          userStartEvent: DateTime.parse(
              jsonItem['userStartEvent'] ?? '2000-01-01 19:00:00'),
          userEndEvent:
              DateTime.parse(jsonItem['userEndEvent'] ?? '2000-01-01 19:00:00'),
          rsvpState: jsonItem['rsvpState'],
          attendenceState: jsonItem['attendenceState'],
          isPaid: jsonItem['isPaid'],
          paymentType: jsonItem['paymentType'],
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
      },
    );

    return thisUser;
  }


  Future<JoinEventModel> joinEvent(
      String eventId, int rsvpState, int isHare, int attendenceState,
      [String hasherId ,String hasherEventMapId]) async {
    final String userId = Preferences.getStringPref(StringPrefsEnum.userId);

    final String accessToken =
        Utilities.generateToken(userId.toUpperCase(), 'joinEvent');

    final String body = jsonEncode(<String, Object>{
      'userId': userId,
      'accessToken': accessToken,
      'eventId': eventId,
      'hasherId': hasherId,
      'hasherEventMapId':hasherEventMapId,
      'isHare': isHare,
      'rsvpState': rsvpState,
      'attendenceState': attendenceState,
      'resultsRequested': 'Attendance totals'
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'join_event',
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

    JoinEventModel thisUser;

    json.decode(response.body).forEach(
      (dynamic user) {
        thisUser = JoinEventModel(
          rsvpYesCount: user['rsvpYesCount'],
          rsvpNoCount: user['rsvpNoCount'],
          rsvpMaybeCount: user['rsvpMaybeCount'],
          haresCount: user['haresCount'],
          totalRunsThisKennel: user['totalRunsThisKennel'],
          totalRunsAllKennels: user['totalRunsAllKennels'],
        );
      },
    );

    return thisUser;
  }

}
