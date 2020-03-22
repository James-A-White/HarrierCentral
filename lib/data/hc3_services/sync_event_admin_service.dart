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
import 'package:harrier_central/data/hc3_services/base_service.dart';

class SyncEventAdminService {
  static const int flagHasherEventMapTable = 0x00000001;
  static const int flagHasherKennelMapTable = 0x00000002;
  static const int flagNarrowEventsTable = 0x00000004;
  static const int flagPaymentsTable = 0x00000008;
  static const int flagReceiptsTable = 0x00000010;
  static const int flagHashersTable = 0x00000020;
  static const int flagKennelCreditTable = 0x00000040;

  static const int flagsAllData = 0x0000007f;

  num _hasherEventMapLastUpdated;
  num _hasherKennelMapLastUpdated;
  num _narrowEventsLastUpdated;
  num _paymentsLastUpdated;
  num _receiptsLastUpdated;
  num _hashersLastUpdated;
  num _kennelCreditsLastUpdated;

  Future<num> getLastUpdatedTime(Database db, String colName, String tableName) async {
    final List<Map<String, dynamic>> table = await db.rawQuery('SELECT MAX($colName) AS maxDate FROM $tableName');
    final num timeValue = table.first['maxDate'];
    print(timeValue.toString());
    return timeValue;
  }

  Future<void> getLastUpdatedTimes(Database db, int flags) async {
    _hasherEventMapLastUpdated = (flags & flagHasherEventMapTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP  : await getLastUpdatedTime(db, hasherEventMapTableHelper.colUpdatedAtValue, hasherEventMapTableHelper.getTableName(TableType.hemEventAdmin));
    _hasherKennelMapLastUpdated = (flags & flagHasherKennelMapTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP  : await getLastUpdatedTime(db, hasherKennelMapTableHelper.colUpdatedAtValue, hasherKennelMapTableHelper.getTableName(TableType.hkmEventAdmin));
    _narrowEventsLastUpdated = (flags & flagNarrowEventsTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP  : await getLastUpdatedTime(db, eventsTableHelper.colUpdatedAtValue, eventsTableHelper.tableName);
    _paymentsLastUpdated = (flags & flagPaymentsTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : await getLastUpdatedTime(db, paymentsTableHelper.colUpdatedAtValue, paymentsTableHelper.getTableName(TableType.paymentsEvent));
    _receiptsLastUpdated = (flags & flagReceiptsTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP  : await getLastUpdatedTime(db, receiptsTableHelper.colUpdatedAtValue, receiptsTableHelper.tableName);
    _hashersLastUpdated = (flags & flagHashersTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP  : await getLastUpdatedTime(db, hashersTableHelper.colUpdatedAtValue, hashersTableHelper.tableName);
    //_hashersLastUpdated = true ? IGNORE_REPLICATION_TIMESTAMP  : await getLastUpdatedTime(db, HashersTableHelper.colUpdatedAtValue, HashersTableHelper.tableName);
    _kennelCreditsLastUpdated = (flags & flagKennelCreditTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP  : await getLastUpdatedTime(db, kennelCreditsTableHelper.colUpdatedAtValue, kennelCreditsTableHelper.tableName);
  }

  Future<bool> updateFromBackend(Database db, int flags, bool forceRefresh, String eventId, {Function informUser}) async {
    if (globalConnectionStatus == connectionStatus_notConnected) {
      return false;
    }

    if (getStringPref(StringPrefsEnum.adminEventId) != eventId) {

      //final HashersService hSrv = HashersService();
      // narrowEvents is not included here because all events are loaded all the time for all hashers.
      // TODO(James): create separate events table for event management

      await baseService.clearTable(paymentsTableHelper,tableType: TableType.paymentsEvent);
      await baseService.clearTable(hasherEventMapTableHelper, tableType: TableType.hemEventAdmin);
      await baseService.clearTable(hasherKennelMapTableHelper, tableType: TableType.hkmEventAdmin);
      await baseService.clearTable(receiptsTableHelper);
      await baseService.clearTable(kennelCreditsTableHelper);
      // we don't want to clear the Hashers table since it is meant to be persistent and not tied to a single event

      await setStringPref(StringPrefsEnum.adminEventId, eventId);
    }

    // final int hasherEventMapLastUpdate = (flags & flagHasherEventMapTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : getIntPref(HasherEventMapTableHelper.getLastUpdatedKey(HasherEventMapTableType.eventAdmin)) ?? 0;
    // final int hasherKennelMapLastUpdate = (flags & flagHasherKennelMapTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : getIntPref(HasherKennelMapTableHelper.getLastUpdatedKey(TableType.eventAdmin)) ?? 0;
    // final int narrowEventsLastUpdate = (flags & flagNarrowEventsTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : getIntPref(NarrowEventsTableHelper.lastUpdatedKey) ?? 0;
    // final int paymentsLastUpdate = (flags & flagReceiptsTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : getIntPref(PaymentsTableHelper.lastUpdatedKey) ?? 0;
    // final int receiptsLastUpdate = (flags & flagReceiptsTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : getIntPref(ReceiptsTableHelper.lastUpdatedKey) ?? 0;
    // final int hashersLastUpdate = (flags & flagHashersTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : getIntPref(HashersTableHelper.lastUpdatedKey) ?? 0;
    // final int kennelCreditsLastUpdate = (flags & flagKennelCreditTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : getIntPref(KennelCreditsTableHelper.lastUpdatedKey) ?? 0;

    if (forceRefresh || true)
    // ((paymentsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - paymentsLastUpdate) > PaymentsTableHelper.forceRequeryInterval) ||
    // ((receiptsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - receiptsLastUpdate) > ReceiptsTableHelper.forceRequeryInterval) ||
    // ((hasherEventMapLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - hasherEventMapLastUpdate) > HasherEventMapTableHelper.forceRequeryInterval) ||
    // ((hasherKennelMapLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - hasherKennelMapLastUpdate) > HasherKennelMapTableHelper.forceRequeryInterval) ||
    // ((narrowEventsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - narrowEventsLastUpdate) > NarrowEventsTableHelper.forceRequeryInterval) ||
    // ((hashersLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - hashersLastUpdate) > HasherEventMapTableHelper.forceRequeryInterval) ||
    // ((kennelCreditsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - kennelCreditsLastUpdate) > KennelCreditsTableHelper.forceRequeryInterval)

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
      await getLastUpdatedTimes(db, flags);

      final DateTime hasherEventMapUpdatedAfter = _hasherEventMapLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_hasherEventMapLastUpdated + 1000);
      final DateTime hasherKennelMapUpdatedAfter = _hasherKennelMapLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);
      final DateTime narrowEventsUpdatedAfter = _narrowEventsLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_narrowEventsLastUpdated + 1000);
      final DateTime paymentsUpdatedAfter = _paymentsLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_paymentsLastUpdated + 1000);
      final DateTime receiptsUpdatedAfter = _receiptsLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_receiptsLastUpdated + 1000);
      final DateTime hashersUpdatedAfter = _hashersLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_hashersLastUpdated + 1000);
      final DateTime kennelCreditsUpdatedAfter = _kennelCreditsLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_kennelCreditsLastUpdated + 1000);

      String userId = getStringPref(StringPrefsEnum.userId);
      if ((userId ?? '').isEmpty) {
        userId = GUID_EMPTY;
      }

      final String accessToken = Utilities.generateToken(userId, 'syncEventAdminData');

      final String body = jsonEncode(<String, String>{
        'userId': userId,
        'accessToken': accessToken,
        'eventId': eventId,
        'hashersUpdatedAfter': (flags & flagHashersTable) == 0 ? 'ignore' : hashersUpdatedAfter.toString().substring(0, 19),
        'hasherEventMapUpdatedAfter': (flags & flagHasherEventMapTable) == 0 ? 'ignore' : hasherEventMapUpdatedAfter.toString().substring(0, 19),
        'hasherKennelMapUpdatedAfter': (flags & flagHasherKennelMapTable) == 0 ? 'ignore' : hasherKennelMapUpdatedAfter.toString().substring(0, 19),
        'narrowEventsUpdatedAfter': (flags & flagNarrowEventsTable) == 0 ? 'ignore' : narrowEventsUpdatedAfter.toString().substring(0, 19),
        'paymentsUpdatedAfter': (flags & flagPaymentsTable) == 0 ? 'ignore' : paymentsUpdatedAfter.toString().substring(0, 19),
        'receiptsUpdatedAfter': (flags & flagReceiptsTable) == 0 ? 'ignore' : receiptsUpdatedAfter.toString().substring(0, 19),
        'kennelCreditsUpdatedAfter': (flags & flagKennelCreditTable) == 0 ? 'ignore' : kennelCreditsUpdatedAfter.toString().substring(0, 19),
      });

      final http.Response response = await http
          .post(BASE_API_URL + 'hc3_sync_event_admin_data', headers: <String, String>{'content-type': 'application/json'}, body: body
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

  static Future<List<dynamic>> updateSqlTablesWithResultsFromBackendApiCall(String jsonResults, {Database db, Function informUser}) async {
    List<dynamic> adHocData;

    db ??= await DBProvider.db.database;

    if (jsonResults.startsWith('[[')) {
      jsonResults = jsonResults.substring(1, jsonResults.length - 1);
    }

    final RegExp r = RegExp(r'\[(\{(.*?)\})\]', multiLine: true);
    final Iterable<Match> matches = r.allMatches(jsonResults);
    for (int i = 0; i < matches.length; i++) {
      final String ms = matches.elementAt(i).group(0);

      if (ms.startsWith(r'[{"paymentId"')) {
        await baseService.bulkUpdateDatabase(paymentsTableHelper,'[$ms]', db, informUser, tableType: TableType.paymentsEvent);
        print('payments updated');
      }

      if (ms.startsWith(r'[{"hasherId"')) {
        await hashersService.bulkUpdateDatabase(hashersTableHelper,'[$ms]', db, informUser);
        print('hashers updated');
      }

      if (ms.startsWith(r'[{"receiptId"')) {
        await baseService.bulkUpdateDatabase(receiptsTableHelper,'[$ms]', db, informUser);
        print('receipts updated');
      }

      if (ms.startsWith(r'[{"eventId"')) {
        await baseService.bulkUpdateDatabase(eventsTableHelper,'[$ms]', db, informUser);
        print('events updated');
      }

      if (ms.startsWith(r'[{"hemId"')) {
        await baseService.bulkUpdateDatabase(hasherEventMapTableHelper,'[$ms]', db, informUser, tableType: TableType.hemEventAdmin);
        print('hasher event map for admin updated');
      }

      if (ms.startsWith(r'[{"hkmId"')) {
        await baseService.bulkUpdateDatabase(hasherKennelMapTableHelper,'[$ms]', db, informUser, tableType: TableType.hkmEventAdmin);
        print('hasher event map for admin updated');
      }

      if (ms.startsWith(r'[{"kennelCreditId"')) {
        await baseService.bulkUpdateDatabase(kennelCreditsTableHelper,'[$ms]', db, informUser);
        print('kennel credits updated');
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
