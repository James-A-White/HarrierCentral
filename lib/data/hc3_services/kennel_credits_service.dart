import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/util/preferences.dart';

class KennelCreditsModel {
  KennelCreditsModel({
    this.kennelCreditId,
    this.userId,
    this.kennelId,
    this.currentBalance,
    this.balanceAsOfEventId,
    this.updatedAt,
    this.removed,
  });

  final String kennelCreditId;
  final String userId;
  final String kennelId;
  final num currentBalance;
  final String balanceAsOfEventId;
  final DateTime updatedAt;
  final int removed;

  static List<KennelCreditsModel> itemsFromJson(String jsonResult) {
    final List<KennelCreditsModel> items = <KennelCreditsModel>[];

    KennelCreditsModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = KennelCreditsModel(kennelCreditId: jsonItem['kennelCreditId'], userId: jsonItem['userId'], kennelId: jsonItem['kennelId'], currentBalance: jsonItem['currentBalance'], balanceAsOfEventId: jsonItem['balanceAsOfEventId'], updatedAt: jsonItem['updatedAt'], removed: jsonItem['removed']);

        items.add(item);
      },
    );

    if (items.isEmpty) {
      return null;
    }

    return items;
  }
}

class KennelCreditsTableHelper {
  KennelCreditsTableHelper._privateConstructor();

  static const String tableName = 'kennelCredits';
  //static const num forceRequeryInterval = 1 * 86400000;
  static const num forceRequeryInterval = 1 * 1000;
  static const num cacheDuration = 365 * 3 * 86400000; // cause a force refresh of the cache every 3 years. This effectively prevents cache refreshes

  static const IntPrefsEnum lastUpdatedKey = IntPrefsEnum.lastUpdateKennelCreditsData;
  static const IntPrefsEnum lastCacheClearKey = IntPrefsEnum.lastCacheClearKennelCreditsData;

  static const String colId = 'id';
  static const String remoteDbId = 'kennelCreditId';

  static const String colKennelCreditId = 'kennelCreditId';
  static const String colUserId = 'userId';
  static const String colKennelId = 'kennelId';
  static const String colCurrentBalance = 'currentBalance';
  static const String colBalanceAsOfEventId = 'balanceAsOfEventId';
  static const String colUpdatedAt = 'updatedAt';
  static const String colRemoved = 'removed';
  static const String colUpdatedAtValue = 'updatedAtValue';

  // make this a singleton class

  static final KennelCreditsTableHelper instance = KennelCreditsTableHelper._privateConstructor();

  // SQL code to create the database table
  static Future<dynamic> createTable(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colKennelCreditId TEXT,
            $colUserId TEXT,
            $colKennelId TEXT,
            $colCurrentBalance NUM,
            $colBalanceAsOfEventId TEXT,

            $colRemoved NUM,
            $colUpdatedAt TEXT,
            $colUpdatedAtValue NUM NULL
          )
          ''');

    await db.execute('CREATE INDEX idx_${tableName}_id ON $tableName($remoteDbId);');
    await db.execute('CREATE INDEX idx_${tableName}_update_at_value ON $tableName($colUpdatedAtValue);');
  }

  static Map<String, dynamic> toMap(KennelCreditsModel item) {
    final Map<String, dynamic> map = <String, dynamic>{
      KennelCreditsTableHelper.colKennelCreditId: item.kennelCreditId,
      KennelCreditsTableHelper.colUserId: item.userId,
      KennelCreditsTableHelper.colKennelId: item.kennelId,
      KennelCreditsTableHelper.colCurrentBalance: item.currentBalance,
      KennelCreditsTableHelper.colBalanceAsOfEventId: item.balanceAsOfEventId,
      KennelCreditsTableHelper.colUpdatedAt: item.updatedAt,
      KennelCreditsTableHelper.colRemoved: item.removed,
      KennelCreditsTableHelper.colUpdatedAtValue: item.updatedAt.millisecondsSinceEpoch,
    };

    return map;
  }

  static Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    final Map<String, dynamic> outputMap = <String, dynamic>{
      KennelCreditsTableHelper.colKennelCreditId: inputMap[KennelCreditsTableHelper.colKennelCreditId],
      KennelCreditsTableHelper.colUserId: inputMap[KennelCreditsTableHelper.colUserId],
      KennelCreditsTableHelper.colKennelId: inputMap[KennelCreditsTableHelper.colKennelId],
      KennelCreditsTableHelper.colCurrentBalance: inputMap[KennelCreditsTableHelper.colCurrentBalance],
      KennelCreditsTableHelper.colBalanceAsOfEventId: inputMap[KennelCreditsTableHelper.colBalanceAsOfEventId],
      KennelCreditsTableHelper.colUpdatedAt: inputMap[KennelCreditsTableHelper.colUpdatedAt],
      KennelCreditsTableHelper.colUpdatedAtValue: DateTime.parse(inputMap[KennelCreditsTableHelper.colUpdatedAt].toString().substring(0, 19)).millisecondsSinceEpoch,
      KennelCreditsTableHelper.colRemoved: inputMap[KennelCreditsTableHelper.colRemoved],
    };

    return outputMap;
  }

  static KennelCreditsModel fromMap(Map<String, dynamic> map) {
    final KennelCreditsModel item = KennelCreditsModel(
      kennelCreditId: map[KennelCreditsTableHelper.colKennelCreditId],
      userId: map[KennelCreditsTableHelper.colUserId],
      kennelId: map[KennelCreditsTableHelper.colKennelId],
      currentBalance: map[KennelCreditsTableHelper.colCurrentBalance],
      balanceAsOfEventId: map[KennelCreditsTableHelper.colBalanceAsOfEventId],
      updatedAt: DateTime.parse(map[KennelCreditsTableHelper.colUpdatedAt].toString().substring(0, 19)),
      removed: map[KennelCreditsTableHelper.colRemoved],
    );

    return item;
  }
}

class KennelCreditsService {
  static final KennelCreditsTableHelper instance = KennelCreditsTableHelper._privateConstructor();

  static Future<num> getLastUpdatedTime() async {
    final Database db = await DBProvider.db.database;
    final List<Map<String, dynamic>> table = await db.rawQuery('SELECT MAX(${KennelCreditsTableHelper.colUpdatedAtValue}) AS maxDate FROM ${KennelCreditsTableHelper.tableName}');
    final num timeValue = table.first['maxDate'];
    return timeValue;
  }

  Future<void> clearTable() async {
    final Database db = await DBProvider.db.database;
    await db.rawDelete('DELETE FROM ${KennelCreditsTableHelper.tableName}').then((void dummy) {
      setIntPref(KennelCreditsTableHelper.lastCacheClearKey, DateTime.now().millisecondsSinceEpoch);
    });
  }

  Future<void> updateDatabase(List<KennelCreditsModel> items) async {
    final Database db = await DBProvider.db.database;

    for (int i = 0; i < items?.length ?? 0; i++) {
      final Map<String, dynamic> row = KennelCreditsTableHelper.toMap(items[i]);

      final List<Map<String, dynamic>> table = await db.rawQuery('SELECT * FROM ${KennelCreditsTableHelper.tableName} WHERE ${KennelCreditsTableHelper.remoteDbId} = "${items[i].kennelCreditId}"');
      if ((table == null) || (table.isEmpty)) {
        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.insert(KennelCreditsTableHelper.tableName, row);
          print(result.toString() + ' inserted into to the ${KennelCreditsTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        });
      } else {
        final String rowId = table.first['id'].toString();

        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.update(KennelCreditsTableHelper.tableName, row, where: 'id = $rowId');
          print(result.toString() + ' update to the ${KennelCreditsTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        });
      }
    }
  }

  Future<int> bulkUpdateDatabase(String rawResults, Database db, Function informUser) async {
    int updateCounter = 0;
    int insertCounter = 0;

    bool doNormalizeMap;

    final List<dynamic> jsonResultSets = json.decode(rawResults);

    final int len = jsonResultSets.length;
    int lastPercentage = 0;

    print('Region recordsets received from cloud = $len');

    for (int i = 0; i < jsonResultSets.length; i++) {
      final List<dynamic> jsonResults = jsonResultSets[i];

      for (int j = 0; j < jsonResults.length; j++) {
        final Map<String, dynamic> jsonItem = jsonResults[j];

        if (doNormalizeMap == null) {
          final Map<String, dynamic> testMap = KennelCreditsTableHelper.normalizeMap(jsonItem);
                    doNormalizeMap = (testMap.length - 1) != jsonItem.length;
          if (doNormalizeMap)
          {
            print('Normalize map called for ${KennelCreditsTableHelper.tableName}, # of fields on the wire = ${jsonItem.length}, # of fields in internal DB = ${testMap.length - 1}' );
          }
        }

        final int percentage = (100 * (j / jsonResults.length)).round();
        if ((percentage != lastPercentage) && (informUser != null)) {
          lastPercentage = percentage;
          informUser('Loading region data\r\n$percentage% complete');
        }

        jsonItem.addAll(<String, dynamic>{
          'updatedAtValue': DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19)).millisecondsSinceEpoch,
        });

        final String query = 'SELECT * FROM ${KennelCreditsTableHelper.tableName} WHERE ${KennelCreditsTableHelper.remoteDbId} = "${jsonItem['kennelCreditId']}"';
        final List<Map<String, dynamic>> table = await db.rawQuery(query);

        if ((table == null) || (table.isEmpty)) {
          //print(table.length.toString());
          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.insert(KennelCreditsTableHelper.tableName, doNormalizeMap ? KennelCreditsTableHelper.normalizeMap(jsonItem) : jsonItem);
            insertCounter++;
            // print(result.toString() +
            //     ' inserted into to the ${KennelCreditsTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        } else {
          final String rowId = table.first['id'].toString();

          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.update(KennelCreditsTableHelper.tableName, doNormalizeMap ? KennelCreditsTableHelper.normalizeMap(jsonItem) : jsonItem, where: 'id = $rowId');
            updateCounter++;
            // print(result.toString() +
            //     ' update to the ${KennelCreditsTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        }
      }
    }

    print('$insertCounter kennel credit records inserted, $updateCounter kennel credit records updated');
    return insertCounter;
  }
}
