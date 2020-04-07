import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

class MigrationsModel {
  MigrationsModel({this.dbVersion, this.migrationText, this.appliedAtInt});

  final int dbVersion;
  final String migrationText;
  final int appliedAtInt;

  static List<MigrationsModel> itemsFromJson(String jsonResult) {
    final List<MigrationsModel> items = <MigrationsModel>[];

    MigrationsModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = MigrationsModel(dbVersion: jsonItem['dbVersion'], migrationText: jsonItem['migrationText'], appliedAtInt: jsonItem['appliedAtInt']);

        items.add(item);
      },
    );

    if (items.isEmpty) {
      return null;
    }

    return items;
  }
}

class MigrationsTableHelper {
  MigrationsTableHelper._privateConstructor();

  static const String tableName = 'migrations';

  static const String colId = 'id';

  static const String colDbVersion = 'dbVersion';
  static const String colMigrationText = 'migrationText';
  static const String colAppliedAtInt = 'appliedAtInt';

  // make this a singleton class

  static final MigrationsTableHelper instance = MigrationsTableHelper._privateConstructor();

  // SQL code to create the database table
  static Future<dynamic> createTable(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colDbVersion INT NOT NULL,
            $colMigrationText TEXT NOT NULL,
            $colAppliedAtInt INT
          )
          ''');

    await db.execute('CREATE INDEX idx_${tableName}_id ON $tableName($colDbVersion);');
  }

  static Map<String, dynamic> toMap(MigrationsModel item) {
    final Map<String, dynamic> map = <String, dynamic>{MigrationsTableHelper.colDbVersion: item.dbVersion, MigrationsTableHelper.colMigrationText: item.migrationText, MigrationsTableHelper.colAppliedAtInt: item.appliedAtInt};

    return map;
  }

  static MigrationsModel fromMap(Map<String, dynamic> map) {
    final MigrationsModel item = MigrationsModel(dbVersion: map[MigrationsTableHelper.colDbVersion], migrationText: map[MigrationsTableHelper.colMigrationText], appliedAtInt: map[MigrationsTableHelper.colAppliedAtInt]);

    return item;
  }

  static Future<bool> doDatabaseMigrations(Database db, List<MigrationsModel> migrationList, int currentDbVersion, int upgradedDbVersion) async {
    if (currentDbVersion == upgradedDbVersion) {
      return true;
    }

    

    bool migrationsSuccessful = true;

    try {
      for (int i = 0; i < migrationList.length; i++) {
        final MigrationsModel mm = migrationList[i];
        if (mm.dbVersion <= currentDbVersion) {
          continue;
        }
        final String sql = mm.migrationText.trim();
        final List<String> statements = sql.split(';');

        int line = 1;

        for (String statement in statements) {
          statement = statement.trim();
          if (statement.isEmpty) {
            continue;
          }

          statement = statement + ';';

          print('Migration #: ${mm.dbVersion.toString()}, statement #$line');
          print('Migration sql: $statement');
          await db.execute(statement);
          print('Migration ${mm.dbVersion.toString()}, statement #$line succeeded');
          line++;
        }
      }
    } catch (e) {
      migrationsSuccessful = false;
      print('Migrations failed');
      print(e.toString());
    }

    return migrationsSuccessful;
  } 
}
