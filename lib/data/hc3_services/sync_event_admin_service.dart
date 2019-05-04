import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/data/hc3_services/narrow_event_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_event_map_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';
import 'package:harrier_central/data/hc3_services/payments_service.dart';
import 'package:harrier_central/data/hc3_services/receipts_service.dart';

class SyncEventAdminService {
  static const int flagHasherEventMapTable = 0x00000001;
  static const int flagHasherKennelMapTable = 0x00000002;
  static const int flagNarrowEventsTable = 0x00000004;
  static const int flagPaymentsTable = 0x00000008;
  static const int flagReceiptsTable = 0x00000010;

  static const int flagsAllData = 0x0000001f;

  num _hasherEventMapLastUpdated;
  num _hasherKennelMapLastUpdated;
  num _narrowEventsLastUpdated;
  num _paymentsLastUpdated;
  num _receiptsLastUpdated;

  Future<num> getLastUpdatedTime(Database db, String colName, String tableName) async {
    final List<Map<String, dynamic>> table = await db.rawQuery('SELECT MAX($colName) AS maxDate FROM $tableName');
    final num timeValue = table.first['maxDate'];
    print(timeValue.toString());
    return timeValue;
  }

  Future<void> getLastUpdatedTimes(Database db, int flags) async {
    _hasherEventMapLastUpdated = (flags & flagHasherEventMapTable) == 0 ? 0 : await getLastUpdatedTime(db, HasherEventMapTableHelper.colUpdatedAtValue, HasherEventMapTableHelper.getTableName(HasherEventMapTableType.admin));
    _hasherKennelMapLastUpdated = (flags & flagHasherKennelMapTable) == 0 ? 0 : await getLastUpdatedTime(db, HasherKennelMapTableHelper.colUpdatedAtValue, HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.admin));
    _narrowEventsLastUpdated = (flags & flagNarrowEventsTable) == 0 ? 0 : await getLastUpdatedTime(db, NarrowEventsTableHelper.colUpdatedAtValue, NarrowEventsTableHelper.tableName);
    _paymentsLastUpdated = (flags & flagPaymentsTable) == 0 ? 0 : await getLastUpdatedTime(db, PaymentsTableHelper.colUpdatedAtValue, PaymentsTableHelper.tableName);
    _receiptsLastUpdated = (flags & flagReceiptsTable) == 0 ? 0 : await getLastUpdatedTime(db, ReceiptsTableHelper.colUpdatedAtValue, ReceiptsTableHelper.tableName);
  }

  Future<bool> updateFromBackend(Database db, int flags, bool forceRefresh, String eventId, {Function informUser}) async {
    if (getStringPref(StringPrefsEnum.adminEventId) != eventId) {
      final PaymentsService paySrv = PaymentsService();
      final HasherEventMapService hem2srv = HasherEventMapService();
      final HasherKennelMapService hkm2srv = HasherKennelMapService();
      final ReceiptsService recSrv = ReceiptsService();

      paySrv.clearTable();
      hem2srv.clearTable(HasherEventMapTableType.admin);
      hkm2srv.clearTable(HasherKennelMapTableType.admin);
      recSrv.clearTable();

      await setStringPref(StringPrefsEnum.adminEventId, eventId);
    }

    final int hasherEventMapLastUpdate = (flags & flagHasherEventMapTable) == 0 ? null : getIntPref(HasherEventMapTableHelper.getLastUpdatedKey(HasherEventMapTableType.admin)) ?? 0;
    final int hasherKennelMapLastUpdate = (flags & flagHasherKennelMapTable) == 0 ? null : getIntPref(HasherKennelMapTableHelper.getLastUpdatedKey(HasherKennelMapTableType.admin)) ?? 0;
    final int narrowEventsLastUpdate = (flags & flagNarrowEventsTable) == 0 ? null : getIntPref(NarrowEventsTableHelper.lastUpdatedKey) ?? 0;
    final int paymentsLastUpdate = (flags & flagReceiptsTable) == 0 ? null : getIntPref(PaymentsTableHelper.lastUpdatedKey) ?? 0;
    final int receiptsLastUpdate = (flags & flagReceiptsTable) == 0 ? null : getIntPref(ReceiptsTableHelper.lastUpdatedKey) ?? 0;

    if (forceRefresh ||
        ((paymentsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - paymentsLastUpdate) > PaymentsTableHelper.forceRequeryInterval) ||
        ((receiptsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - receiptsLastUpdate) > ReceiptsTableHelper.forceRequeryInterval) ||
        ((hasherEventMapLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - hasherEventMapLastUpdate) > HasherEventMapTableHelper.forceRequeryInterval) ||
        ((hasherKennelMapLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - hasherKennelMapLastUpdate) > HasherKennelMapTableHelper.forceRequeryInterval) ||
        ((narrowEventsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - narrowEventsLastUpdate) > NarrowEventsTableHelper.forceRequeryInterval)) {
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

      final DateTime hasherEventMapUpdatedAfter = _hasherEventMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherEventMapLastUpdated + 1000);
      final DateTime hasherKennelMapUpdatedAfter = _hasherKennelMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);
      final DateTime narrowEventsUpdatedAfter = _narrowEventsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_narrowEventsLastUpdated + 1000);
      final DateTime paymentsUpdatedAfter = _paymentsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_paymentsLastUpdated + 1000);
      final DateTime receiptsUpdatedAfter = _receiptsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_receiptsLastUpdated + 1000);

      String userId = getStringPref(StringPrefsEnum.userId);
      if ((userId ?? '').isEmpty) {
        userId = GUID_EMPTY;
      }

      final String accessToken = Utilities.generateToken(userId, 'syncEventAdminData');

      final String body = jsonEncode(<String, String>{
        'userId': userId,
        'accessToken': accessToken,
        'eventId': eventId,
        'hasherEventMapUpdatedAfter': (flags & flagHasherEventMapTable) == 0 ? 'ignore' : hasherEventMapUpdatedAfter.toString().substring(0, 19),
        'hasherKennelMapUpdatedAfter': (flags & flagHasherKennelMapTable) == 0 ? 'ignore' : hasherKennelMapUpdatedAfter.toString().substring(0, 19),
        'narrowEventsUpdatedAfter': (flags & flagNarrowEventsTable) == 0 ? 'ignore' : narrowEventsUpdatedAfter.toString().substring(0, 19),
        'paymentsUpdatedAfter': (flags & flagPaymentsTable) == 0 ? 'ignore' : paymentsUpdatedAfter.toString().substring(0, 19),
        'receiptsUpdatedAfter': (flags & flagReceiptsTable) == 0 ? 'ignore' : receiptsUpdatedAfter.toString().substring(0, 19),
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

      await processReturnRecords(response.body, db: db, informUser: informUser);
    }
    return true;
  }

  static Future<void> processReturnRecords(String jsonResults, {Database db,Function informUser}) async {
    
    db ??= await DBProvider.db.database;
    
    if (jsonResults.startsWith('[[')) {
      jsonResults = jsonResults.substring(1, jsonResults.length - 1);
    }

    final RegExp r = RegExp(r'\[(\{(.*?)\})\]', multiLine: true);
    final Iterable<Match> matches = r.allMatches(jsonResults);
    for (int i = 0; i < matches.length; i++) {
      final String ms = matches.elementAt(i).group(0);

      if (ms.startsWith(r'[{"paymentId"')) {
        final PaymentsService nSrv = PaymentsService();
        await nSrv.bulkUpdateDatabase('[$ms]', db, informUser);
        print('payments updated');
      }

      if (ms.startsWith(r'[{"receiptId"')) {
        final ReceiptsService kSrv = ReceiptsService();
        await kSrv.bulkUpdateDatabase('[$ms]', db, informUser);
        print('receipts updated');
      }

      if (ms.startsWith(r'[{"eventId"')) {
        final NarrowEventsService eSrv = NarrowEventsService();
        await eSrv.bulkUpdateDatabase('[$ms]', db, informUser);
        print('events updated');
      }

      if (ms.startsWith(r'[{"hemId"')) {
        final HasherEventMapService hemSrv = HasherEventMapService();
        await hemSrv.bulkUpdateDatabase('[$ms]', db, informUser, HasherEventMapTableType.admin);
        print('hasher event map for admin updated');
      }

      if (ms.startsWith(r'[{"hkmId"')) {
        final HasherKennelMapService hkmSrv = HasherKennelMapService();
        await hkmSrv.bulkUpdateDatabase('[$ms]', db, informUser, HasherKennelMapTableType.admin);
        print('hasher event map for admin updated');
      }
    }
  }
}
