import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/core/migrations.dart';

class DBProvider {
  static Future<bool> deleteDb(String dbName) async {
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, dbName);
    await deleteDatabase(path);

    return true;
  }

  static Future<Database> openOrInitDb(
    String dbName,
    int dbVersion,
    Function informUser,
    List<MigrationsModel> migrations, {
    Function createTables,
  }) async {
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, dbName);
    return openDatabase(path, version: dbVersion, onOpen: (Database db) {
      // nothing happens in here
    }, onUpgrade: (Database db, int oldVersion, int newVersion) async {
      MigrationsTableHelper.doDatabaseMigrations(db, migrations, oldVersion, dbVersion);
    }, onCreate: (Database db, int version) async {
      await createTables(db, version, informUser);
    });
  }
}
