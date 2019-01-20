import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';

import 'package:harrier_central/data_models/pack_model.dart';
import 'package:harrier_central/data_models/join_event_model.dart';
import 'package:harrier_central/remote_api_data/join_event_service.dart';
import 'package:harrier_central/util/constants.dart';

import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';

import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:scoped_model/scoped_model.dart';

class PackScopedModel extends Model {
  List<PackModel> _packList;
  List<PackModel> get packList => _packList;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  PermissionStatus _location_permission;

  void clearPackList() {
    if (_packList != null) {
      _packList.clear();
      _packList = null;
    }
  }

  int getPackCount() {
    return _packList.length;
  }

  void forceRefresh()
  {
    notifyListeners();
  }

  void setRsvpState(
      int rsvpState, int isHare, int attendenceState, PackModel run) {
    bool isDirty = false;

    if ((rsvpState != -1) && (rsvpState != run.rsvpState)) {
      run.requestedRsvpState = rsvpState;
      run.rsvpState = -1;
      isDirty = true;
    }

    if ((isHare != -1) && (isHare != run.isHare)) {
      run.requestedHaringState = isHare;
      run.isHare = -1;
      isDirty = true;
    }

    if ((attendenceState != -1) && (run.attendenceState != attendenceState)) {
      run.requestedAttendenceState = attendenceState;
      run.attendenceState = -1;
      isDirty = true;
    }

    if (isDirty) {
      notifyListeners();
      JoinEventService srv = new JoinEventService();
      srv
          .joinEvent(run.eventId, rsvpState, isHare, attendenceState, run.hasherId)
          .then<dynamic>((JoinEventModel result) { 
        if ((rsvpState != -1) && (rsvpState != run.rsvpState)) {
          run.rsvpState = rsvpState;
          run.requestedRsvpState = -1;
        }

        if ((isHare != -1) && (isHare != run.isHare)) {
          run.isHare = isHare;
          run.requestedHaringState = -1;
        }

        if ((attendenceState != -1) && (run.attendenceState != attendenceState)) {
          run.attendenceState = attendenceState;
          run.requestedAttendenceState = -1;
        }

        // run.rsvpYesCount = result.rsvpYesCount;
        // run.rsvpNoCount = result.rsvpNoCount;
        // run.rsvpMaybeCount = result.rsvpMaybeCount;
        // run.haresCount = result.haresCount;

        notifyListeners();
      });
    }
  }

  void addEditPackModelList(PackModel packModel) {
    if (_packList.isNotEmpty) {
      final PackModel packItem = _packList.firstWhere(
          (PackModel pi) => pi.hasherEventMapId == packModel.hasherEventMapId,
          orElse: () => null);

      if (packItem != null) {
        // if (run.hareList != packModel.hareList) {
        //   run.hareList = packModel.hareList;
        // }
        // if (run.eventStartDatetime != packModel.eventStartDatetime) {
        //   run.eventStartDatetime = packModel.eventStartDatetime;
        // }
        // if (run.eventNumber != packModel.eventNumber) {
        //   run.eventNumber = packModel.eventNumber;
        // }
        // if (run.daysUntilNextRun != packModel.daysUntilNextRun) {
        //   run.daysUntilNextRun = packModel.daysUntilNextRun;
        // }
        // if (run.distanceToEvent != packModel.distanceToEvent) {
        //   run.distanceToEvent = packModel.distanceToEvent;
        // }

      } else {
        _packList.add(packModel);
      }
    } else {
      _packList.add(packModel);
    }
  }

  //  Future<List<PackModel>> getPack(String eventId) async {

  //   final String userId = Preferences.getStringPref(StringPrefsEnum.userId);

  //   final String accessToken = Utilities.generateToken(
  //       userId, 'getUsersByEvent');

  //   final String body = jsonEncode(<String,String>{
  //     'userId': userId,
  //     'accessToken': accessToken,
  //     'eventId': eventId
  //   });

  //   final http.Response response = await http
  //       .post(BASE_API_URL + 'get_users_by_event',
  //           headers: <String,String> {'content-type': 'application/json'}, body: body
  //           // Send authorization headers to your backend
  //           //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
  //           )
  //       .catchError(
  //     (dynamic error) {
  //       return false;
  //     },
  //   );

  //   final List<PackModel> packList =  List<PackModel>();

  //   PackModel packMember;
  //   json.decode(response.body).forEach(
  //     (dynamic pack) {
  //       packMember = PackModel(
  //         hasherId: pack['hasherId'],
  //         hasherEventMapId: pack['hasherEventMapId'],
  //         rsvpState: pack['rsvpState'],
  //         attendenceState: pack['attendenceState'],
  //         displayName: pack['displayName'],
  //         photo: pack['photo'],
  //         isHare: pack['isHare']
  //       );

  //       packList.add(packMember);
  //     },
  //   );

  //   return packList;
  // }

  Future<List<PackModel>> getPack(String eventId, String targetUserId) async {
    final String userId = Preferences.getStringPref(StringPrefsEnum.userId);

    final String accessToken =
        Utilities.generateToken(userId, 'getUsersByEventForAdmin');

    final String body = jsonEncode(<String, String>{
      'userId': userId,
      'accessToken': accessToken,
      'eventId': eventId,
      'targetUserId': targetUserId
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'get_users_by_event_for_admin',
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

    final List<PackModel> usersList = List<PackModel>();

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
          userStartEvent: DateTime.parse(
              jsonItem['userStartEvent'] ?? '2000-01-01 19:00:00'),
          userEndEvent:
              DateTime.parse(jsonItem['userEndEvent'] ?? '2000-01-01 19:00:00'),
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

  Future<void> getpackFromBackend(String eventId, bool forceRefresh) async {
    if (!forceRefresh && (_packList != null)) {
      return null;
    }

    _packList ??= <PackModel>[];

    _isLoading = true;
    if (forceRefresh) {
      notifyListeners();
    }
    final dynamic dataFromResponse =
        await getPack(eventId, '00000000-0000-0000-0000-000000000000');

    dataFromResponse.forEach(
      (dynamic jsonItem) {
        //parse new kennel's details
        final PackModel thisRun = PackModel(
          eventId: jsonItem['eventId'],
          hasherId: jsonItem['userId'],
          isFollowing: jsonItem['isFollowing'],
          isMember: jsonItem['isMember'],
          isRsvped: jsonItem['isRsvped'],
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

        jsonItem.isExpanded = false;

        addEditPackModelList(thisRun);
      },
    );

    _isLoading = false;

    notifyListeners();

    return null;
  }
}
