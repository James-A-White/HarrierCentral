import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:scoped_model/scoped_model.dart';

import 'package:harrier_central/data/models/join_event_model.dart';
import 'package:harrier_central/data/models/lite_event_model.dart';
import 'package:harrier_central/data/services/join_event_service.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';

class EventsScopedModel extends Model {
  EventsScopedModel({
    @required this.kennelId,
  });

  final String kennelId;

  final List<Event> _eventList = <Event>[];
  List<Event> get userEventList => _eventList;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void addEditEventList(Event event) {
    if (_eventList.isNotEmpty) {
      final Event evt = _eventList.firstWhere(
          (Event e) => e.eventId == event.eventId,
          orElse: () => null);

      if (evt != null) {
        if (evt.eventNumber != event.eventNumber) {
          evt.eventNumber = event.eventNumber;
        }
        if (evt.absoluteEventNumber != event.absoluteEventNumber) {
          evt.absoluteEventNumber = event.absoluteEventNumber;
        }
        if (evt.isCountedRun != event.isCountedRun) {
          evt.isCountedRun = event.isCountedRun;
        }
        if (evt.isVisible != event.isVisible) {
          evt.isVisible = event.isVisible;
        }

        // //if (ken.kennelShortName != kennel.kennelShortName) {ken.kennelShortName = kennel.kennelShortName;}
        // //if (ken.locationName != kennel.locationName) {ken.locationName = kennel.locationName;}
        // if (ken.totalHaringThisKennel != event.totalHaringThisKennel) {
        //   ken.totalHaringThisKennel = event.totalHaringThisKennel;
        // }
        // if (ken.totalPackRunsThisKennel != event.totalPackRunsThisKennel) {
        //   ken.totalPackRunsThisKennel = event.totalPackRunsThisKennel;
        // }

        // if (ken.totalRunsThisKennel != event.totalRunsThisKennel) {
        //   ken.totalRunsThisKennel = event.totalRunsThisKennel;
        // }
      } else {
        _eventList.add(event);
      }
    } else {
      _eventList.add(event);
    }
  }

  void clearKennelList() {
    _eventList.clear();
  }

  int getKennelsCount() {
    return _eventList.length;
  }

  Future<void> getUserEventsFromBackend(bool showLoadingIndicator,
      int filterByUser, int includeHidden, int includeFuture) async {

    
    if (globalConnectionStatus == connectionStatus_notConnected)
    {
      return;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    if (showLoadingIndicator) {
      _isLoading = true;
      //notifyListeners();
    }

    final String userId = getStringPref(StringPrefsEnum.userId);

    //final String paramString = '$kennelId#${filterByUser.toString()}';

    final String accessToken =
        Utilities.generateToken(userId.toUpperCase(), 'getRuns');

    final String body = jsonEncode(<String, Object>{
      'userId': userId,
      'accessToken': accessToken,
      'kennelId': kennelId,
      'following': -1,
      'filterByUser': filterByUser,
      'includeHidden': includeHidden,
      'includeFuture': includeFuture
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'get_runs',
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

    final List<Event> items = Event.itemsFromJson(response.body);

    for (int i = 0; i < items.length; i++) {
      addEditEventList(items[i]);
    }

    _isLoading = false;

    notifyListeners();
  }

  Future<JoinEventModel> setRsvpState(
      int rsvpState, int isHare, int attendenceState, String eventId) {
    //bool isDirty = false;

    // if ((rsvpState != -1) && (rsvpState != user.rsvpState)) {
    //   user.requestedRsvpState = rsvpState;
    //   user.rsvpState = -1;
    //   isDirty = true;
    // }

    // if ((isHare != -1) && (isHare != user.isHare)) {
    //   user.requestedHaringState = isHare;
    //   user.isHare = -1;
    //   isDirty = true;
    // }

    // if ((attendenceState != -1) && (user.attendenceState != attendenceState)) {
    //   user.requestedAttendenceState = attendenceState;
    //   user.attendenceState = -1;
    //   isDirty = true;
    // }

    notifyListeners();
    final JoinEventService srv = JoinEventService();

    return srv.joinEvent(eventId, rsvpState, isHare, attendenceState);

    // if ((rsvpState != -1) && (rsvpState != user.rsvpState)) {
    //   user.rsvpState = rsvpState;
    //   user.requestedRsvpState = -1;
    // }

    // if ((isHare != -1) && (isHare != user.isHare)) {
    //   user.isHare = isHare;
    //   user.requestedHaringState = -1;
    // }

    // if ((attendenceState != -1) &&
    //     (user.attendenceState != attendenceState)) {
    //   user.attendenceState = attendenceState;
    //   user.requestedAttendenceState = -1;
    // }

    // user.userRunCount = result.totalRunsThisKennel;

    // run.rsvpYesCount = result.rsvpYesCount;
    // run.rsvpNoCount = result.rsvpNoCount;
    // run.rsvpMaybeCount = result.rsvpMaybeCount;
    // run.haresCount = result.haresCount;
  }

  Future<Map<String, String>> sendRunCountReportByEmail(
      {String kennelId, String kennelName}) async {
    final String userId = getStringPref(StringPrefsEnum.userId);
    final String userName = getStringPref(StringPrefsEnum.displayName);
    final String emailAddress = getStringPref(StringPrefsEnum.email);

    final String accessToken1 =
        Utilities.generateToken(userId.toUpperCase(), 'getRuns');

    final String accessToken2 =
        Utilities.generateToken(userId, 'getMyKennelRunTotals');

    if ((emailAddress ?? '').isNotEmpty) {
      final String body = jsonEncode(<String, String>{
        'userId': userId,
        'accessToken1': accessToken1,
        'accessToken2': accessToken2,
        'kennelId': kennelId,
        'kennelName': kennelName,
        'userName': userName,
        'emailAddress': emailAddress
      });

      final http.Response response = await http
          .post(EMAIL_RUN_REPORT_API_URL,
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

  Future<dynamic> updateEvent(
      {String eventId,
      int isVisible,
      int isCountedRun,
      int absoluteRunNumber}) async {

    
    if (globalConnectionStatus == connectionStatus_notConnected)
    {
      return null;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    isVisible ??= -1;
    isCountedRun ??= -1;
    absoluteRunNumber ??= -1;

    final String userId = getStringPref(StringPrefsEnum.userId);

    final String accessToken = Utilities.generateToken(userId, 'addEditEvent');

    final String body = jsonEncode(<String, String>{
      'userId': userId,
      'accessToken': accessToken,
      'eventId': eventId,
      'isVisible': isVisible.toString(),
      'isCountedRun': isCountedRun.toString(),
      'absoluteEventNumber': absoluteRunNumber.toString()
    });

    return http
        .post(BASE_API_URL + 'add_edit_event',
            headers: <String, String>{'content-type': 'application/json'},
            body: body)
        .catchError(
      (dynamic error) {
        return <String, String>{'result': 'error', 'email': ''};
      },
    );
  }
}
