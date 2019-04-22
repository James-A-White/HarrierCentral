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
import 'package:harrier_central/data/hc3_services/hashers_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';

class SyncDataService {
  static const int flagHashersTable = 0x00000001;
  static const int flagCitiesTable = 0x00000002;
  static const int flagRegionsTable = 0x00000004;
  static const int flagCountriesTable = 0x00000008;
  static const int flagKennelsTable = 0x00000010;

  static const int flagAllMasterDataWithoutHashers = 0x0000001E;
  static const int flagAllMasterData = 0x0000001F;

  static const int flagHasherKennelMapTable = 0x00010000;

  num _hashersLastUpdated;
  num _citiesLastUpdated;
  num _regionsLastUpdated;
  num _countriesLastUpdated;
  num _kennelsLastUpdated;
  num _hasherKennelMapLastUpdated;

  Future<num> getLastUpdatedTime(Database db, String colName, String tableName) async {
    final List<Map<String, dynamic>> table = await db.rawQuery('SELECT MAX($colName) AS maxDate FROM $tableName');
    final num timeValue = table.first['maxDate'];
    print(timeValue.toString());
    return timeValue;
  }

  Future<void> getLastUpdatedTimes(Database db, int flags) async {
    _hashersLastUpdated = (flags & flagHashersTable) == 0 ? 0 : await getLastUpdatedTime(db, HashersTableHelper.colUpdatedAtValue, HashersTableHelper.tableName);
    _citiesLastUpdated = (flags & flagCitiesTable) == 0 ? 0 : await getLastUpdatedTime(db, CitiesTableHelper.colUpdatedAtValue, CitiesTableHelper.tableName);
    _regionsLastUpdated = (flags & flagRegionsTable) == 0 ? 0 : await getLastUpdatedTime(db, RegionsTableHelper.colUpdatedAtValue, RegionsTableHelper.tableName);
    _countriesLastUpdated = (flags & flagCountriesTable) == 0 ? 0 : await getLastUpdatedTime(db, CountriesTableHelper.colUpdatedAtValue, CountriesTableHelper.tableName);
    _kennelsLastUpdated = (flags & flagKennelsTable) == 0 ? 0 : await getLastUpdatedTime(db, KennelsTableHelper.colUpdatedAtValue, KennelsTableHelper.tableName);
    _hasherKennelMapLastUpdated = (flags & flagHasherKennelMapTable) == 0 ? 0 : await getLastUpdatedTime(db, HasherKennelMapTableHelper.colUpdatedAtValue, HasherKennelMapTableHelper.tableName);
  }

  Future<bool> updateFromBackend(Database db, int flags, bool forceRefresh) async {
    final int hashersLastUpdate = (flags & flagHashersTable) == 0 ? null : getIntPref(HashersTableHelper.lastUpdatedKey) ?? 0;
    final int citiesLastUpdate = (flags & flagCitiesTable) == 0 ? null : getIntPref(CitiesTableHelper.lastUpdatedKey) ?? 0;
    final int regionsLastUpdate = (flags & flagRegionsTable) == 0 ? null : getIntPref(RegionsTableHelper.lastUpdatedKey) ?? 0;
    final int countriesLastUpdate = (flags & flagCountriesTable) == null ? 0 : getIntPref(CountriesTableHelper.lastUpdatedKey) ?? 0;
    final int kennelsLastUpdate = (flags & flagKennelsTable) == 0 ? null : getIntPref(KennelsTableHelper.lastUpdatedKey) ?? 0;
    final int hasherKennelMapLastUpdate = (flags & flagHasherKennelMapTable) == 0 ? null : getIntPref(HasherKennelMapTableHelper.lastUpdatedKey) ?? 0;

    if (forceRefresh ||
        ((hashersLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - hashersLastUpdate) > HashersTableHelper.forceRequeryInterval) || 
        ((citiesLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - citiesLastUpdate) > CitiesTableHelper.forceRequeryInterval) || 
        ((regionsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - regionsLastUpdate) > RegionsTableHelper.forceRequeryInterval) ||
        ((countriesLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - countriesLastUpdate) > CountriesTableHelper.forceRequeryInterval) ||
        ((kennelsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - kennelsLastUpdate) > KennelsTableHelper.forceRequeryInterval) ||
        ((hasherKennelMapLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - hasherKennelMapLastUpdate) > HasherKennelMapTableHelper.forceRequeryInterval) 
        ) {
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
      await getLastUpdatedTimes(db, flags);

      final DateTime hashersUpdatedAfter = _hashersLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hashersLastUpdated + 1000);
      final DateTime citiesUpdatedAfter = _citiesLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_citiesLastUpdated + 1000);
      final DateTime regionsUpdatedAfter = _regionsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_regionsLastUpdated + 1000);
      final DateTime countriesUpdatedAfter = _countriesLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_countriesLastUpdated + 1000);
      final DateTime kennelsUpdatedAfter = _kennelsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_kennelsLastUpdated + 1000);
      final DateTime hasherKennelMapUpdatedAfter = _hasherKennelMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);

      String userId = getStringPref(StringPrefsEnum.userId);
      if ((userId ?? '').isEmpty) {
        userId = GUID_EMPTY;
      }

      final String accessToken = Utilities.generateToken(userId, 'syncData');

      final String body = jsonEncode(<String, String>{
        'userId': userId,
        'accessToken': accessToken,
        'hashersUpdatedAfter': (flags & flagCitiesTable) == 0 ? 'ignore' : hashersUpdatedAfter.toString().substring(0, 19),
        'citiesUpdatedAfter': (flags & flagCitiesTable) == 0 ? 'ignore' : citiesUpdatedAfter.toString().substring(0, 19),
        'regionsUpdatedAfter': (flags & flagRegionsTable) == 0 ? 'ignore' : regionsUpdatedAfter.toString().substring(0, 19),
        'countriesUpdatedAfter': (flags & flagCountriesTable) == 0 ? 'ignore' : countriesUpdatedAfter.toString().substring(0, 19),
        'kennelsUpdatedAfter': (flags & flagKennelsTable) == 0 ? 'ignore' : kennelsUpdatedAfter.toString().substring(0, 19),
        'hasherKennelMapUpdatedAfter': (flags & flagKennelsTable) == 0 ? 'ignore' : hasherKennelMapUpdatedAfter.toString().substring(0, 19),
      });

      final http.Response response = await http
          .post(BASE_API_URL + 'hc3_sync_data', headers: <String, String>{'content-type': 'application/json'}, body: body
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

        if (ms.startsWith(r'[{"hasherId"')) {
          final HashersService hSrv = HashersService();
          hSrv.bulkUpdateDatabase('[$ms]', db, null);
          print('hashers updated');
        }

        if (ms.startsWith(r'[{"cityId"')) {
          final CitiesService cSrv = CitiesService();
          cSrv.bulkUpdateDatabase('[$ms]', db, null);
          print('cities updated');
        }

        if (ms.startsWith(r'[{"regionId"')) {
          final RegionsService rSrv = RegionsService();
          rSrv.bulkUpdateDatabase('[$ms]', db, null);
          print('regions updated');
        }

        if (ms.startsWith(r'[{"countryId"')) {
          final CountriesService nSrv = CountriesService();
          nSrv.bulkUpdateDatabase('[$ms]', db, null);
          print('countries updated');
        }

        if (ms.startsWith(r'[{"kennelId"')) {
          final KennelsService kSrv = KennelsService();
          kSrv.bulkUpdateDatabase('[$ms]', db, null);
          print('kennels updated');
        }

        if (ms.startsWith(r'[{"hkmId"')) {
          final HasherKennelMapTdService hkmSrv = HasherKennelMapTdService();
          hkmSrv.bulkUpdateDatabase('[$ms]', db, null);
          print('hasher kennel map updated');
        }
      }
    }
    return true;
  }
}
