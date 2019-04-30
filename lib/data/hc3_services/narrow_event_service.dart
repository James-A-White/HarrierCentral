import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/util/preferences.dart';

class NarrowEventsModel {
  NarrowEventsModel(
      {this.eventId,
this.eventStartDatetime,
this.kennelId,
this.isVisible,
this.isCountedRun,
this.eventNumber,
this.eventName,
this.latitude,
this.longitude,
      this.removed,
      this.updatedAt});

final String eventId;
final DateTime eventStartDatetime;
final String kennelId;
final int isVisible;
final int isCountedRun;
final int eventNumber;
final String eventName;
final num latitude;
final num longitude;
  final int removed;
  final DateTime updatedAt;

  static List<NarrowEventsModel> itemsFromJson(String jsonResult) {
    final List<NarrowEventsModel> items = <NarrowEventsModel>[];

    NarrowEventsModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = NarrowEventsModel(
eventId: jsonItem['eventId'],
eventStartDatetime: jsonItem['eventStartDatetime'],
kennelId: jsonItem['kennelId'],
isVisible: jsonItem['isVisible'],
isCountedRun: jsonItem['isCountedRun'],
eventNumber: jsonItem['eventNumber'],
eventName: jsonItem['eventName'],
latitude: jsonItem['latitude'],
longitude: jsonItem['longitude'],

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

class NarrowEventsTableHelper {
  NarrowEventsTableHelper._privateConstructor();

  static const String tableName = 'narrowEvents';
  //static const num forceRequeryInterval = 1 * 86400000;
  static const num forceRequeryInterval = 1 * 1000;
  static const num cacheDuration = 365 *
      3 *
      86400000; // cause a force refresh of the cache every 3 years. This effectively prevents cache refreshes

  static const IntPrefsEnum lastUpdatedKey = IntPrefsEnum.lastUpdateNarrowEventsData;
  static const IntPrefsEnum lastCacheClearKey =
      IntPrefsEnum.lastCacheClearNarrowEventsData;

  static const String colId = 'id';
  static const String remoteDbId = 'eventId';

  static const String colEventId= 'eventId';
  static const String colEventStartDatetime= 'eventStartDatetime';
  static const String colKennelId= 'kennelId';
  static const String colIsVisible= 'isVisible';
  static const String colIsCountedRun= 'isCountedRun';
  static const String colEventNumber= 'eventNumber';
  static const String colEventName= 'eventName';
  static const String colLatitude= 'latitude';
  static const String colLongitude= 'longitude';
  
  static const String colRemoved = 'removed';
  static const String colUpdatedAt = 'updatedAt';
  static const String colUpdatedAtValue = 'updatedAtValue';

  // make this a singleton class

  static final NarrowEventsTableHelper instance =
      NarrowEventsTableHelper._privateConstructor();

  // SQL code to create the database table
  static Future<dynamic> createTable(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colEventId TEXT NOT NULL,
            $colEventStartDatetime TEXT,
            $colKennelId TEXT NOT NULL,
            $colIsVisible INT,
            $colIsCountedRun INT,
            $colEventNumber INT,
            $colEventName TEXT,
            $colLatitude NUM,
            $colLongitude NUM,

            $colRemoved NUM,
            $colUpdatedAt TEXT,
            $colUpdatedAtValue NUM NULL
          )
          ''');

    await db.execute('CREATE INDEX idx_${tableName}_id ON $tableName($remoteDbId);');
    await db.execute(
        'CREATE INDEX idx_${tableName}_update_at_value ON $tableName($colUpdatedAtValue);');
  }


  static Map<String, dynamic> toMap(NarrowEventsModel item) {
    final Map<String, dynamic> map = <String, dynamic>{

    NarrowEventsTableHelper.colEventId: item.eventId,
    NarrowEventsTableHelper.colEventStartDatetime: item.eventStartDatetime.toString(),
    NarrowEventsTableHelper.colKennelId: item.kennelId,
    NarrowEventsTableHelper.colIsVisible: item.isVisible,
    NarrowEventsTableHelper.colIsCountedRun: item.isCountedRun,
    NarrowEventsTableHelper.colEventNumber: item.eventNumber,
    NarrowEventsTableHelper.colEventName: item.eventName,
    NarrowEventsTableHelper.colLatitude: item.latitude,
    NarrowEventsTableHelper.colLongitude: item.longitude,

      NarrowEventsTableHelper.colUpdatedAt: item.updatedAt.toString(),
      NarrowEventsTableHelper.colUpdatedAtValue:
          item.updatedAt.millisecondsSinceEpoch,
      NarrowEventsTableHelper.colRemoved: item.removed
    };

    return map;
  }

  static NarrowEventsModel fromMap(Map<String, dynamic> map) {
    final NarrowEventsModel item = NarrowEventsModel(

      eventId: map[NarrowEventsTableHelper.colEventId],
      eventStartDatetime: DateTime.parse(
          map[NarrowEventsTableHelper.colEventStartDatetime].toString().substring(0, 19)),
      kennelId: map[NarrowEventsTableHelper.colKennelId],
      isVisible: map[NarrowEventsTableHelper.colIsVisible],
      isCountedRun: map[NarrowEventsTableHelper.colIsCountedRun],
      eventNumber: map[NarrowEventsTableHelper.colEventNumber],
      eventName: map[NarrowEventsTableHelper.colEventName],
      latitude: map[NarrowEventsTableHelper.colLatitude],
      longitude: map[NarrowEventsTableHelper.colLongitude],

      updatedAt: DateTime.parse(
          map[NarrowEventsTableHelper.colUpdatedAt].toString().substring(0, 19)),
      removed: map[NarrowEventsTableHelper.colRemoved],
    );

    return item;
  }
}

class NarrowEventsService {
  static final NarrowEventsTableHelper instance =
      NarrowEventsTableHelper._privateConstructor();

  Future<void> clearTable() async {
    final Database db = await DBProvider.db.database;
    await db
        .rawDelete('DELETE FROM ${NarrowEventsTableHelper.tableName}')
        .then((void dummy) {
      setIntPref(NarrowEventsTableHelper.lastCacheClearKey,
          DateTime.now().millisecondsSinceEpoch);
    });
  }

  Future<void> updateDatabase(List<NarrowEventsModel> items) async {
    final Database db = await DBProvider.db.database;

    for (int i = 0; i < items?.length ?? 0; i++) {
      final Map<String, dynamic> row = NarrowEventsTableHelper.toMap(items[i]);

      final List<Map<String, dynamic>> table = await db.rawQuery(
          'SELECT * FROM ${NarrowEventsTableHelper.tableName} WHERE ${NarrowEventsTableHelper.remoteDbId} = "${items[i].eventId}"');
      if ((table == null) || (table.isEmpty)) {
        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.insert(NarrowEventsTableHelper.tableName, row);
          print(result.toString() +
              ' inserted into to the ${NarrowEventsTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        });
      } else {
        final String rowId = table.first['id'].toString();

        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await db.update(NarrowEventsTableHelper.tableName, row,
              where: 'id = $rowId');
          print(result.toString() +
              ' update to the ${NarrowEventsTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
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

    print('Event records received from cloud = $len');

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
            'SELECT * FROM ${NarrowEventsTableHelper.tableName} WHERE ${NarrowEventsTableHelper.remoteDbId} = "${jsonItem['eventId']}"';
        final List<Map<String, dynamic>> table = await db.rawQuery(query);

        if ((table == null) || (table.isEmpty)) {
          //print(table.length.toString());
          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.insert(NarrowEventsTableHelper.tableName, jsonItem);
            insertCounter++;
            // print(result.toString() +
            //     ' inserted into to the ${NarrowEventsTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        } else {
          final String rowId = table.first['id'].toString();

          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.update(NarrowEventsTableHelper.tableName, jsonItem,
                where: 'id = $rowId');
            updateCounter++;
            // print(result.toString() +
            //     ' update to the ${NarrowEventsTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        }
      }
    }

    print(
        '$insertCounter event records inserted, $updateCounter event records updated');
    return insertCounter;
  }
}
