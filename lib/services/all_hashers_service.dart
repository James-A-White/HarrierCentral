import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory;

import 'package:http/http.dart' as http;
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/data_models/all_hasher_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';

class AllHasherSqlTableHelper {
  AllHasherSqlTableHelper._privateConstructor();

  static const String _databaseName = DB_NAME;
  static const int _databaseVersion = 1;

  static const String table = 'hashers';

  static const String colId = 'id';
  static const String colUserId = 'user_id';
  static const String colFirstName = 'first_name';
  static const String colLastName = 'last_name';
  static const String colDisplayName = 'display_name';
  static const String colHashName = 'hash_name';
  static const String colPhoto = 'photo';
  static const String colNameDisplayPref = 'name_display_pref';
  static const String colUpdatedAt = 'updated_at';
  static const String colUpdatedAtValue = 'updated_at_value';
  static const String colRemovedFlag = 'removed_flag';

  // make this a singleton class

  static final AllHasherSqlTableHelper instance =
      AllHasherSqlTableHelper._privateConstructor();

  // only have a single app-wide reference to the database
  static Database _database;
  Future<Database> get database async {
    if (_database != null) {
      return _database;
    }
    // lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database;
  }

  // this opens the database (and creates it if it doesn't exist)
  Future<Database> _initDatabase() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future<dynamic> _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $colId INTEGER PRIMARY KEY,
            $colUserId TEXT NOT NULL,
            $colFirstName TEXT,
            $colLastName TEXT,
            $colDisplayName TEXT,
            $colHashName TEXT,
            $colPhoto TEXT,
            $colNameDisplayPref NUM,
            $colUpdatedAt TEXT,
            $colUpdatedAtValue NUM,
            $colRemovedFlag NUM
          )
          ''');

    await db.execute('CREATE INDEX idx_user_id ON $table($colUserId);');
    await db.execute('CREATE INDEX idx_update_at_value ON $table($colUpdatedAtValue);');
  }

  static Map<String, dynamic> toMap(AllHasherListModel item) {
    final Map<String, dynamic> map = <String, dynamic>{
      AllHasherSqlTableHelper.colUserId: item.userId,
      AllHasherSqlTableHelper.colFirstName: item.firstName,
      AllHasherSqlTableHelper.colLastName: item.lastName,
      AllHasherSqlTableHelper.colDisplayName: item.displayName,
      AllHasherSqlTableHelper.colHashName: item.hashName,
      AllHasherSqlTableHelper.colPhoto: item.photo,
      AllHasherSqlTableHelper.colNameDisplayPref: item.nameDisplayPref,
      AllHasherSqlTableHelper.colUpdatedAt: item.updatedAt.toString(),
      AllHasherSqlTableHelper.colUpdatedAtValue:
          item.updatedAt.millisecondsSinceEpoch,
      AllHasherSqlTableHelper.colRemovedFlag: item.removed
    };

    return map;
  }

  static AllHasherListModel fromMap(Map<String, dynamic> map) {
    final AllHasherListModel item = AllHasherListModel(
      userId: map[AllHasherSqlTableHelper.colUserId],
      firstName: map[AllHasherSqlTableHelper.colFirstName],
      lastName: map[AllHasherSqlTableHelper.colLastName],
      displayName: map[AllHasherSqlTableHelper.colDisplayName],
      hashName: map[AllHasherSqlTableHelper.colHashName],
      photo: map[AllHasherSqlTableHelper.colPhoto],
      nameDisplayPref: map[AllHasherSqlTableHelper.colNameDisplayPref],
      updatedAt: DateTime.parse(map[AllHasherSqlTableHelper.colUpdatedAt]),
      removed: map[AllHasherSqlTableHelper.colRemovedFlag],
    );

    return item;
  }
}




class GetAllHashersService {
  static final AllHasherSqlTableHelper instance =
      AllHasherSqlTableHelper._privateConstructor();

  Future<num> getLastUpdatedTime() async {
    final Database db = await AllHasherSqlTableHelper.instance.database;
    final List<Map<String, dynamic>> table = await db
        .rawQuery('SELECT MAX(updated_at_value) AS maxDate FROM hashers');
    final num timeValue = table.first['maxDate'];
    print(timeValue.toString());
    return timeValue;
  }

  Future<List<AllHasherListModel>> getHashersFromLocalDb() async {
    final Database db = await AllHasherSqlTableHelper.instance.database;

    final List<Map<String, dynamic>> result =
        await db.query(AllHasherSqlTableHelper.table);

    final List<AllHasherListModel> hashers = <AllHasherListModel>[];

    if ((result != null) && (result.isNotEmpty)) {
      for (int i = 0; i < result.length; i++) {
        if (result[i]['removed_flag'] == 0) {
          final AllHasherListModel hasher =
              AllHasherSqlTableHelper.fromMap(result[i]);
          hashers.add(hasher);
        }
      }
    }
    return hashers;
  }

  Future<void> clearDatabase() async {
    final Database db = await AllHasherSqlTableHelper.instance.database;
    await db.rawDelete('DELETE FROM hashers').then((void dummy) {
      setIntPref(IntPrefsEnum.lastCacheClearAllHasherData,
          DateTime.now().millisecondsSinceEpoch);
    });
  }

  Future<void> updateDatabase(List<AllHasherListModel> hasherList) async {
    final Database db = await AllHasherSqlTableHelper.instance.database;

    for (int i = 0; i < hasherList?.length ?? 0; i++) {
      final Map<String, dynamic> row =
          AllHasherSqlTableHelper.toMap(hasherList[i]);

      final List<Map<String, dynamic>> table = await db.rawQuery(
          'SELECT * FROM hashers WHERE user_id = "${hasherList[i].userId}"');
      if ((table == null) || (table.isEmpty)) {
        final int result = await db.insert(AllHasherSqlTableHelper.table, row);
        print(result.toString() +
            ' inserted into to the AllHashers table @ ${DateTime.now().millisecondsSinceEpoch}');
      } else {
        final String rowId = table.first['id'].toString();

        final int result = await db.update(AllHasherSqlTableHelper.table, row,
            where: 'id = $rowId');
        print(result.toString() +
            ' update only to the AllHashers table @ ${DateTime.now().millisecondsSinceEpoch}');
      }
    }
  }

  Future<List<AllHasherListModel>> getAllHashers(bool forceRefresh) async {
    final int lastUpdate =
        getIntPref(IntPrefsEnum.lastUpdateAllHasherData) ?? 0;

    //forceRefresh = true;

    if (forceRefresh ||
        ((DateTime.now().millisecondsSinceEpoch - lastUpdate) > 86400000)) {
      // check to see if we need to clear the cache
      final int lastCacheClear =
          getIntPref(IntPrefsEnum.lastCacheClearAllHasherData) ?? 0;
      if (lastCacheClear + cacheDurationAllHashers <
          DateTime.now().millisecondsSinceEpoch) {
        print(
            'clearing all hashers cache @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        await clearDatabase();
      }

      final num timeValue = await getLastUpdatedTime();
      final DateTime updatedAfter = timeValue == null
          ? DateTime(2019, 1, 1)
          : DateTime.fromMillisecondsSinceEpoch(timeValue);

      String userId = getStringPref(StringPrefsEnum.userId);
      if ((userId ?? '').isEmpty) {
        userId = GUID_EMPTY;
      }

      final String accessToken =
          Utilities.generateToken(userId, 'getAllHashers');

      final String body = jsonEncode(<String, String>{
        'userId': userId,
        'accessToken': accessToken,
        'updatedAfter': updatedAfter.toUtc().toString().substring(0, 19)
      });

      final http.Response response = await http
          .post(BASE_API_URL + 'get_all_hashers',
              headers: <String, String>{'content-type': 'application/json'},
              body: body
              // Send authorization headers to your backend
              //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
              )
          .catchError(
        (dynamic error) {
          return false;
        },
      );

      List<AllHasherListModel> updatedHasherRecords =
          AllHasherListModel.itemsFromJson(response.body);

      updatedHasherRecords ??= <AllHasherListModel>[];

      setIntPref(IntPrefsEnum.lastUpdateAllHasherData,
          DateTime.now().millisecondsSinceEpoch);

      if (updatedHasherRecords.isNotEmpty) {
        await updateDatabase(updatedHasherRecords);
      }
    }

    final List<AllHasherListModel> allHasherRecords =
        await getHashersFromLocalDb();

    return allHasherRecords;
  }
}
