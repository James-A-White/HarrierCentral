import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';
import 'package:harrier_central/data/hc3_services/hashers_service.dart';
import 'package:harrier_central/data/hc3_services/kennels_service.dart';

class SyncKennelAdminService {
  static const int flagKennelTable = 0x00000001;
  static const int flagHasherKennelMapTable = 0x00000002;
  static const int flagHashersTable = 0x00000004;

  static const int flagsAllData = 0x00000007;

  num _kennelLastUpdated;
  num _hasherKennelMapLastUpdated;
  num _hashersLastUpdated;

  Future<num> getLastUpdatedTime(Database db, String colName, String tableName) async {
    final List<Map<String, dynamic>> table = await db.rawQuery('SELECT MAX($colName) AS maxDate FROM $tableName');
    final num timeValue = table.first['maxDate'];
    print(timeValue.toString());
    return timeValue;
  }

  Future<void> getLastUpdatedTimes(Database db, int flags) async {
    _kennelLastUpdated = (flags & flagKennelTable) == 0 ? 0 : await getLastUpdatedTime(db, KennelsTableHelper.colUpdatedAtValue, KennelsTableHelper.tableName);
    _hashersLastUpdated = (flags & flagHashersTable) == 0 ? 0 : await getLastUpdatedTime(db, HashersTableHelper.colUpdatedAtValue, HashersTableHelper.tableName);
    _hasherKennelMapLastUpdated = (flags & flagHasherKennelMapTable) == 0 ? 0 : await getLastUpdatedTime(db, HasherKennelMapTableHelper.colUpdatedAtValue, HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.kennelAdmin));
  }

  Future<bool> updateFromBackend(Database db, int flags, bool forceRefresh, String kennelId, {Function informUser}) async {
    
    if (globalConnectionStatus == connectionStatus_notConnected)
    {
      return false;
    }
  
    if (getStringPref(StringPrefsEnum.adminKennelId) != kennelId) {
      final HasherKennelMapService hkm2srv = HasherKennelMapService();

      // NOTE: kennels and hashers are not cleared here because all kennels and all hashers are loaded all the time for all users
      hkm2srv.clearTable(HasherKennelMapTableType.kennelAdmin);

      await setStringPref(StringPrefsEnum.adminKennelId, kennelId);
    }

    final int kennelsLastUpdate = (flags & flagKennelTable) == 0 ? null : getIntPref(KennelsTableHelper.lastUpdatedKey) ?? 0;
    final int hashersLastUpdate = (flags & flagHashersTable) == 0 ? null : getIntPref(HashersTableHelper.lastUpdatedKey) ?? 0;
    final int hasherKennelMapLastUpdate = (flags & flagHasherKennelMapTable) == 0 ? null : getIntPref(HasherKennelMapTableHelper.getLastUpdatedKey(HasherKennelMapTableType.kennelAdmin)) ?? 0;

    if (forceRefresh ||
        ((kennelsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - kennelsLastUpdate) > KennelsTableHelper.forceRequeryInterval) ||
        ((hashersLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - hashersLastUpdate) > HashersTableHelper.forceRequeryInterval) ||
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

      final DateTime kennelsUpdatedAfter = _kennelLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_kennelLastUpdated + 1000);
      final DateTime hashersUpdatedAfter = _hashersLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hashersLastUpdated + 1000);
      final DateTime hasherKennelMapUpdatedAfter = _hasherKennelMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);

      String userId = getStringPref(StringPrefsEnum.userId);
      if ((userId ?? '').isEmpty) {
        userId = GUID_EMPTY;
      }

      final String accessToken = Utilities.generateToken(userId, 'syncKennelAdminData');

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

      await updateSqlTablesWithResultsFromBackendApiCall(response.body, db: db, informUser: informUser);
    }
    return true;
  }

  static Future<void> updateSqlTablesWithResultsFromBackendApiCall(String jsonResults, {Database db,Function informUser}) async {
    
    db ??= await DBProvider.db.database;
    
    if (jsonResults.startsWith('[[')) {
      jsonResults = jsonResults.substring(1, jsonResults.length - 1);
    }

    final RegExp r = RegExp(r'\[(\{(.*?)\})\]', multiLine: true);
    final Iterable<Match> matches = r.allMatches(jsonResults);
    for (int i = 0; i < matches.length; i++) {
      final String ms = matches.elementAt(i).group(0);

      if (ms.startsWith(r'[{"kennelId"')) {
        final KennelsService kSrv = KennelsService();
        await kSrv.bulkUpdateDatabase('[$ms]', db, informUser);
        print('kennels updated');
      }


      if (ms.startsWith(r'[{"hasherId"')) {
        final HashersService hSrv = HashersService();
        await hSrv.bulkUpdateDatabase('[$ms]', db, informUser);
        print('hashers updated');
      }

      if (ms.startsWith(r'[{"hkmId"')) {
        final HasherKennelMapService hkmSrv = HasherKennelMapService();
        await hkmSrv.bulkUpdateDatabase('[$ms]', db, informUser, HasherKennelMapTableType.kennelAdmin);
        print('hasher kennel map for kennel admin updated');
      }
    }
  }
}
