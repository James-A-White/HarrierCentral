import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:scoped_model/scoped_model.dart';
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_td_service.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/data/models/kennel_model.dart';


class KennelScopedModel extends Model {

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> toggleFollowing(Kennel kennel) async {
    kennel.followingRequested = kennel.followingBool + 1;
    if (kennel.followingRequested > 2) {
      kennel.followingRequested = 0;
    }

    notifyListeners();

    final String userId = getStringPref(StringPrefsEnum.userId);

    final String accessToken = Utilities.generateToken(userId.toUpperCase(), 'joinKennel');

    final String body = jsonEncode(<String, Object>{
      'userId': userId,
      'accessToken': accessToken,
      'kennelId': kennel.kennelId,
      'targetUserId': userId,
      'isFollowing': kennel.followingRequested,
    });

    final http.Response response = await http.post(BASE_API_URL + 'join_kennel', headers: <String, String>{'content-type': 'application/json'}, body: body).catchError(
      (dynamic error) {
        return false;
      },
    );

    kennel.followingBool = kennel.followingRequested;
    kennel.followingRequested = null;

    notifyListeners();

    return json.decode(response.body);
  }

  Future<void> getKennelsFromBackend(bool showLoadingIndicator) async {
    if (showLoadingIndicator) {
      _isLoading = true;
      notifyListeners();
    }

    final Database db = await DBProvider.db.database;

    final HasherKennelMapTdService cSrv = HasherKennelMapTdService();
    final bool result = await cSrv.updateFromBackend(db, false);
    final String resultStr = result ? 'successfully' : 'unsuccessfully';
    print('Kennel user data synchronized $resultStr');

    _isLoading = false;

    notifyListeners();
  }
}
