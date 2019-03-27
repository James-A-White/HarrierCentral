import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:scoped_model/scoped_model.dart';

import 'package:harrier_central/data_models/join_event_model.dart';
import 'package:harrier_central/data_models/user_run_history_model.dart';
import 'package:harrier_central/services/join_event_service.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';

class UserRunHistoryScopedModel extends Model {
  UserRunHistoryScopedModel({
    @required this.kennelId,
  });

  final String kennelId;

  final List<UserEventHistoryModel> _eventList = <UserEventHistoryModel>[];
  List<UserEventHistoryModel> get userEventList => _eventList;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void addEditEventList(UserEventHistoryModel event) {
    if (_eventList.isNotEmpty) {
      final UserEventHistoryModel evt = _eventList.firstWhere(
          (UserEventHistoryModel e) => e.eventId == event.eventId,
          orElse: () => null);

      if (evt != null) {
        // //if (ken.kennelName != kennel.kennelName) {ken.kennelName = kennel.kennelName;}
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

  Future<void> getUserEventsFromBackend(bool showLoadingIndicator) async {
    if (showLoadingIndicator) {
      _isLoading = true;
      notifyListeners();
    }

    final String userId = getStringPref(StringPrefsEnum.userId);

    final String accessToken =
        Utilities.generateToken(userId.toUpperCase(), 'getMyRuns');

    final String body = jsonEncode(<String, Object>{
      'userId': userId,
      'accessToken': accessToken,
      'kennelId': kennelId,
      'following': -1
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'get_my_runs',
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

    final List<UserEventHistoryModel> items =
        UserEventHistoryModel.itemsFromJson(response.body);

    for (int i = 0; i < items.length; i++) {
      addEditEventList(items[i]);
    }

    _isLoading = false;

    notifyListeners();
  }

  Future<JoinEventModel> setRsvpState(int rsvpState, int isHare, int attendenceState, String eventId) {
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

    return srv
        .joinEvent(eventId, rsvpState, isHare, attendenceState);

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
}
