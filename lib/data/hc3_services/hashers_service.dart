import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/data/hc3_services/hasher_event_map_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';
import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/data/hc3_services/sync_event_admin_service.dart';
import 'package:harrier_central/data/hc3_services/sync_kennel_admin_service.dart';

class HashersModel {
  HashersModel({this.hasherId, this.homeKennelId, this.firstName, this.lastName, this.dispName, this.hashName, this.email, this.photo, this.dispPref, this.resetCode, this.qrCode, this.removed, this.updatedAt});

  final String hasherId;
  final String homeKennelId;
  String firstName;
  String lastName;
  String dispName;
  String hashName;
  String email;
  String photo;
  int dispPref;
  String resetCode;
  String qrCode;
  final int removed;
  final DateTime updatedAt;

  static List<HashersModel> itemsFromJson(String jsonResult) {
    final List<HashersModel> items = <HashersModel>[];

    HashersModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = HashersModel(
            hasherId: jsonItem['hasherId'],
            homeKennelId: jsonItem['homeKennelId'],
            firstName: jsonItem['firstName'],
            lastName: jsonItem['lastName'],
            dispName: jsonItem['dispName'],
            hashName: jsonItem['hashName'],
            email: jsonItem['email'],
            photo: jsonItem['photo'],
            dispPref: jsonItem['dispPref'],
            resetCode: jsonItem['resetCode'],
            qrCode: jsonItem['qrCode'],
            updatedAt: DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19)),
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

class HashersTableHelper {
  HashersTableHelper._privateConstructor();

  static const String tableName = 'hashers';
  //static const num forceRequeryInterval = 1 * 86400000;
  static const num forceRequeryInterval = 1 * 1000;
  static const num cacheDuration = 365 * 3 * 86400000; // cause a force refresh of the cache every 3 years. This effectively prevents cache refreshes

  static const IntPrefsEnum lastUpdatedKey = IntPrefsEnum.lastUpdateHashersData;
  static const IntPrefsEnum lastCacheClearKey = IntPrefsEnum.lastCacheClearHashersData;

  static const String colId = 'id';
  static const String remoteDbId = 'hasherId';

  static const String colHasherId = 'hasherId';
  static const String colHomeKennelId = 'homeKennelId';
  static const String colFirstName = 'firstName';
  static const String colLastName = 'lastName';
  static const String colDispName = 'dispName';
  static const String colHashName = 'hashName';
  static const String colEmail = 'email';
  static const String colPhoto = 'photo';
  static const String colDispPref = 'dispPref';
  static const String colResetCode = 'resetCode';
  static const String colQrCode = 'qrCode';

  static const String colRemoved = 'removed';
  static const String colUpdatedAt = 'updatedAt';
  static const String colUpdatedAtValue = 'updatedAtValue';

  // make this a singleton class

  static final HashersTableHelper instance = HashersTableHelper._privateConstructor();

  // SQL code to create the database table
  static Future<dynamic> createTable(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colHasherId TEXT NOT NULL,
            $colHomeKennelId TEXT,
            $colFirstName TEXT,
            $colLastName TEXT,
            $colDispName TEXT,
            $colHashName TEXT,
            $colEmail TEXT,
            $colPhoto TEXT,
            $colDispPref INT,
            $colResetCode TEXT,
            $colQrCode TEXT,

            $colRemoved NUM,
            $colUpdatedAt TEXT,
            $colUpdatedAtValue NUM NULL
          )
          ''');

    await db.execute('CREATE INDEX idx_${tableName}_id ON $tableName($remoteDbId);');
    await db.execute('CREATE INDEX idx_${tableName}_update_at_value ON $tableName($colUpdatedAtValue);');
  }

  static Map<String, dynamic> toMap(HashersModel item) {
    final Map<String, dynamic> map = <String, dynamic>{
      HashersTableHelper.colHasherId: item.hasherId,
      HashersTableHelper.colHomeKennelId: item.homeKennelId,
      HashersTableHelper.colFirstName: item.firstName,
      HashersTableHelper.colLastName: item.lastName,
      HashersTableHelper.colDispName: item.dispName,
      HashersTableHelper.colHashName: item.hashName,
      HashersTableHelper.colEmail: item.email,
      HashersTableHelper.colPhoto: item.photo,
      HashersTableHelper.colDispPref: item.dispPref,
      HashersTableHelper.colResetCode: item.resetCode,
      HashersTableHelper.colQrCode: item.qrCode,
      HashersTableHelper.colUpdatedAt: item.updatedAt.toString(),
      HashersTableHelper.colUpdatedAtValue: item.updatedAt.millisecondsSinceEpoch,
      HashersTableHelper.colRemoved: item.removed
    };

    return map;
  }

  static Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    final Map<String, dynamic> outputMap = <String, dynamic>{
      HashersTableHelper.colHasherId: inputMap[HashersTableHelper.colHasherId],
      HashersTableHelper.colHomeKennelId: inputMap[HashersTableHelper.colHomeKennelId],
      HashersTableHelper.colFirstName: inputMap[HashersTableHelper.colFirstName],
      HashersTableHelper.colLastName: inputMap[HashersTableHelper.colLastName],
      HashersTableHelper.colDispName: inputMap[HashersTableHelper.colDispName],
      HashersTableHelper.colHashName: inputMap[HashersTableHelper.colHashName],
      //HashersTableHelper.colEmail: inputMap[HashersTableHelper.colEmail],  // we don't pull eMail from the server for privacy reasons
      HashersTableHelper.colPhoto: inputMap[HashersTableHelper.colPhoto],
      HashersTableHelper.colDispPref: inputMap[HashersTableHelper.colDispPref],
      HashersTableHelper.colResetCode: inputMap[HashersTableHelper.colResetCode],
      HashersTableHelper.colQrCode: inputMap[HashersTableHelper.colQrCode],
      HashersTableHelper.colUpdatedAt: inputMap[HashersTableHelper.colUpdatedAt],
      HashersTableHelper.colUpdatedAtValue: DateTime.parse(inputMap[HashersTableHelper.colUpdatedAt].toString().substring(0, 19)).millisecondsSinceEpoch,
      HashersTableHelper.colRemoved: inputMap[HashersTableHelper.colRemoved],
    };

    return outputMap;
  }

  static HashersModel fromMap(Map<String, dynamic> map) {
    final HashersModel item = HashersModel(
      hasherId: map[HashersTableHelper.colHasherId],
      homeKennelId: map[HashersTableHelper.colHomeKennelId],
      firstName: map[HashersTableHelper.colFirstName],
      lastName: map[HashersTableHelper.colLastName],
      dispName: map[HashersTableHelper.colDispName],
      hashName: map[HashersTableHelper.colHashName],
      email: map[HashersTableHelper.colEmail],
      photo: map[HashersTableHelper.colPhoto],
      dispPref: map[HashersTableHelper.colDispPref],
      resetCode: map[HashersTableHelper.colResetCode],
      qrCode: map[HashersTableHelper.colQrCode],
      updatedAt: DateTime.parse(map[HashersTableHelper.colUpdatedAt].toString().substring(0, 19)),
      removed: map[HashersTableHelper.colRemoved],
    );

    return item;
  }
}

class HashersService {
  static final HashersTableHelper instance = HashersTableHelper._privateConstructor();

  static Future<num> getLastUpdatedTime() async {
    final Database db = await DBProvider.db.database;
    final List<Map<String, dynamic>> table = await db.rawQuery('SELECT MAX(${HashersTableHelper.colUpdatedAtValue}) AS maxDate FROM ${HashersTableHelper.tableName}');
    final num timeValue = table.first['maxDate'];
    return timeValue;
  }

  Future<List<HashersModel>> selectAllFromLocalDb() async {
    final Database db = await DBProvider.db.database;

    final List<Map<String, dynamic>> result = await db.query(HashersTableHelper.tableName);

    final List<HashersModel> records = <HashersModel>[];

    if ((result != null) && (result.isNotEmpty)) {
      for (int i = 0; i < result.length; i++) {
        if (result[i]['removed'] == 0) {
          final HashersModel record = HashersTableHelper.fromMap(result[i]);
          records.add(record);
        }
      }
    }
    return records;
  }

  Future<void> clearTable() async {
    final Database db = await DBProvider.db.database;
    await db.rawDelete('DELETE FROM ${HashersTableHelper.tableName}').then((void dummy) {
      setIntPref(HashersTableHelper.lastCacheClearKey, DateTime.now().millisecondsSinceEpoch);
    });
  }

  Future<void> updateDatabase(List<HashersModel> items) async {
    final Database db = await DBProvider.db.database;

    for (int i = 0; i < items?.length ?? 0; i++) {
      final Map<String, dynamic> row = HashersTableHelper.toMap(items[i]);

      final List<Map<String, dynamic>> table = await db.rawQuery('SELECT * FROM ${HashersTableHelper.tableName} WHERE ${HashersTableHelper.remoteDbId} = "${items[i].hasherId}"');
      if ((table == null) || (table.isEmpty)) {
        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.insert(HashersTableHelper.tableName, row);
          print(result.toString() + ' inserted into to the ${HashersTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        });
      } else {
        final String rowId = table.first['id'].toString();

        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.update(HashersTableHelper.tableName, row, where: 'id = $rowId');
          print(result.toString() + ' update to the ${HashersTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
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

    print('Hasher recordsets received from cloud = $len');

    for (int i = 0; i < jsonResultSets.length; i++) {
      final List<dynamic> jsonResults = jsonResultSets[i];

      for (int j = 0; j < jsonResults.length; j++) {
        final Map<String, dynamic> jsonItem = jsonResults[j];

        if (doNormalizeMap == null) {
          final Map<String, dynamic> testMap = HashersTableHelper.normalizeMap(jsonItem);
                    doNormalizeMap = (testMap.length - 1) != jsonItem.length;
          if (doNormalizeMap)
          {
            print('Normalize map called for ${HashersTableHelper.tableName}, # of fields on the wire = ${jsonItem.length}, # of fields in internal DB = ${testMap.length - 1}' );
          }
        }

        final int percentage = (100 * (j / jsonResults.length)).round();
        if ((percentage != lastPercentage) && (informUser != null)) {
          lastPercentage = percentage;
          informUser('Loading packs \r\n$percentage% complete');
        }

        jsonItem.addAll(<String, dynamic>{
          'updatedAtValue': DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19)).millisecondsSinceEpoch,
        });

        final String query = 'SELECT * FROM ${HashersTableHelper.tableName} WHERE ${HashersTableHelper.remoteDbId} = "${jsonItem['hasherId']}"';
        final List<Map<String, dynamic>> table = await db.rawQuery(query);

        if ((table == null) || (table.isEmpty)) {
          //print(table.length.toString());
          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.insert(HashersTableHelper.tableName, doNormalizeMap ? HashersTableHelper.normalizeMap(jsonItem) : jsonItem);
            insertCounter++;
            // print(result.toString() +
            //     ' inserted into to the ${HashersTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        } else {
          final String rowId = table.first['id'].toString();

          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.update(HashersTableHelper.tableName, doNormalizeMap ? HashersTableHelper.normalizeMap(jsonItem) : jsonItem, where: 'id = $rowId');
            updateCounter++;
            // print(result.toString() +
            //     ' update to the ${HashersTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        }
      }
    }

    print('$insertCounter hasher records inserted, $updateCounter hasher records updated');
    return insertCounter;
  }

  // ============ Functions go here =============

  Future<String> addEditUser({String targetUserId, String firstName, String lastName, String email, String hashName, String photo, String eventId, String kennelId, String historicalPackRunCount, String historicalHaringCount, bool historicalCountIsEstimate, int followKennelOnAddNewUser, int includeInGlobalHashDirectory = -1}) async {
    if (globalConnectionStatus == connectionStatus_notConnected) {
      return '';
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    bool newUserForThisDevice = false;

    final String hcVersion = getStringPref(StringPrefsEnum.harrierCentralVersion);
    String userId = getStringPref(StringPrefsEnum.userId);
    if ((userId == null) || (userId.isEmpty)) {
      userId = GUID_EMPTY;
      newUserForThisDevice = true;
    }

    final String accessToken = Utilities.generateToken(userId.toUpperCase(), 'addEditUser', paramString: targetUserId.toUpperCase());

    DateTime hashersUpdatedAfter;
    DateTime hasherEventMapUpdatedAfter;
    DateTime hasherKennelMapUpdatedAfter;

    if (!newUserForThisDevice) {
      final num _hashersLastUpdated = await HashersService.getLastUpdatedTime();
      hashersUpdatedAfter = _hashersLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hashersLastUpdated + 1000);

      final num _hasherEventMapLastUpdated = await HasherEventMapService.getLastUpdatedTime(HasherEventMapTableType.eventAdmin);
      hasherEventMapUpdatedAfter = _hasherEventMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherEventMapLastUpdated + 1000);

      final num _hasherKennelMapLastUpdated = await HasherKennelMapService.getLastUpdatedTime(((eventId != null) && (eventId.isNotEmpty) && (eventId != GUID_EMPTY)) ? HasherKennelMapTableType.eventAdmin : HasherKennelMapTableType.kennelAdmin);
      hasherKennelMapUpdatedAfter = _hasherKennelMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);
    } else {
      // do this to suppress any records being returned through the sync mechanism
      hashersUpdatedAfter = DateTime(2050, 1, 1);
      hasherEventMapUpdatedAfter = DateTime(2050, 1, 1);
    }

    final String body = jsonEncode(<String, String>{
      'userId': userId,
      'accessToken': accessToken,
      'hcVersion': hcVersion,
      'hashersUpdatedAfter': hashersUpdatedAfter.toString(),
      'hasherEventMapUpdatedAfter': ((eventId != null) && (eventId.isNotEmpty) && (eventId != GUID_EMPTY)) ? hasherEventMapUpdatedAfter.toString() : 'ignore',
      'hasherKennelMapUpdatedAfter': ((kennelId != null) && (kennelId.isNotEmpty) && (kennelId != GUID_EMPTY)) ? hasherKennelMapUpdatedAfter.toString() : 'ignore',
      'targetUserId': targetUserId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'hashName': hashName,
      'photo': photo,
      'includeInGlobalHashDirectory': includeInGlobalHashDirectory.toString(),
      'eventId': eventId,
      'kennelId': kennelId,
      'historicalPackRunCount': historicalPackRunCount,
      'historicalHaringCount': historicalHaringCount,
      'historicalCountIsEstimate': (historicalCountIsEstimate ?? false) ? '1' : '0',
      'followKennelOnAddNewUser': followKennelOnAddNewUser == null ? null : followKennelOnAddNewUser.toString()
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'hc3_add_edit_user', headers: <String, String>{'content-type': 'application/json'}, body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return false;
      },
    );

    if (!newUserForThisDevice) {
      if (((eventId == null) || (eventId == GUID_EMPTY)) && ((kennelId == null) || (kennelId == GUID_EMPTY))) {
        // we don't have either an eventId or a kennelId so all we need to do is update
        // the Hasher table
        await SyncUserDataService.updateSqlTablesWithResultsFromBackendApiCall(response.body);
      } else if ((eventId != null) && (eventId != GUID_EMPTY)) {
        // if we have an eventId we are definitely editing an event irrespective of whether or not
        // there is also a kennelId
        await SyncEventAdminService.updateSqlTablesWithResultsFromBackendApiCall(response.body);
      } else if ((kennelId != null) && (kennelId != GUID_EMPTY)) {
        // if we get here, we have a kennelId but no eventId, which means we are editing kennel members
        await SyncKennelAdminService.updateSqlTablesWithResultsFromBackendApiCall(response.body);
      } else {
        // TODO(James): handle this error, we should never arrive at this point in the code
      }
    }

    return response.body;
  }
}
