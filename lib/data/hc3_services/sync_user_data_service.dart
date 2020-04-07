import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:ive_flutter_core/base_service.dart';
import 'package:harrier_central/database/tables.dart';

class SyncUserDataService {
  static const int flagHashersTable = 0x00000001;
  static const int flagCitiesTable = 0x00000002;
  static const int flagRegionsTable = 0x00000004;
  static const int flagCountriesTable = 0x00000008;
  static const int flagKennelsTable = 0x00000010;
  static const int flagNarrowEventsTable = 0x00000020;
  static const int flagPaymentsTable = 0x00000040;

  static const int flagAllMasterDataWithoutHashers = 0x0000007E;
  static const int flagAllMasterData = 0x0000007F;

  static const int flagHasherKennelMapTable = 0x00010000;
  static const int flagHasherEventMapTable = 0x00020000;

  static const int flagsAllData = 0x0003007f;

  num _hashersLastUpdated;
  num _citiesLastUpdated;
  num _regionsLastUpdated;
  num _countriesLastUpdated;
  num _kennelsLastUpdated;
  num _paymentsLastUpdated;
  num _hasherKennelMapLastUpdated;
  num _hasherEventMapLastUpdated;
  num _narrowEventsLastUpdated;

  Future<num> getLastUpdatedTime(String colName, String tableName) async {
    final List<Map<String, dynamic>> table = await internalSqlDb.rawQuery('SELECT MAX($colName) AS maxDate FROM $tableName');
    final num timeValue = table.first['maxDate'];
    print(timeValue.toString());
    return timeValue;
  }

  Future<void> getLastUpdatedTimes(int flags) async {
    _hashersLastUpdated = (flags & flagHashersTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : await getLastUpdatedTime(hashersTableHelper.colUpdatedAtValue, hashersTableHelper.tableName);
    _citiesLastUpdated = (flags & flagCitiesTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : await getLastUpdatedTime(citiesTableHelper.colUpdatedAtValue, citiesTableHelper.tableName);
    _regionsLastUpdated = (flags & flagRegionsTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : await getLastUpdatedTime(regionsTableHelper.colUpdatedAtValue, regionsTableHelper.tableName);
    _countriesLastUpdated = (flags & flagCountriesTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : await getLastUpdatedTime(countriesTableHelper.colUpdatedAtValue, countriesTableHelper.tableName);
    _kennelsLastUpdated = (flags & flagKennelsTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : await getLastUpdatedTime(kennelsTableHelper.colUpdatedAtValue, kennelsTableHelper.tableName);
    _paymentsLastUpdated = (flags & flagPaymentsTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : await getLastUpdatedTime(paymentsTableHelper.colUpdatedAtValue, paymentsTableHelper.getTableName(TableType.paymentsUser));
    _hasherKennelMapLastUpdated = (flags & flagHasherKennelMapTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : await getLastUpdatedTime(hasherKennelMapTableHelper.colUpdatedAtValue, hasherKennelMapTableHelper.getTableName(TableType.hkmUser));
    _hasherEventMapLastUpdated = (flags & flagHasherEventMapTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : await getLastUpdatedTime(hasherEventMapTableHelper.colUpdatedAtValue, hasherEventMapTableHelper.getTableName(TableType.hemUser));
    _narrowEventsLastUpdated = (flags & flagNarrowEventsTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : await getLastUpdatedTime(eventsTableHelper.colUpdatedAtValue, eventsTableHelper.tableName);
  }

  Future<bool> updateFromBackend(int tablesToSync, bool forceRefresh, {Function informUser}) async {
    if (globalConnectionStatus == connectionStatus_notConnected) {
      return false;
    }

    // final int hashersLastUpdate = (tablesToSync & flagHashersTable) == 0 ? null : getIntPref(HashersTableHelper.lastUpdatedKey) ?? 0;
    // final int citiesLastUpdate = (tablesToSync & flagCitiesTable) == 0 ? null : getIntPref(CitiesTableHelper.lastUpdatedKey) ?? 0;
    // final int regionsLastUpdate = (tablesToSync & flagRegionsTable) == 0 ? null : getIntPref(RegionsTableHelper.lastUpdatedKey) ?? 0;
    // final int countriesLastUpdate = (tablesToSync & flagCountriesTable) == null ? 0 : getIntPref(CountriesTableHelper.lastUpdatedKey) ?? 0;
    // final int kennelsLastUpdate = (tablesToSync & flagKennelsTable) == 0 ? null : getIntPref(KennelsTableHelper.lastUpdatedKey) ?? 0;
    // final int hasherKennelMapLastUpdate = (tablesToSync & flagHasherKennelMapTable) == 0 ? null : getIntPref(HasherKennelMapTableHelper.getLastUpdatedKey(TableType.user)) ?? 0;
    // final int hasherEventMapLastUpdate = (tablesToSync & flagHasherEventMapTable) == 0 ? null : getIntPref(HasherEventMapTableHelper.getLastUpdatedKey(HasherEventMapTableType.user)) ?? 0;
    // final int narrowEventsLastUpdate = (tablesToSync & flagNarrowEventsTable) == 0 ? null : getIntPref(NarrowEventsTableHelper.lastUpdatedKey) ?? 0;

    if (forceRefresh || true)

    // ||
    // ((hashersLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - hashersLastUpdate) > HashersTableHelper.forceRequeryInterval) ||
    // ((citiesLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - citiesLastUpdate) > CitiesTableHelper.forceRequeryInterval) ||
    // ((regionsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - regionsLastUpdate) > RegionsTableHelper.forceRequeryInterval) ||
    // ((countriesLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - countriesLastUpdate) > CountriesTableHelper.forceRequeryInterval) ||
    // ((kennelsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - kennelsLastUpdate) > KennelsTableHelper.forceRequeryInterval) ||
    // ((hasherKennelMapLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - hasherKennelMapLastUpdate) > HasherKennelMapTableHelper.forceRequeryInterval) ||
    // ((hasherEventMapLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - hasherEventMapLastUpdate) > HasherEventMapTableHelper.forceRequeryInterval) ||
    // ((narrowEventsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - narrowEventsLastUpdate) > NarrowEventsTableHelper.forceRequeryInterval))

    {
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
      await getLastUpdatedTimes(tablesToSync);

      final DateTime hashersUpdatedAfter = _hashersLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_hashersLastUpdated + 1000);
      final DateTime citiesUpdatedAfter = _citiesLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_citiesLastUpdated + 1000);
      final DateTime regionsUpdatedAfter = _regionsLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_regionsLastUpdated + 1000);
      final DateTime countriesUpdatedAfter = _countriesLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_countriesLastUpdated + 1000);
      final DateTime kennelsUpdatedAfter = _kennelsLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_kennelsLastUpdated + 1000);
      final DateTime paymentsUpdatedAfter = _paymentsLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_paymentsLastUpdated + 1000);
      final DateTime hasherKennelMapUpdatedAfter = _hasherKennelMapLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);
      final DateTime hasherEventMapUpdatedAfter = _hasherEventMapLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_hasherEventMapLastUpdated + 1000);
      final DateTime narrowEventsUpdatedAfter = _narrowEventsLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_narrowEventsLastUpdated + 1000);

      String userId = getStringPref(StringPrefsEnum.userId);
      if ((userId ?? '').isEmpty) {
        userId = GUID_EMPTY;
      }

      final String accessToken = Utilities.generateToken(userId, 'syncUserData');

      final String body = jsonEncode(<String, String>{
        'userId': userId,
        'accessToken': accessToken,
        'hashersUpdatedAfter': (tablesToSync & flagCitiesTable) == 0 ? 'ignore' : hashersUpdatedAfter.toString().substring(0, 19),
        'citiesUpdatedAfter': (tablesToSync & flagCitiesTable) == 0 ? 'ignore' : citiesUpdatedAfter.toString().substring(0, 19),
        'regionsUpdatedAfter': (tablesToSync & flagRegionsTable) == 0 ? 'ignore' : regionsUpdatedAfter.toString().substring(0, 19),
        'countriesUpdatedAfter': (tablesToSync & flagCountriesTable) == 0 ? 'ignore' : countriesUpdatedAfter.toString().substring(0, 19),
        'kennelsUpdatedAfter': (tablesToSync & flagKennelsTable) == 0 ? 'ignore' : kennelsUpdatedAfter.toString().substring(0, 19),
        'hasherKennelMapUpdatedAfter': (tablesToSync & flagHasherKennelMapTable) == 0 ? 'ignore' : hasherKennelMapUpdatedAfter.toString().substring(0, 19),
        'hasherEventMapUpdatedAfter': (tablesToSync & flagHasherEventMapTable) == 0 ? 'ignore' : hasherEventMapUpdatedAfter.toString().substring(0, 19),
        'narrowEventsUpdatedAfter': (tablesToSync & flagNarrowEventsTable) == 0 ? 'ignore' : narrowEventsUpdatedAfter.toString().substring(0, 19),
        'paymentsUpdatedAfter': (tablesToSync & flagPaymentsTable) == 0 ? 'ignore' : paymentsUpdatedAfter.toString().substring(0, 19),
      });

      final http.Response response = await http
          .post(BASE_API_URL + 'hc3_sync_user_data', headers: <String, String>{'content-type': 'application/json'}, body: body
              // Send authorization headers to your backend
              //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
              )
          .catchError(
        (dynamic error) {
          return false;
        },
      );

      await updateSqlTablesWithResultsFromBackendApiCall(response.body, informUser: informUser);
      await setIntPref(IntPrefsEnum.lastSuccessfulUserDataSync, DateTime.now().millisecondsSinceEpoch);
    }
    return true;
  }

  static Future<List<dynamic>> updateSqlTablesWithResultsFromBackendApiCall(String jsonResults, {Function informUser}) async {
    List<dynamic> adHocData;

    if (jsonResults.startsWith('[[')) {
      jsonResults = jsonResults.substring(1, jsonResults.length - 1);
    }

    final RegExp r = RegExp(r'\[(\{(.*?)\})\]', multiLine: true);
    final Iterable<Match> matches = r.allMatches(jsonResults);
    for (int i = 0; i < matches.length; i++) {
      final String ms = matches.elementAt(i).group(0);

      if (ms.startsWith(r'[{"hasherId"')) {
        await hashersService.bulkUpdateDatabase(
          hashersTableHelper,
          Tables.getTableName(hashersTableHelper),
          '[$ms]',
          internalSqlDb,
          informUser: informUser,
        );
        print('hashers updated');
      }

      if (ms.startsWith(r'[{"paymentId"')) {
        await baseService.bulkUpdateDatabase(
          paymentsTableHelper,
          Tables.getTableName(paymentsTableHelper, tableType: TableType.paymentsUser),
          '[$ms]',
          internalSqlDb,
          informUser: informUser,
        );
        print('payments updated');
      }

      if (ms.startsWith(r'[{"cityId"')) {
        await baseService.bulkUpdateDatabase(
          citiesTableHelper,
          Tables.getTableName(citiesTableHelper),
          '[$ms]',
          internalSqlDb,
          informUser: informUser,
        );
        print('cities updated');
      }

      if (ms.startsWith(r'[{"regionId"')) {
        await baseService.bulkUpdateDatabase(
          regionsTableHelper,
          Tables.getTableName(regionsTableHelper),
          '[$ms]',
          internalSqlDb,
          informUser: informUser,
        );
        print('regions updated');
      }

      if (ms.startsWith(r'[{"countryId"')) {
        await baseService.bulkUpdateDatabase(
          countriesTableHelper,
          Tables.getTableName(countriesTableHelper),
          '[$ms]',
          internalSqlDb,
          informUser: informUser,
        );
        print('countries updated');
      }

      if (ms.startsWith(r'[{"kennelId"')) {
        await baseService.bulkUpdateDatabase(
          kennelsTableHelper,
          Tables.getTableName(kennelsTableHelper),
          '[$ms]',
          internalSqlDb,
          informUser: informUser,
        );
        print('kennels updated');
      }

      if (ms.startsWith(r'[{"eventId"')) {
        await baseService.bulkUpdateDatabase(
          eventsTableHelper,
          Tables.getTableName(eventsTableHelper),
          '[$ms]',
          internalSqlDb,
          informUser: informUser,
        );
        print('events updated');
      }

      if (ms.startsWith(r'[{"hkmId"')) {
        await baseService.bulkUpdateDatabase(
          hasherKennelMapTableHelper,
          Tables.getTableName(hasherKennelMapTableHelper, tableType: TableType.hkmUser),
          '[$ms]',
          internalSqlDb,
          informUser: informUser,
        );
        print('hasher kennel map updated');
      }

      if (ms.startsWith(r'[{"hemId"')) {
        await baseService.bulkUpdateDatabase(
          hasherEventMapTableHelper,
          Tables.getTableName(hasherEventMapTableHelper,tableType:TableType.hemUser ),
          '[$ms]',
          internalSqlDb,
          informUser: informUser,
        );
        print('hasher event map updated');
      }

      if (ms.startsWith(r'[{"adHocDataId"')) {
        final List<dynamic> adHocItems = jsonDecode('$ms');
        if ((adHocItems != null) && (adHocItems.isNotEmpty)) {
          adHocData = adHocItems;
        }
        print('server messages received');
      }
    }
    return adHocData;
  }
}
