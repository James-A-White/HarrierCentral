import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';

import 'package:harrier_central/data_models/future_run_model.dart';
import 'package:harrier_central/data_models/join_event_model.dart';
import 'package:harrier_central/remote_api_data/join_event_service.dart';
import 'package:harrier_central/util/constants.dart';

import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';

import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:scoped_model/scoped_model.dart';

class FutureRunScopedModel
 extends Model {
  List<FutureRun> _futureRunsList;
  List<FutureRun> get futureRunsList => _futureRunsList;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  PermissionStatus _location_permission;

  void clearFutureRunsList() {
    if (_futureRunsList != null) {
      _futureRunsList.clear();
      _futureRunsList = null;
    }
  }

  int getFutureRunsCount() {
    return _futureRunsList.length;
  }

  void setRsvpState(
      int rsvpState, int isHare, int attendenceState, FutureRun run) {
    if (rsvpState != -1) {
      run.requestedRsvpState = rsvpState;
      run.rsvpState = -1;
    }

    if (isHare != -1) {
      run.requestedHaringState = isHare;
      run.isHare = -1;
    }

    if (attendenceState != -1) {
      run.attendenceState = -1;
      run.requestedAttendenceState = attendenceState;
    }

    notifyListeners();
    JoinEventService srv = new JoinEventService();
    srv
        .joinEvent(run.eventId, rsvpState, isHare, attendenceState)
        .then<dynamic>((JoinEventModel result) {
      if (rsvpState != -1) {
        run.rsvpState = rsvpState;
        run.requestedRsvpState = -1;
      }

      if (isHare != -1) {
        run.isHare = isHare;
        run.requestedHaringState = -1;
      }

      if (attendenceState != -1) {
        run.attendenceState = attendenceState;
        run.requestedAttendenceState = -1;
      }

      run.rsvpYesCount = result.rsvpYesCount;
      run.rsvpNoCount = result.rsvpNoCount;
      run.rsvpMaybeCount = result.rsvpMaybeCount;
      run.haresCount = result.haresCount;

      notifyListeners();
    });
  }

  void addEditFutureRunList(FutureRun futureRun) {
    if (_futureRunsList.isNotEmpty) {
      final FutureRun run = _futureRunsList.firstWhere(
          (FutureRun evt) => evt.eventId == futureRun.eventId,
          orElse: () => null);

      if (run != null) {
        if (run.hareList != futureRun.hareList) {
          run.hareList = futureRun.hareList;
        }
        if (run.eventStartDatetime != futureRun.eventStartDatetime) {
          run.eventStartDatetime = futureRun.eventStartDatetime;
        }
        if (run.eventNumber != futureRun.eventNumber) {
          run.eventNumber = futureRun.eventNumber;
        }
        if (run.daysUntilNextRun != futureRun.daysUntilNextRun) {
          run.daysUntilNextRun = futureRun.daysUntilNextRun;
        }
        if (run.distanceToEvent != futureRun.distanceToEvent) {
          run.distanceToEvent = futureRun.distanceToEvent;
        }
        // // add fields here that might have been updated
        // if (ken.followingBool != kennel.followingBool) {ken.followingBool = kennel.followingBool;}
        // //if (ken.kennelName != kennel.kennelName) {ken.kennelName = kennel.kennelName;}
        // //if (ken.kennelShortName != kennel.kennelShortName) {ken.kennelShortName = kennel.kennelShortName;}
        // //if (ken.locationName != kennel.locationName) {ken.locationName = kennel.locationName;}
        // if (ken.isHomeKennel != kennel.isHomeKennel) {ken.isHomeKennel = kennel.isHomeKennel;}
        // if (ken.isMember != kennel.isMember) {ken.isMember = kennel.isMember;}
      } else {
        _futureRunsList.add(futureRun);
      }
    } else {
      _futureRunsList.add(futureRun);
    }
  }

  Future<dynamic> _getFutureRunsByDistance(int distance) async {
    Position position;

    if (_location_permission == null) {
      _location_permission = await PermissionHandler()
          .checkPermissionStatus(PermissionGroup.location);
    }

    if (_location_permission == PermissionStatus.granted) {
      position = await Geolocator()
          .getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);
    }

    double latitude = DEFAULT_LATITUDE;
    double longitude = DEFAULT_LONGITUDE;
    if (position != null) {
      latitude = position.latitude;
      longitude = position.longitude;
    }

    final String userId = Preferences.getStringPref(StringPrefsEnum.userId);

    final String accessToken = Utilities.generateToken(
        userId.toUpperCase(), 'getFutureRunsByDistance');

    final String body = jsonEncode(<String, Object>{
      'userId': userId,
      'accessToken': accessToken,
      'distanceInKm': distance,
      'latitude': latitude,
      'longitude': longitude,
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'get_future_runs_by_distance',
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

    return json.decode(response.body);
  }

  Future<void> getFutureRunsFromBackend(bool forceRefresh) async {
    if (!forceRefresh && (_futureRunsList != null)) {
      return null;
    }

    _futureRunsList ??= <FutureRun>[];

    _isLoading = true;
    if (forceRefresh) {
      notifyListeners();
    }
    final dynamic dataFromResponse = await _getFutureRunsByDistance(50);

    dataFromResponse.forEach(
      (dynamic run) {
        //parse new kennel's details
        final FutureRun thisRun = FutureRun(
          eventId: run['eventId'],
          kennelId: run['kennelId'],
          eventName: run['eventName'],
          eventNumber: run['eventNumber'],
          locationOneLineDesc: run['locationOneLineDesc'],
          eventDescription: run['eventDescription'],
          eventPriceForMembers: run['eventPriceForMembers'] * 1.0,
          eventPriceForNonMembers: run['eventPriceForNonMembers'] * 1.0,
          eventCurrencyType: run['eventCurrencyType'],
          currencySymbol: run['currencySymbol'],
          digitsAfterDecimal: run['digitsAfterDecimal'],
          eventImage: run['eventImage'],
          eventShortDesc: run['eventShortDesc'],
          locationCity: run['locationCity'],
          locationStreet: run['locationStreet'],
          locationPostCode: run['locationPostCode'],
          rsvpYesCount: run['attendingEvent'],
          rsvpNoCount: run['notAttendingEvent'],
          rsvpMaybeCount: run['maybeAttendingEvent'],
          haresCount: run['haresCount'],
          hareList: run['hareList'],
          latitude: run['latitude'],
          longitude: run['longitude'],
          kennelLogo: run['kennelLogo'],
          daysUntilNextRun: run['daysUntilNextRun'],
          eventStartDatetime: DateTime.parse(run['eventStartDatetime']),
          friendsAttending: run['friendsAttending'],
          rsvpState: run['rsvpState'],
          attendenceState: run['attendenceState'],
          isHare: run['isHare'],
          totalRunsThisKennel: run['totalRunsThisKennel'],
          kennelShortName: run['kennelShortName'],
          runSequence: run['runSequence'],
          distanceToEvent: run['distanceToEvent'],
        );

        thisRun.isExpanded = false;

        addEditFutureRunList(thisRun);
      },
    );

    _isLoading = false;

    notifyListeners();

    return null;
  }
}
