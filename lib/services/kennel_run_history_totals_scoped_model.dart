import 'dart:async';
import 'dart:convert';

import 'package:harrier_central/data_models/kennel_run_history_totals_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';

import 'package:http/http.dart' as http;
import 'package:scoped_model/scoped_model.dart';

class KennelRunHistoryTotalsScopedModel extends Model {

  final List<KennelRunHistoryTotals> _kennelRunCountList = <KennelRunHistoryTotals>[];
  List<KennelRunHistoryTotals> get kennelRunCountList => _kennelRunCountList;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void addEditKennelList(KennelRunHistoryTotals kennel) {
    if (_kennelRunCountList.isNotEmpty) {
      final KennelRunHistoryTotals ken = _kennelRunCountList.firstWhere(
          (KennelRunHistoryTotals k) => k.kennelId == kennel.kennelId,
          orElse: () => null);
      if (ken != null) {
        // add fields here that might have been updated
        if (ken.following != kennel.following) {
          ken.following = kennel.following;
        }

        //if (ken.kennelName != kennel.kennelName) {ken.kennelName = kennel.kennelName;}
        //if (ken.kennelShortName != kennel.kennelShortName) {ken.kennelShortName = kennel.kennelShortName;}
        //if (ken.locationName != kennel.locationName) {ken.locationName = kennel.locationName;}
        if (ken.totalHaringThisKennel != kennel.totalHaringThisKennel) {
          ken.totalHaringThisKennel = kennel.totalHaringThisKennel;
        }
        if (ken.totalPackRunsThisKennel != kennel.totalPackRunsThisKennel) {
          ken.totalPackRunsThisKennel = kennel.totalPackRunsThisKennel;
        }

        if (ken.totalRunsThisKennel != kennel.totalRunsThisKennel) {
          ken.totalRunsThisKennel = kennel.totalRunsThisKennel;
        }
      } else {
        _kennelRunCountList.add(kennel);
      }
    } else {
      _kennelRunCountList.add(kennel);
    }
  }

  void clearKennelList() {
    _kennelRunCountList.clear();
  }

  int getKennelsCount() {
    return _kennelRunCountList.length;
  }


  Future<void> getKennelsFromBackend(
      bool showLoadingIndicator) async {
    if (showLoadingIndicator) {
      _isLoading = true;
      notifyListeners();
    }

    final String userId = getStringPref(StringPrefsEnum.userId);

    final String accessToken =
        Utilities.generateToken(userId.toUpperCase(), 'getMyKennelRunTotals');

    final String body = jsonEncode(<String,Object>{
      'userId': userId,
      'accessToken': accessToken,
      'kennelId': '00000000-0000-0000-0000-000000000000'
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'get_my_kennel_run_totals',
            headers: <String,String>{'content-type': 'application/json'}, body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return false;
      },
    );

    final List<KennelRunHistoryTotals> items = KennelRunHistoryTotals.itemsFromJson(response.body);

    for (int i = 0; i < items.length; i++)
    {
      addEditKennelList(items[i]);
    }

    _isLoading = false;

    notifyListeners();

  }
}
