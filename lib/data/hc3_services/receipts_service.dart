import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/util/preferences.dart';

class ReceiptsModel {
  ReceiptsModel(
      {
        
this.receiptId,
this.eventId,
this.receiptAmount,
this.costCategory,
this.dateUploaded,
this.imageUrl,
this.receiptShortDescription,
this.removed,
this.updatedAt
      
      });

final String receiptId;
final String eventId;
final num receiptAmount;
final int costCategory;
final DateTime dateUploaded;
final String imageUrl;
final String receiptShortDescription;
final int removed;
final DateTime updatedAt;

  static List<ReceiptsModel> itemsFromJson(String jsonResult) {
    final List<ReceiptsModel> items = <ReceiptsModel>[];

    ReceiptsModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = ReceiptsModel(
receiptId: jsonItem['receiptId'],
eventId: jsonItem['eventId'],
receiptAmount: jsonItem['receiptAmount'],
costCategory: jsonItem['costCategory'],
dateUploaded: DateTime.parse(
                jsonItem['dateUploaded'].toString().substring(0, 19)),
imageUrl: jsonItem['imageUrl'],
receiptShortDescription: jsonItem['receiptShortDescription'],

            updatedAt: DateTime.parse(
                jsonItem['updatedAt'].toString().substring(0, 19)),
            removed: jsonItem['removed']);

        items.add(item);
      },
    );

    if (items.isEmpty) {
      return null;
    }

    return items;
  }
}

class ReceiptssTableHelper {
  ReceiptssTableHelper._privateConstructor();

  static const String tableName = 'Receiptss';
  //static const num forceRequeryInterval = 1 * 86400000;
  static const num forceRequeryInterval = 1 * 1000;
  static const num cacheDuration = 365 *
      3 *
      86400000; // cause a force refresh of the cache every 3 years. This effectively prevents cache refreshes

  static const IntPrefsEnum lastUpdatedKey = IntPrefsEnum.lastUpdateReceiptsData;
  static const IntPrefsEnum lastCacheClearKey =
      IntPrefsEnum.lastCacheClearReceiptsData;

  static const String colId = 'id';
  static const String remoteDbId = 'receiptId';

  static const String colReceiptId= 'receiptId';
  static const String colEventId= 'eventId';
  static const String colReceiptAmount= 'receiptAmount';
  static const String colCostCategory= 'costCategory';
  static const String colDateUploaded= 'dateUploaded';
  static const String colImageUrl= 'imageUrl';
  static const String colReceiptShortDescription= 'receiptShortDescription';
  
  static const String colRemoved = 'removed';
  static const String colUpdatedAt = 'updatedAt';
  static const String colUpdatedAtValue = 'updatedAtValue';

  // make this a singleton class

  static final ReceiptssTableHelper instance =
      ReceiptssTableHelper._privateConstructor();

  // SQL code to create the database table
  static Future<dynamic> createTable(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colReceiptId TEXT NOT NULL,
            $colEventId TEXT NOT NULL,
            $colReceiptAmount NUM,
            $colCostCategory INT,
            $colDateUploaded TEXT,
            $colImageUrl TEXT,
            $colReceiptShortDescription TEXT,

            $colRemoved NUM,
            $colUpdatedAt TEXT,
            $colUpdatedAtValue NUM NULL
          )
          ''');

    await db.execute('CREATE INDEX idx_${tableName}_id ON $tableName($remoteDbId);');
    await db.execute(
        'CREATE INDEX idx_${tableName}_update_at_value ON $tableName($colUpdatedAtValue);');
  }


  static Map<String, dynamic> toMap(ReceiptsModel item) {
    final Map<String, dynamic> map = <String, dynamic>{

      ReceiptssTableHelper.colReceiptId: item.receiptId,
      ReceiptssTableHelper.colEventId: item.eventId,
      ReceiptssTableHelper.colReceiptAmount: item.receiptAmount,
      ReceiptssTableHelper.colCostCategory: item.costCategory,
      ReceiptssTableHelper.colDateUploaded: item.dateUploaded,
      ReceiptssTableHelper.colImageUrl: item.imageUrl,
      ReceiptssTableHelper.colReceiptShortDescription: item.receiptShortDescription,

      ReceiptssTableHelper.colUpdatedAt: item.updatedAt.toString(),
      ReceiptssTableHelper.colUpdatedAtValue:
          item.updatedAt.millisecondsSinceEpoch,
      ReceiptssTableHelper.colRemoved: item.removed
    };

    return map;
  }

  static ReceiptsModel fromMap(Map<String, dynamic> map) {
    final ReceiptsModel item = ReceiptsModel(

      receiptId: map[ReceiptssTableHelper.colReceiptId],
      eventId: map[ReceiptssTableHelper.colEventId],
      receiptAmount: map[ReceiptssTableHelper.colReceiptAmount],
      costCategory: map[ReceiptssTableHelper.colCostCategory],
      dateUploaded: DateTime.parse(
          map[ReceiptssTableHelper.colDateUploaded].toString().substring(0, 19)),
      imageUrl: map[ReceiptssTableHelper.colImageUrl],
      receiptShortDescription: map[ReceiptssTableHelper.colReceiptShortDescription],

      updatedAt: DateTime.parse(
          map[ReceiptssTableHelper.colUpdatedAt].toString().substring(0, 19)),
      removed: map[ReceiptssTableHelper.colRemoved],
    );

    return item;
  }
}

class ReceiptsService {

  Future<void> clearTable() async {
    final Database db = await DBProvider.db.database;
    await db
        .rawDelete('DELETE FROM ${ReceiptssTableHelper.tableName}')
        .then((void dummy) {
      setIntPref(ReceiptssTableHelper.lastCacheClearKey,
          DateTime.now().millisecondsSinceEpoch);
    });
  }

  Future<void> updateDatabase(List<ReceiptsModel> items) async {
    final Database db = await DBProvider.db.database;

    for (int i = 0; i < items?.length ?? 0; i++) {
      final Map<String, dynamic> row = ReceiptssTableHelper.toMap(items[i]);

      final List<Map<String, dynamic>> table = await db.rawQuery(
          'SELECT * FROM ${ReceiptssTableHelper.tableName} WHERE ${ReceiptssTableHelper.remoteDbId} = "${items[i].receiptId}"');
      if ((table == null) || (table.isEmpty)) {
        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.insert(ReceiptssTableHelper.tableName, row);
          print(result.toString() +
              ' inserted into to the ${ReceiptssTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        });
      } else {
        final String rowId = table.first['id'].toString();

        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await db.update(ReceiptssTableHelper.tableName, row,
              where: 'id = $rowId');
          print(result.toString() +
              ' update to the ${ReceiptssTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        });
      }
    }
  }

  Future<int> bulkUpdateDatabase(String rawResults, Database db, Function informUser) async {
    int updateCounter = 0;
    int insertCounter = 0;

    final List<dynamic> jsonResultSets = json.decode(rawResults);

    final int len = jsonResultSets.length;
    int lastPercentage = 0;

    print('Receipt records received from cloud = $len');

    for (int i = 0; i < jsonResultSets.length; i++) {
      final List<dynamic> jsonResults = jsonResultSets[i];

      for (int j = 0; j < jsonResults.length; j++) {
        final Map<String, dynamic> jsonItem = jsonResults[j];

        final int percentage = (100 * (j/jsonResults.length)).round();
        if ((percentage != lastPercentage) && (informUser != null))
        {
          lastPercentage =percentage;
          informUser('Loading event data\r\n$percentage% complete');   
        }

        jsonItem.addAll(<String, dynamic>{
          'updatedAtValue':
              DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19))
                  .millisecondsSinceEpoch,
        });

        final String query =
            'SELECT * FROM ${ReceiptssTableHelper.tableName} WHERE ${ReceiptssTableHelper.remoteDbId} = "${jsonItem['receiptId']}"';
        final List<Map<String, dynamic>> table = await db.rawQuery(query);

        if ((table == null) || (table.isEmpty)) {
          //print(table.length.toString());
          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.insert(ReceiptssTableHelper.tableName, jsonItem);
            insertCounter++;
            // print(result.toString() +
            //     ' inserted into to the ${ReceiptssTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        } else {
          final String rowId = table.first['id'].toString();

          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.update(ReceiptssTableHelper.tableName, jsonItem,
                where: 'id = $rowId');
            updateCounter++;
            // print(result.toString() +
            //     ' update to the ${ReceiptssTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        }
      }
    }

    print(
        '$insertCounter receipt records inserted, $updateCounter receipt records updated');
    return insertCounter;
  }
}
