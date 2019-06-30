import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/data/hc3_services/narrow_event_service.dart';
import 'package:harrier_central/data/hc3_services/kennel_credits_service.dart';
import 'package:harrier_central/data/hc3_services/kennels_service.dart';

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

  static Future<bool> doDatabaseMigrations(int currentDbVersion, int upgradedDbVersion) async {
    if (currentDbVersion == upgradedDbVersion) {
      return true;
    }
    final Database db = await DBProvider.db.database;
    bool migrationsSuccessful = true;

    try {
      for (int i = 0; i < migrationList.length; i++) {
        final MigrationsModel mm = migrationList[i];
        if (mm.migrationNumber <= currentDbVersion) {
          continue;
        }
        final String sql = mm.migrationText.trim();
        await db.execute(sql);
      }
    } catch (e) {
      migrationsSuccessful = false;
    }

    return migrationsSuccessful;
  }

  ///// MIGRATIONS GO HERE
  ///
  ///
  ///

  static int dbVersion = 153;

  static List<MigrationsModel> migrationList = <MigrationsModel>[
    // MIGRATION 136
    MigrationsModel(migrationNumber: 136, migrationText: '''
            ALTER TABLE ${NarrowEventsTableHelper.tableName} 
              ADD COLUMN hares TEXT;
         '''),
    // MIGRATION 149
    MigrationsModel(migrationNumber: 149, migrationText: '''

          CREATE TABLE ${KennelCreditsTableHelper.tableName} (
            ${KennelCreditsTableHelper.colId} INTEGER PRIMARY KEY,

            ${KennelCreditsTableHelper.colKennelCreditId} TEXT,
            ${KennelCreditsTableHelper.colUserId} TEXT,
            ${KennelCreditsTableHelper.colKennelId} TEXT,
            ${KennelCreditsTableHelper.colCurrentBalance} NUM,
            ${KennelCreditsTableHelper.colBalanceAsOfEventId} TEXT,

            ${KennelCreditsTableHelper.colRemoved} NUM,
            ${KennelCreditsTableHelper.colUpdatedAt} TEXT,
            ${KennelCreditsTableHelper.colUpdatedAtValue} NUM NULL
          );
         
         CREATE INDEX idx_${KennelCreditsTableHelper.tableName}_id ON ${KennelCreditsTableHelper.tableName}(${KennelCreditsTableHelper.remoteDbId});
         CREATE INDEX idx_${KennelCreditsTableHelper.tableName}_update_at_value ON ${KennelCreditsTableHelper.tableName}($KennelCreditsTableHelper.colUpdatedAtValue);
         
         '''),
    // MIGRATION 153
    MigrationsModel(migrationNumber: 153, migrationText: '''
            ALTER TABLE ${KennelsTableHelper.tableName} ADD COLUMN ${KennelsTableHelper.colCurrencyCode} TEXT;
            ALTER TABLE ${KennelsTableHelper.tableName} ADD COLUMN ${KennelsTableHelper.colPrimaryCultureCode} TEXT;
            ALTER TABLE ${KennelsTableHelper.tableName} ADD COLUMN ${KennelsTableHelper.colCurrencySymbol} TEXT;
            ALTER TABLE ${KennelsTableHelper.tableName} ADD COLUMN ${KennelsTableHelper.colDigitsAfterDecimal} NUM;
            ALTER TABLE ${KennelsTableHelper.tableName} ADD COLUMN ${KennelsTableHelper.colBankScheme} TEXT;
            ALTER TABLE ${KennelsTableHelper.tableName} ADD COLUMN ${KennelsTableHelper.colBankAccountNumber} TEXT,
            ALTER TABLE ${KennelsTableHelper.tableName} ADD COLUMN ${KennelsTableHelper.colBankBic} TEXT;
            ALTER TABLE ${KennelsTableHelper.tableName} ADD COLUMN ${KennelsTableHelper.colBankBeneficiary} TEXT;
         '''),
  ];
}
