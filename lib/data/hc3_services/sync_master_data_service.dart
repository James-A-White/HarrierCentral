import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/data/hc3_services/cities_service.dart';
import 'package:harrier_central/data/hc3_services/regions_service.dart';
import 'package:harrier_central/data/hc3_services/countries_service.dart';
import 'package:harrier_central/data/hc3_services/kennels_service.dart';

class SyncMasterDataService {
  num _citiesLastUpdated;
  num _regionsLastUpdated;
  num _countriesLastUpdated;
  num _kennelsLastUpdated;

  Future<num> _getLastUpdatedTime(Database db, String colName, String tableName) async {
    final List<Map<String, dynamic>> table = await db.rawQuery('SELECT MAX($colName) AS maxDate FROM $tableName');
    final num timeValue = table.first['maxDate'];
    print(timeValue.toString());
    return timeValue;
  }

  Future<void> getLastUpdatedTimes(Database db) async {
    _citiesLastUpdated = await _getLastUpdatedTime(db, CitiesTableHelper.colUpdatedAtValue, CitiesTableHelper.tableName);
    _regionsLastUpdated = await _getLastUpdatedTime(db, RegionsTableHelper.colUpdatedAtValue, RegionsTableHelper.tableName);
    _countriesLastUpdated = await _getLastUpdatedTime(db, CountriesTableHelper.colUpdatedAtValue, CountriesTableHelper.tableName);
    _kennelsLastUpdated = await _getLastUpdatedTime(db, KennelsTableHelper.colUpdatedAtValue, KennelsTableHelper.tableName);
  }

  Future<bool> updateFromBackend(Database db, bool forceRefresh) async {
    final int citiesLastUpdate = getIntPref(CitiesTableHelper.lastUpdatedKey) ?? 0;
    final int regionsLastUpdate = getIntPref(RegionsTableHelper.lastUpdatedKey) ?? 0;
    final int countriesLastUpdate = getIntPref(CountriesTableHelper.lastUpdatedKey) ?? 0;
    final int kennelsLastUpdate = getIntPref(KennelsTableHelper.lastUpdatedKey) ?? 0;

    if (forceRefresh ||
        ((DateTime.now().millisecondsSinceEpoch - citiesLastUpdate) > CitiesTableHelper.forceRequeryInterval) ||
        ((DateTime.now().millisecondsSinceEpoch - regionsLastUpdate) > RegionsTableHelper.forceRequeryInterval) ||
        ((DateTime.now().millisecondsSinceEpoch - countriesLastUpdate) > CountriesTableHelper.forceRequeryInterval) ||
        ((DateTime.now().millisecondsSinceEpoch - kennelsLastUpdate) > KennelsTableHelper.forceRequeryInterval)) {
      // check to see if we need to clear the cache
      //int lastCacheClear = getIntPref(CitiesTableHelper.lastCacheClearKey);

      // if (lastCacheClear == null) {
      //   // if lastCacheClear is null that means we've never cleared the
      //   // cache. This happens on startup. So, go ahead and set the lastCacheClear
      //   // date to now and set lastCacheClear to now to prevent the
      //   // cache from clearing immediatly upon startup
      //   lastCacheClear = DateTime.now().millisecondsSinceEpoch;
      //   setIntPref(CitiesTableHelper.lastCacheClearKey,
      //       DateTime.now().millisecondsSinceEpoch);
      // }

      // if (lastCacheClear + CitiesTableHelper.cacheDuration <
      //     DateTime.now().millisecondsSinceEpoch) {
      //   print(
      //       'clearing ${CitiesTableHelper.tableName} cache @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
      //   await clearTable();
      // }

      // get the last updated time of any of the records in
      // the table and add one second to it
      await getLastUpdatedTimes(db);

      final DateTime citiesUpdatedAfter = _citiesLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_citiesLastUpdated + 1000);
      final DateTime regionsUpdatedAfter = _regionsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_regionsLastUpdated + 1000);
      final DateTime countriesUpdatedAfter = _countriesLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_countriesLastUpdated + 1000);
      final DateTime kennelsUpdatedAfter = _kennelsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_kennelsLastUpdated + 1000);

      String userId = getStringPref(StringPrefsEnum.userId);
      if ((userId ?? '').isEmpty) {
        userId = GUID_EMPTY;
      }

      final String accessToken = Utilities.generateToken(userId, 'syncMasterData');

      final String body = jsonEncode(<String, String>{
        'userId': userId,
        'accessToken': accessToken,
        'citiesUpdatedAfter': citiesUpdatedAfter.toString().substring(0, 19),
        'regionsUpdatedAfter': regionsUpdatedAfter.toString().substring(0, 19),
        'countriesUpdatedAfter': countriesUpdatedAfter.toString().substring(0, 19),
        'kennelsUpdatedAfter': kennelsUpdatedAfter.toString().substring(0, 19),
      });

      final http.Response response = await http
          .post(BASE_API_URL + 'hc3_sync_master_data', headers: <String, String>{'content-type': 'application/json'}, body: body
              // Send authorization headers to your backend
              //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
              )
          .catchError(
        (dynamic error) {
          return false;
        },
      );

      final String s = response.body.substring(1, response.body.length - 1);

      final RegExp r = RegExp(r'\[(.*?)\]', multiLine: true);
      final Iterable<Match> matches = r.allMatches(s);
      for (int i = 0; i < matches.length; i++) {
        final String ms = matches.elementAt(i).group(0);
        if (ms.startsWith(r'[{"cityId"')) {
          final CitiesService cSrv = CitiesService();
          cSrv.bulkUpdateDatabase('[$ms]', db, null);
        }

        if (ms.startsWith(r'[{"regionId"')) {
          final RegionsService rSrv = RegionsService();
          rSrv.bulkUpdateDatabase('[$ms]', db, null);
        }

        if (ms.startsWith(r'[{"countryId"')) {
          final CountriesService nSrv = CountriesService();
          nSrv.bulkUpdateDatabase('[$ms]', db, null);
        }

        if (ms.startsWith(r'[{"kennelId"')) {
          final KennelsService kSrv = KennelsService();
          kSrv.bulkUpdateDatabase('[$ms]', db, null);
        }
      }
    }
    return true;
  }
}
