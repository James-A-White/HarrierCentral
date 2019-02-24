import 'dart:async';
import 'dart:convert';

import 'package:harrier_central/data_models/user_model.dart';
import 'package:harrier_central/data_models/join_event_model.dart';
import 'package:harrier_central/remote_api_data/join_event_service.dart';
import 'package:harrier_central/util/constants.dart';

import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/utilities.dart';

import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:scoped_model/scoped_model.dart';

class PackScopedModel extends Model {
  List<UserModel> _packList;
  List<UserModel> get packList => _packList;

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

  void forceRefresh() {
    notifyListeners();
  }

  Future<UserModel> joinEventAsVisitor(String displayName, String email,
      String phoneNumber, EnumVirginVisitor virginVisitor, String eventId) {
    notifyListeners();
    JoinEventService srv = JoinEventService();
    return srv.joinEventAsVisitor(eventId, virginVisitor, attendenceAtHash,
        displayName, email, phoneNumber);
  }

  void setRsvpState(
      int rsvpState, int isHare, int attendenceState, UserModel user) {
    bool isDirty = false;

    if ((rsvpState != -1) && (rsvpState != user.rsvpState)) {
      user.requestedRsvpState = rsvpState;
      user.rsvpState = -1;
      isDirty = true;
    }

    if ((isHare != -1) && (isHare != user.isHare)) {
      user.requestedHaringState = isHare;
      user.isHare = -1;
      isDirty = true;
    }

    if ((attendenceState != -1) && (user.attendenceState != attendenceState)) {
      user.requestedAttendenceState = attendenceState;
      user.attendenceState = -1;
      isDirty = true;
    }

    if (isDirty) {
      notifyListeners();
      JoinEventService srv = new JoinEventService();

      srv
          .joinEvent(
              user.eventId, rsvpState, isHare, attendenceState, user.hasherId, user.hasherEventMapId)
          .then<dynamic>((JoinEventModel result) {
        if ((rsvpState != -1) && (rsvpState != user.rsvpState)) {
          user.rsvpState = rsvpState;
          user.requestedRsvpState = -1;
        }

        if ((isHare != -1) && (isHare != user.isHare)) {
          user.isHare = isHare;
          user.requestedHaringState = -1;
        }

        if ((attendenceState != -1) &&
            (user.attendenceState != attendenceState)) {
          user.attendenceState = attendenceState;
          user.requestedAttendenceState = -1;
        }

        user.userRunCount = result.totalRunsThisKennel;

        // run.rsvpYesCount = result.rsvpYesCount;
        // run.rsvpNoCount = result.rsvpNoCount;
        // run.rsvpMaybeCount = result.rsvpMaybeCount;
        // run.haresCount = result.haresCount;

        notifyListeners();
      });
    }
  }

  void sortPackList()
  {
     _packList.sort((a,b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
  }

  void addEditPackModelList(UserModel packModel) {
    if (_packList.isNotEmpty) {
      final UserModel packItem = _packList.firstWhere(
          (UserModel pi) => ((packModel.hasherEventMapId ==
                      pi.hasherEventMapId) &&
                  (packModel.hasherId ==
                      null) // this covers people who are visitors and virgins
              ||
              (packModel.hasherEventMapId == null) &&
                  (packModel.hasherId == pi.hasherId)), // this covers members
          orElse: () => null);

      if (packItem != null) {
        int i = 0;
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

  Future<List<UserModel>> _getPack(String eventId, String targetUserId) async {
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

    final List<UserModel> userListFromServer = List<UserModel>();

    UserModel item;
    json.decode(response.body).forEach(
      (dynamic jsonItem) {
        item = UserModel(
          // isRsvped: jsonItem['isRsvped'],
          allowNegativeCredit: jsonItem['allowNegativeCredit'],
          atHashCount: jsonItem['atHashCount'],
          attendenceState: jsonItem['attendenceState'],
          credit: jsonItem['credit'] * 1.0,
          currencySymbol: jsonItem['currencySymbol'],
          digitsAfterDecimal: jsonItem['digitsAfterDecimal'],
          displayName: jsonItem['displayName'],
          email: jsonItem['email'],
          eventId: jsonItem['eventId'],
          eventLocale: jsonItem['eventLocale'],
          eventPrice: jsonItem['eventPrice'] * 1.0,
          facebookId: jsonItem['facebookId'],
          firstName: jsonItem['firstName'],
          hasherEventMapId: jsonItem['hasherEventMapId'],
          hasherId: jsonItem['userId'],
          isFollowing: jsonItem['isFollowing'],
          isHare: jsonItem['isHare'],
          isMember: jsonItem['isMember'],
          isPaid: jsonItem['isPaid'],
          lastName: jsonItem['lastName'],
          onInCount: jsonItem['onInCount'],
          onTrailCount: jsonItem['onTrailCount'],
          paidCount: jsonItem['paidCount'],
          paymentType: jsonItem['paymentType'],
          photo: jsonItem['photo'],
          qrCode: jsonItem['qrCode'],
          qrSecretCode: jsonItem['qrSecretCode'],
          rsvpState: jsonItem['rsvpState'],
          userEndEvent:DateTime.parse(jsonItem['userEndEvent'] ?? '2000-01-01 19:00:00'),
          userRunCount: jsonItem['userRunCount'],
          userStartEvent: DateTime.parse(jsonItem['userStartEvent'] ?? '2000-01-01 19:00:00'),
          virginVisitorType: jsonItem['virginVisitorType'],
          waitingForCount: jsonItem['waitingForCount'],
        );

        userListFromServer.add(item);
      },
    );

    return userListFromServer;
  }

  Future<List<UserModel>> getpackFromBackend(
      String eventId, bool showLoadingIndicator, bool forceEntireReload) async {
    print('Get pack from backend: ' +
        DateTime.now().millisecondsSinceEpoch.toString());
    // if (!showLoadingIndicator && (_packList != null)) {
    //   return null;
    // }

    _packList ??= <UserModel>[];

    if (showLoadingIndicator) {
      _isLoading = true;
      notifyListeners();
    }

    if (forceEntireReload) {
      _packList.clear();
    }

    final List<UserModel> dataFromResponse =
        await _getPack(eventId, '00000000-0000-0000-0000-000000000000');

    dataFromResponse.forEach(
      (UserModel item) {
        //parse new kennel's details

        addEditPackModelList(item);
      },
    );

    sortPackList();

    _isLoading = false;

    notifyListeners();

    return _packList;
  }
}
