
import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';

import 'package:harrier_central/data_models/future_run_model.dart';
import 'package:harrier_central/data_models/join_event_model.dart';
import 'package:harrier_central/remote_api_data/join_event_service.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/data_models/kennel_member_model.dart';

import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:scoped_model/scoped_model.dart';

class KennelMemberScopedModel extends Model {
  final List<GetKennelMembersModel> _kennelMembersList = <GetKennelMembersModel>[];
  List<GetKennelMembersModel> get kennelMembersList => _kennelMembersList;

  bool _isLoading = true;

  bool get isLoading => _isLoading;

  void clearFutureRunsList() {
    _kennelMembersList.clear();
  }

  int getKennelMembersListCount() {
    return _kennelMembersList.length;
  }

  void addEditKennelMemberList(GetKennelMembersModel member) {
    if (_kennelMembersList.isNotEmpty) {
      final GetKennelMembersModel kennelMember = _kennelMembersList.firstWhere(
          (GetKennelMembersModel thisMember) => thisMember.hasherId == member.hasherId,
          orElse: () => null);

      if (kennelMember != null) {
        if (kennelMember.firstName != member.firstName) {
          kennelMember.firstName = member.firstName;
        }
        if (kennelMember.lastName != member.lastName) {
          kennelMember.lastName = member.lastName;
        }
        if (kennelMember.hashName != member.hashName) {
          kennelMember.hashName = member.hashName;
        }
        if (kennelMember.photo != member.photo) {
          kennelMember.photo = member.photo;
        }
        if (kennelMember.displayName != member.displayName) {
          kennelMember.displayName = member.displayName;
        }
        // // add fields here that might have been updated
        // if (ken.followingBool != kennel.followingBool) {ken.followingBool = kennel.followingBool;}
        // //if (ken.kennelName != kennel.kennelName) {ken.kennelName = kennel.kennelName;}
        // //if (ken.kennelShortName != kennel.kennelShortName) {ken.kennelShortName = kennel.kennelShortName;}
        // //if (ken.locationName != kennel.locationName) {ken.locationName = kennel.locationName;}
        // if (ken.isHomeKennel != kennel.isHomeKennel) {ken.isHomeKennel = kennel.isHomeKennel;}
        // if (ken.isMember != kennel.isMember) {ken.isMember = kennel.isMember;}
      } else {
        _kennelMembersList.add(member);
      }
    } else {
      _kennelMembersList.add(member);
    }
  }

  Future<dynamic> _getKennelMembers(String kennelId) async {

    final String userId = Preferences.getStringPref(StringPrefsEnum.userId);

    final String accessToken = Utilities.generateToken(
        userId.toUpperCase(), 'getKennelMembers');

    final String body = jsonEncode(<String, Object>{
      'userId': userId,
      'accessToken': accessToken,
      'kennelId': kennelId,
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'get_kennel_members',
            headers: <String, String>{'content-type': 'application/json'},
            body: body
            )
        .catchError(
      (dynamic error) {
        return false;
      },
    );

    return json.decode(response.body);
  }

  Future<void> getKennelMembersFromBackend(
      int pageIndex, bool showLoadingIndicator, String kennelId) async {
    if ((pageIndex == 1) && showLoadingIndicator) {
      _isLoading = true;
      notifyListeners();
    }

    final dynamic dataFromResponse = await _getKennelMembers(kennelId);

    dataFromResponse.forEach(
      (dynamic item) {
        //parse new kennel's details
        final GetKennelMembersModel kennelMember = GetKennelMembersModel(
            hasherId: item['hasherId'],
            hashName: item['hashName'],
            firstName: item['firstName'],
            lastName: item['lastName'],
            displayName: item['displayName'],
            dispPref: item['dispPref'],
            photo: item['photo'],
        );

        addEditKennelMemberList(kennelMember);
      },
    );

    if (pageIndex == 1) {
      _isLoading = false;
    }

    notifyListeners();

    return null;
  }
}
