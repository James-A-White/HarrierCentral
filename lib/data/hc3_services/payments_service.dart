import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/util/preferences.dart';

class PaymentsModel {
  PaymentsModel(
      {
        
this.paymentId,
this.kennelId,
this.paidBy,
this.hemId,
this.eventId,
this.paidTo,
this.creditAmount,
this.debitAmount,
this.paidDate,
this.paymentType,
this.cancelledDate,
this.cancelledBy,
this.paymentReference,
this.notes,
this.removed,
this.updatedAt,
      
      });

final String paymentId;
final String kennelId;
final String paidBy;
final String hemId;
final String eventId;
final String paidTo;
final num creditAmount;
final num debitAmount;
final DateTime paidDate;
final int paymentType;
final DateTime cancelledDate;
final String cancelledBy;
final String paymentReference;
final String notes;
final int removed;
final DateTime updatedAt;

  static List<PaymentsModel> itemsFromJson(String jsonResult) {
    final List<PaymentsModel> items = <PaymentsModel>[];

    PaymentsModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = PaymentsModel(
          paymentId: jsonItem['paymentId'],
          kennelId: jsonItem['kennelId'],
          paidBy: jsonItem['paidBy'],
          hemId: jsonItem['hemId'],
          eventId: jsonItem['eventId'],
          paidTo: jsonItem['paidTo'],
          creditAmount: jsonItem['creditAmount'],
          debitAmount: jsonItem['debitAmount'],
          paidDate: DateTime.parse(
                jsonItem['paidDate'].toString().substring(0, 19)),
          paymentType: jsonItem['paymentType'],
          cancelledDate: DateTime.parse(
                jsonItem['cancelledDate'].toString().substring(0, 19)),
          cancelledBy: jsonItem['cancelledBy'],
          paymentReference: jsonItem['paymentReference'],
          notes: jsonItem['notes'],

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

class PaymentsTableHelper {
  PaymentsTableHelper._privateConstructor();

  static const String tableName = 'Payments';
  //static const num forceRequeryInterval = 1 * 86400000;
  static const num forceRequeryInterval = 1 * 1000;
  static const num cacheDuration = 365 *
      3 *
      86400000; // cause a force refresh of the cache every 3 years. This effectively prevents cache refreshes

  static const IntPrefsEnum lastUpdatedKey = IntPrefsEnum.lastUpdatePaymentsData;
  static const IntPrefsEnum lastCacheClearKey =
      IntPrefsEnum.lastCacheClearPaymentsData;

  static const String colId = 'id';
  static const String remoteDbId = 'paymentId';

static const String colPaymentId= 'paymentId';
static const String colKennelId= 'kennelId';
static const String colPaidBy= 'paidBy';
static const String colHemId= 'hemId';
static const String colEventId= 'eventId';
static const String colPaidTo= 'paidTo';
static const String colCreditAmount= 'creditAmount';
static const String colDebitAmount= 'debitAmount';
static const String colPaidDate= 'paidDate';
static const String colPaymentType= 'paymentType';
static const String colCancelledDate= 'cancelledDate';
static const String colCancelledBy= 'cancelledBy';
static const String colPaymentReference= 'paymentReference';
static const String colNotes= 'notes';
  
  static const String colRemoved = 'removed';
  static const String colUpdatedAt = 'updatedAt';
  static const String colUpdatedAtValue = 'updatedAtValue';

  // make this a singleton class

  static final PaymentsTableHelper instance =
      PaymentsTableHelper._privateConstructor();

  // SQL code to create the database table
  static Future<dynamic> createTable(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colPaymentId TEXT NOT NULL,
            $colKennelId TEXT NOT NULL,
            $colPaidBy TEXT NOT NULL,
            $colHemId TEXT NOT NULL,
            $colEventId TEXT NOT NULL,
            $colPaidTo TEXT NOT NULL,
            $colCreditAmount NUM,
            $colDebitAmount NUM,
            $colPaidDate TEXT,
            $colPaymentType INT,
            $colCancelledDate TEXT,
            $colCancelledBy TEXT,
            $colPaymentReference TEXT,
            $colNotes TEXT,

            $colRemoved INT,
            $colUpdatedAt TEXT,
            $colUpdatedAtValue NUM NULL
          )
          ''');

    await db.execute('CREATE INDEX idx_${tableName}_id ON $tableName($remoteDbId);');
    await db.execute(
        'CREATE INDEX idx_${tableName}_update_at_value ON $tableName($colUpdatedAtValue);');
  }


  static Map<String, dynamic> toMap(PaymentsModel item) {
    final Map<String, dynamic> map = <String, dynamic>{

      PaymentsTableHelper.colPaymentId: item.paymentId,
      PaymentsTableHelper.colKennelId: item.kennelId,
      PaymentsTableHelper.colPaidBy: item.paidBy,
      PaymentsTableHelper.colHemId: item.hemId,
      PaymentsTableHelper.colEventId: item.eventId,
      PaymentsTableHelper.colPaidTo: item.paidTo,
      PaymentsTableHelper.colCreditAmount: item.creditAmount,
      PaymentsTableHelper.colDebitAmount: item.debitAmount,
      PaymentsTableHelper.colPaidDate: item.paidDate.toString(),
      PaymentsTableHelper.colPaymentType: item.paymentType,
      PaymentsTableHelper.colCancelledDate: item.cancelledDate.toString(),
      PaymentsTableHelper.colCancelledBy: item.cancelledBy,
      PaymentsTableHelper.colPaymentReference: item.paymentReference,
      PaymentsTableHelper.colNotes: item.notes,

      PaymentsTableHelper.colUpdatedAt: item.updatedAt.toString(),
      PaymentsTableHelper.colUpdatedAtValue:
          item.updatedAt.millisecondsSinceEpoch,
      PaymentsTableHelper.colRemoved: item.removed
    };

    return map;
  }

  static PaymentsModel fromMap(Map<String, dynamic> map) {
    final PaymentsModel item = PaymentsModel(

      paymentId: map[PaymentsTableHelper.colPaymentId],
      kennelId: map[PaymentsTableHelper.colKennelId],
      paidBy: map[PaymentsTableHelper.colPaidBy],
      hemId: map[PaymentsTableHelper.colHemId],
      eventId: map[PaymentsTableHelper.colEventId],
      paidTo: map[PaymentsTableHelper.colPaidTo],
      creditAmount: map[PaymentsTableHelper.colCreditAmount],
      debitAmount: map[PaymentsTableHelper.colDebitAmount],
      paidDate: DateTime.parse(
          map[PaymentsTableHelper.colPaidDate].toString().substring(0, 19)),
      paymentType: map[PaymentsTableHelper.colPaymentType],
      cancelledDate: DateTime.parse(
          map[PaymentsTableHelper.colCancelledDate].toString().substring(0, 19)),
      cancelledBy: map[PaymentsTableHelper.colCancelledBy],
      paymentReference: map[PaymentsTableHelper.colPaymentReference],
      notes: map[PaymentsTableHelper.colNotes],

      updatedAt: DateTime.parse(
          map[PaymentsTableHelper.colUpdatedAt].toString().substring(0, 19)),
      removed: map[PaymentsTableHelper.colRemoved],
    );

    return item;
  }
}

class PaymentsService {

  Future<void> clearTable() async {
    final Database db = await DBProvider.db.database;
    await db
        .rawDelete('DELETE FROM ${PaymentsTableHelper.tableName}')
        .then((void dummy) {
      setIntPref(PaymentsTableHelper.lastCacheClearKey,
          DateTime.now().millisecondsSinceEpoch);
    });
  }

  Future<void> updateDatabase(List<PaymentsModel> items) async {
    final Database db = await DBProvider.db.database;

    for (int i = 0; i < items?.length ?? 0; i++) {
      final Map<String, dynamic> row = PaymentsTableHelper.toMap(items[i]);

      final List<Map<String, dynamic>> table = await db.rawQuery(
          'SELECT * FROM ${PaymentsTableHelper.tableName} WHERE ${PaymentsTableHelper.remoteDbId} = "${items[i].paymentId}"');
      if ((table == null) || (table.isEmpty)) {
        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.insert(PaymentsTableHelper.tableName, row);
          print(result.toString() +
              ' inserted into to the ${PaymentsTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        });
      } else {
        final String rowId = table.first['id'].toString();

        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.update(PaymentsTableHelper.tableName, row,
              where: 'id = $rowId');
          print(result.toString() +
              ' update to the ${PaymentsTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
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

    print('Payment records received from cloud = $len');

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
            'SELECT * FROM ${PaymentsTableHelper.tableName} WHERE ${PaymentsTableHelper.remoteDbId} = "${jsonItem['paymentId']}"';
        final List<Map<String, dynamic>> table = await db.rawQuery(query);

        if ((table == null) || (table.isEmpty)) {
          //print(table.length.toString());
          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.insert(PaymentsTableHelper.tableName, jsonItem);
            insertCounter++;
            // print(result.toString() +
            //     ' inserted into to the ${PaymentsTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        } else {
          final String rowId = table.first['id'].toString();

          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.update(PaymentsTableHelper.tableName, jsonItem,
                where: 'id = $rowId');
            updateCounter++;
            // print(result.toString() +
            //     ' update to the ${PaymentsTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        }
      }
    }

    print(
        '$insertCounter payment records inserted, $updateCounter payment records updated');
    return insertCounter;
  }
}
