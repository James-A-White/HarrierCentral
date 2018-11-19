import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:harrier_central/util/utilities.dart';

import 'package:harrier_central/data_models/kennel_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';

import 'package:geolocator/geolocator.dart';

class KennelScopedModel extends Model {

  final List<Kennel> _kennelsList = <Kennel>[];
  List<Kennel> get kennelsList => _kennelsList;


  bool _isLoading = true;

  bool get isLoading => _isLoading;

  void addEditKennelList(Kennel kennel) {
    if (_kennelsList.isNotEmpty) {
      final Kennel ken = _kennelsList.firstWhere(
          (Kennel k) => k.kennelId == kennel.kennelId,
          orElse: () => null);
      if (ken != null) {
        // add fields here that might have been updated
        if (ken.followingBool != kennel.followingBool) {
          ken.followingBool = kennel.followingBool;
        }
        //if (ken.kennelName != kennel.kennelName) {ken.kennelName = kennel.kennelName;}
        //if (ken.kennelShortName != kennel.kennelShortName) {ken.kennelShortName = kennel.kennelShortName;}
        //if (ken.locationName != kennel.locationName) {ken.locationName = kennel.locationName;}
        if (ken.isHomeKennel != kennel.isHomeKennel) {
          ken.isHomeKennel = kennel.isHomeKennel;
        }
        if (ken.isMember != kennel.isMember) {
          ken.isMember = kennel.isMember;
        }
      } else {
        _kennelsList.add(kennel);
      }
    } else {
      _kennelsList.add(kennel);
    }
  }

  void clearKennelList() {
    _kennelsList.clear();
  }

  int getKennelsCount() {
    return _kennelsList.length;
  }

  Future<void> toggleFollowing(Kennel kennel) async {
    kennel.followingRequested = kennel.followingBool + 1;
    if (kennel.followingRequested > 2) {
      kennel.followingRequested = 0;
    }

    notifyListeners();

    final String userId = Preferences.getStringPref(StringPrefsEnum.userId);

    final String accessToken =
        Utilities.generateToken(userId.toUpperCase(), 'joinKennel');

    final String body = jsonEncode(<String,Object>{
      'userId': userId,
      'accessToken': accessToken,
      'kennelId': kennel.kennelId,
      'targetUserId': userId,
      'isFollowing': kennel.followingRequested,
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'join_kennel',
            headers: <String,String>{'content-type': 'application/json'}, body: body)
        .catchError(
      (dynamic error) {
        return false;
      },
    );

    kennel.followingBool = kennel.followingRequested;
    kennel.followingRequested = null;

    notifyListeners();

    return json.decode(response.body);
  }

  Future<dynamic> _getKennelsByDistance(int distance) async {
    //TODO: Check to see if the app has permission to access location before trying to read it.

    final Position position = await Geolocator()
        .getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);

    double latitude = DEFAULT_LATITUDE;
    double longitude = DEFAULT_LONGITUDE;

    if (position != null) {
      latitude = position.latitude;
      longitude = position.longitude;
    }

    final String userId = Preferences.getStringPref(StringPrefsEnum.userId);

    final String accessToken =
        Utilities.generateToken(userId.toUpperCase(), 'getAllKennels');

    final String body = jsonEncode(<String,Object>{
      'userId': userId,
      'accessToken': accessToken,
      'userLatitude': latitude,
      'userLongitude': longitude,
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'get_all_kennels',
            headers: <String,String>{'content-type': 'application/json'}, body: body
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

  Future<void> getKennelsFromBackend(
      int pageIndex, bool showLoadingIndicator) async {
    if ((pageIndex == 1) && showLoadingIndicator) {
      _isLoading = true;
      notifyListeners();
    }

    final dynamic dataFromResponse = await _getKennelsByDistance(1000);

    dataFromResponse.forEach(
      (dynamic newKennel) {
        //parse new kennel's details
        final Kennel kennel = Kennel(
          kennelId: newKennel['kennelId'],
          distance: newKennel['distance'],
          following: newKennel['following'],
          followingBool: newKennel['followingBool'],
          kennelStatus: newKennel['kennelStatus'],
          kennelName: newKennel['kennelName'],
          kennelDescription: newKennel['kennelDescription'],
          cityId: newKennel['cityId'],
          kennelWebsiteUrl: newKennel['kennelWebsiteUrl'],
          kennelFacebookId: newKennel['kennelFacebookId'],
          kennelFacebookToken: newKennel['kennelFacebookToken'],
          kennelFacebookTokenUserId: newKennel['kennelFacebookTokenUserId'],
          autoImportFacebookEvents: newKennel['autoImportFacebookEvents'],
          importOnlyTaggedEvents: newKennel['importOnlyTaggedEvents'],
          facebookTagForImport: newKennel['facebookTagForImport'],
          defaultEventCurrencyType: newKennel['defaultEventCurrencyType'],
          defaultEventPriceForNonMembers:
              (newKennel['defaultEventPriceForNonMembers'] ?? 0).toDouble(),
          defaultEventPriceForMembers:
              (newKennel['defaultEventPriceForMembers'] ?? 0).toDouble(),
          //defaultRunStartTime: DateTime.parse(['defaultRunStartTime'] ?? '2000-01-01 19:00:00'),
          kennelShortName: newKennel['kennelShortName'],
          kennelLogo: newKennel['kennelLogo'],
          latitude: (newKennel['latitude'] ?? -1).toDouble(),
          longitude: (newKennel['longitude'] ?? -1).toDouble(),
          activeHaberdasheryItems: newKennel['activeHaberdasheryItems'] ?? 0,
          archiveHaberdasheryItems: newKennel['archiveHaberdasheryItems'] ?? 0,
          locationName: newKennel['locationName'],
          isMember: newKennel['isMember'] ?? 0,
          // mismanagementRoleFlags: newKennel['mismanagementRoleFlags'],
          // isHomeKennel: newKennel['isHomeKennel'],
          // authAllowCredit: newKennel['authAllowCredit'],
          // authCheckInAndOut: newKennel['authCheckInAndOut'],
          // authCustomLogo: newKennel['authCustomLogo'],
          // authCustomSongbook: newKennel['authCustomSongbook'],
          // authFacebookIntegration: newKennel['authFacebookIntegration'],
          // authHaberdashery: newKennel['authHaberdashery'],
          // authHareRaisingManagement: newKennel['authHareRaisingManagement'],
          // authMembersAllowed: newKennel['authMembersAllowed'],
          // authPromoteEvents: newKennel['authPromoteEvents'],
          // authPushNotifications: newKennel['authPushNotifications'],
          // authTrackPayments: newKennel['authTrackPayments'],
          // authWebsiteIntegration: newKennel['authWebsiteIntegration'],
          memberCount: newKennel['memberCount'] ?? 0,
        );

        addEditKennelList(kennel);
      },
    );

    if (pageIndex == 1) {
      _isLoading = false;
    }

    notifyListeners();

    return null;
  }
}
