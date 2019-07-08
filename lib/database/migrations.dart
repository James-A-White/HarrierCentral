import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

//import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/data/hc3_services/narrow_event_service.dart';
//import 'package:harrier_central/data/hc3_services/kennel_credits_service.dart';
import 'package:harrier_central/data/hc3_services/kennels_service.dart';
//import 'package:harrier_central/data/hc3_services/narrow_event_service.dart';

class MigrationsModel {
  MigrationsModel({this.migrationNumber, this.migrationText, this.appliedAtInt});

  final int migrationNumber;
  final String migrationText;
  final int appliedAtInt;

  static List<MigrationsModel> itemsFromJson(String jsonResult) {
    final List<MigrationsModel> items = <MigrationsModel>[];

    MigrationsModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = MigrationsModel(migrationNumber: jsonItem['migrationNumber'], migrationText: jsonItem['migrationText'], appliedAtInt: jsonItem['appliedAtInt']);

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

  static const String colMigrationNumber = 'migrationNumber';
  static const String colMigrationText = 'migrationText';
  static const String colAppliedAtInt = 'appliedAtInt';

  // make this a singleton class

  static final MigrationsTableHelper instance = MigrationsTableHelper._privateConstructor();

  // SQL code to create the database table
  static Future<dynamic> createTable(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colMigrationNumber INT NOT NULL,
            $colMigrationText TEXT NOT NULL,
            $colAppliedAtInt INT
          )
          ''');

    await db.execute('CREATE INDEX idx_${tableName}_id ON $tableName($colMigrationNumber);');
  }

  static Map<String, dynamic> toMap(MigrationsModel item) {
    final Map<String, dynamic> map = <String, dynamic>{MigrationsTableHelper.colMigrationNumber: item.migrationNumber, MigrationsTableHelper.colMigrationText: item.migrationText, MigrationsTableHelper.colAppliedAtInt: item.appliedAtInt};

    return map;
  }

  static MigrationsModel fromMap(Map<String, dynamic> map) {
    final MigrationsModel item = MigrationsModel(migrationNumber: map[MigrationsTableHelper.colMigrationNumber], migrationText: map[MigrationsTableHelper.colMigrationText], appliedAtInt: map[MigrationsTableHelper.colAppliedAtInt]);

    return item;
  }

  static Future<bool> doDatabaseMigrations(Database db, int currentDbVersion, int upgradedDbVersion) async {
    if (currentDbVersion == upgradedDbVersion) {
      return true;
    }
    
    bool migrationsSuccessful = true;

    try {
      for (int i = 0; i < migrationList.length; i++) {
        final MigrationsModel mm = migrationList[i];
        if (mm.migrationNumber <= currentDbVersion) {
          continue;
        }
        final String sql = mm.migrationText.trim();
        await db.execute(sql);
        print('Migration ${mm.migrationNumber.toString()} succeeded');
      }
    } catch (e) {
      migrationsSuccessful = false;
      print('Migrations failed');
      print(e.toString());
    }

    return migrationsSuccessful;
  }

  ///// MIGRATIONS GO HERE
  ///
  ///
  ///

  static int dbVersion = 220;

  static List<MigrationsModel> migrationList = <MigrationsModel>[

    // MIGRATION 190
    MigrationsModel(migrationNumber: 190, migrationText: '''
            ALTER TABLE ${KennelsTableHelper.tableName} ADD COLUMN ${KennelsTableHelper.colKennelPaymentUrl} TEXT;
            ALTER TABLE ${KennelsTableHelper.tableName} ADD COLUMN ${KennelsTableHelper.colKennelPaymentUrlExpires} TEXT;
            ALTER TABLE ${NarrowEventsTableHelper.tableName} ADD COLUMN ${NarrowEventsTableHelper.colEventPaymentUrl} TEXT;
            ALTER TABLE ${NarrowEventsTableHelper.tableName} ADD COLUMN ${NarrowEventsTableHelper.colEventPaymentUrlExpires} TEXT;
         '''),
  ];
}
