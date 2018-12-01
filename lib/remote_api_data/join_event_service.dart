
import 'dart:async';
import 'dart:convert';

import 'package:harrier_central/data_models/join_event_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';

import 'package:http/http.dart' as http;

//import 'package:harrier_central/util/constants.dart';

//import 'package:geolocator/geolocator.dart';

class JoinEventService {
//    @userId uniqueidentifier,
//  @accessToken nvarchar(1000),
//  @eventId uniqueidentifier,

//  @state VARCHAR(10) = '-1',
//  @isHare VARCHAR(10) = '-1',
//  @isAttending VARCHAR(10) = '-1',

//  @resultRequested nvarchar(25) = 'Attendance totals'

  Future<JoinEventModel> joinEvent(
      String eventId, int rsvpState, int isHare, int isAttending) async {
    final String userId = Preferences.getStringPref(StringPrefsEnum.userId);

    final String accessToken =
        Utilities.generateToken(userId.toUpperCase(), 'joinEvent');

    final String body = jsonEncode(<String, Object>{
      'userId': userId,
      'accessToken': accessToken,
      'eventId': eventId,
      'state': rsvpState,
      'isHare' : isHare,
      'isAttending': isAttending,
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
          attendingEvent: user['attendingEvent'],
          notAttendingEvent: user['notAttendingEvent'],
          maybeAttendingEvent: user['maybeAttendingEvent'],
          haresCount: user['haresCount'],
        );
      },
    );

    return thisUser;
  }
}
