import 'dart:async';
import 'dart:convert';

import 'package:harrier_central/data_models/join_event_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/utilities.dart';

import 'package:http/http.dart' as http;



class JoinEventService {

    Future<JoinEventModel> joinEventAsVisitor(
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
          hasherEventMapId: user['hasherEventMapId'],
        );
      },
    );

    return thisUser;
  }


  Future<JoinEventModel> joinEvent(
      String eventId, int rsvpState, int isHare, int attendenceState,
      [String hasherId]) async {
    final String userId = Preferences.getStringPref(StringPrefsEnum.userId);

    final String accessToken =
        Utilities.generateToken(userId.toUpperCase(), 'joinEvent');

    final String body = jsonEncode(<String, Object>{
      'userId': userId,
      'accessToken': accessToken,
      'eventId': eventId,
      'hasherId': hasherId ?? userId,
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
