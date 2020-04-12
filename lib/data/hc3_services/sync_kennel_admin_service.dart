import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:harrier_central/util/constants.dart';

import 'package:ive_flutter_core/util/core_utilities.dart';
import 'package:ive_flutter_core/util/connection.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/database/tables.dart';
import 'package:harrier_central/util/enums.dart';

class SyncKennelAdminService {
  static const int flagKennelTable = 0x00000001;
  static const int flagHasherKennelMapTable = 0x00000002;
  static const int flagHashersTable = 0x00000004;

  static const int flagsAllData = 0x00000007;

  num _kennelLastUpdated;
  num _hasherKennelMapLastUpdated;
  num _hashersLastUpdated;

  Future<num> getLastUpdatedTime(String colName, String tableName) async {
    final List<Map<String, dynamic>> table = await internalSqlDb.rawQuery('SELECT MAX($colName) AS maxDate FROM $tableName');
    final num timeValue = table.first['maxDate'];
    print(timeValue.toString());
    return timeValue;
  }

  Future<void> getLastUpdatedTimes(int flags) async {
    _kennelLastUpdated = (flags & flagKennelTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : await getLastUpdatedTime(kennelsTableHelper.colUpdatedAtValue, kennelsTableHelper.tableName);
    _hashersLastUpdated = (flags & flagHashersTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : await getLastUpdatedTime(hashersTableHelper.colUpdatedAtValue, hashersTableHelper.tableName);
    _hasherKennelMapLastUpdated = (flags & flagHasherKennelMapTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : await getLastUpdatedTime(hasherKennelMapTableHelper.colUpdatedAtValue, hasherKennelMapTableHelper.getTableName(TableType.hkmKennelAdmin));
  }

  Future<bool> updateFromBackend(int flags, bool forceRefresh, String kennelId, {Function informUser}) async {
    if (globalConnectionStatus == connectionStatus_notConnected) {
      return false;
    }

    if (getStringPref(StringPrefsEnum.adminKennelId) != kennelId) {
      // NOTE: kennels and hashers are not cleared here because all kennels and all hashers are loaded all the time for all users
      baseService.clearTable(
        internalSqlDb,
        hasherKennelMapTableHelper,
        Tables.getTableName(hasherKennelMapTableHelper, tableType: TableType.hkmKennelAdmin),
      );

      await setStringPref(StringPrefsEnum.adminKennelId, kennelId);
    }

    // final int kennelsLastUpdate = (flags & flagKennelTable) == 0 ? null : getIntPref(KennelsTableHelper.lastUpdatedKey) ?? 0;
    // final int hashersLastUpdate = (flags & flagHashersTable) == 0 ? null : getIntPref(HashersTableHelper.lastUpdatedKey) ?? 0;
    // final int hasherKennelMapLastUpdate = (flags & flagHasherKennelMapTable) == 0 ? null : getIntPref(HasherKennelMapTableHelper.getLastUpdatedKey(TableType.kennelAdmin)) ?? 0;

    if (forceRefresh || true)
    // ((kennelsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - kennelsLastUpdate) > KennelsTableHelper.forceRequeryInterval) ||
    // ((hashersLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - hashersLastUpdate) > HashersTableHelper.forceRequeryInterval) ||
    // ((hasherKennelMapLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - hasherKennelMapLastUpdate) > HasherKennelMapTableHelper.forceRequeryInterval)
    // )
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
      await getLastUpdatedTimes(flags);

      final DateTime kennelsUpdatedAfter = _kennelLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_kennelLastUpdated + 1000);
      final DateTime hashersUpdatedAfter = _hashersLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_hashersLastUpdated + 1000);
      final DateTime hasherKennelMapUpdatedAfter = _hasherKennelMapLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);

      String userId = getStringPref(StringPrefsEnum.userId);
      if ((userId ?? '').isEmpty) {
        userId = GUID_EMPTY;
      }

      final String accessToken = CoreUtilities.generateToken(userId, 'syncKennelAdminData');

      final String body = jsonEncode(<String, String>{
        'userId': userId,
        'accessToken': accessToken,
        'kennelId': kennelId,
        'hashersUpdatedAfter': (flags & flagHashersTable) == 0 ? 'ignore' : hashersUpdatedAfter.toString().substring(0, 19),
        'kennelsUpdatedAfter': (flags & flagKennelTable) == 0 ? 'ignore' : kennelsUpdatedAfter.toString().substring(0, 19),
        'hasherKennelMapUpdatedAfter': (flags & flagHasherKennelMapTable) == 0 ? 'ignore' : hasherKennelMapUpdatedAfter.toString().substring(0, 19),
      });

      final http.Response response = await http
          .post(BASE_API_URL + 'hc3_sync_kennel_admin_data', headers: <String, String>{'content-type': 'application/json'}, body: body
              // Send authorization headers to your backend
              //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
              )
          .catchError(
        (dynamic error) {
          return false;
        },
      );

      await updateSqlTablesWithResultsFromBackendApiCall(response.body, informUser: informUser);
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

      if (ms.startsWith(r'[{"hasherId"')) {
        await baseService.bulkUpdateDatabase(
          hashersTableHelper,
          Tables.getTableName(hashersTableHelper),
          '[$ms]',
          internalSqlDb,
          informUser: informUser,
        );
        print('hashers updated');
      }

      if (ms.startsWith(r'[{"hkmId"')) {
        await baseService.bulkUpdateDatabase(
          hasherKennelMapTableHelper,
          Tables.getTableName(hasherKennelMapTableHelper, tableType: TableType.hkmKennelAdmin),
          '[$ms]',
          internalSqlDb,
          informUser: informUser,
        );
        print('hasher kennel map for kennel admin updated');
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
