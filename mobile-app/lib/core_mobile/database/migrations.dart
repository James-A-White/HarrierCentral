// Vendored from ive_flutter_core_mobile @ eefbbc16 on 2026-09-02.
//
// Moved in-project because the 3.1 sync work has to change it: the UNIQUE
// constraint on the server primary key belongs in table creation and
// INSERT OR REPLACE belongs in the batch insert, both of which live here.
// Iterating on that across two repos behind a pinned commit hash is friction
// on every loop, and harrier_central was the only live consumer — the other,
// HarrierCentralMobile-Flutter, is the retired pre-HC6 repo.
//
// ive_flutter_core (non-mobile) is NOT vendored: four live consumers,
// including the portal, and the bug was never in it.

// Lints inherited from the vendored source, suppressed so this commit stays a
// faithful move rather than a move mixed with style edits. Worth clearing when
// these files are next opened for the 3.1 sync work — in particular the 19
// print() calls, which run on every sync in release builds too and would be
// better behind kDebugMode.
// ignore_for_file: avoid_print, no_leading_underscores_for_local_identifiers
// ignore_for_file: prefer_interpolation_to_compose_strings
// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

class MigrationsModel {
  MigrationsModel({
    required this.dbVersion,
    required this.migrationText,
    required this.appliedAtInt,
  });

  final int dbVersion;
  final String migrationText;
  final int appliedAtInt;

  static List<MigrationsModel> itemsFromJson(String jsonResult) {
    final List<MigrationsModel> items = <MigrationsModel>[];

    MigrationsModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = MigrationsModel(
          dbVersion: jsonItem['dbVersion'] as int,
          migrationText: jsonItem['migrationText'] as String,
          appliedAtInt: jsonItem['appliedAtInt'] as int,
        );

        items.add(item);
      },
    );

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

  static final MigrationsTableHelper instance =
      MigrationsTableHelper._privateConstructor();

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

    await db.execute(
        'CREATE INDEX idx_${tableName}_id ON $tableName($colDbVersion);');
  }

  static Map<String, dynamic> toMap(MigrationsModel item) {
    final Map<String, dynamic> map = <String, dynamic>{
      MigrationsTableHelper.colDbVersion: item.dbVersion,
      MigrationsTableHelper.colMigrationText: item.migrationText,
      MigrationsTableHelper.colAppliedAtInt: item.appliedAtInt
    };

    return map;
  }

  static MigrationsModel fromMap(Map<String, dynamic> map) {
    final MigrationsModel item = MigrationsModel(
        dbVersion: map[MigrationsTableHelper.colDbVersion] as int,
        migrationText: map[MigrationsTableHelper.colMigrationText] as String,
        appliedAtInt: map[MigrationsTableHelper.colAppliedAtInt] as int);

    return item;
  }

  static Future<bool> doDatabaseMigrations(
      Database db,
      List<MigrationsModel> migrationList,
      int currentDbVersion,
      int upgradedDbVersion) async {
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
          print(
              'Migration ${mm.dbVersion.toString()}, statement #$line succeeded');
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
