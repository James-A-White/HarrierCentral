import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

//import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/data/hc3_services/narrow_event_service.dart';
import 'package:harrier_central/data/hc3_services/countries_service.dart';
//import 'package:harrier_central/data/hc3_services/kennel_credits_service.dart';
import 'package:harrier_central/data/hc3_services/kennels_service.dart';
import 'package:harrier_central/data/hc3_services/payments_service.dart';
//import 'package:harrier_central/data/hc3_services/narrow_event_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_event_map_service.dart';
import 'package:harrier_central/data/hc3_services/hashers_service.dart';
import 'package:harrier_central/util/globals.dart';

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
        final List<String> statements = sql.split(';');

        int line = 1;

        for(String statement in statements)
        {
            statement = statement.trim();
            if (statement.isEmpty) 
            {
              continue;
            }

            statement = statement + ';';

            print('Migration #: ${mm.migrationNumber.toString()}, statement #$line');
            print('Migration sql: $statement');
            await db.execute(statement);
            print('Migration ${mm.migrationNumber.toString()}, statement #$line succeeded');
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

  ///// MIGRATIONS GO HERE
  ///
  ///
  ///

  static int dbVersion = 228;

  static List<MigrationsModel> migrationList = <MigrationsModel>[

    // MIGRATION 221
    MigrationsModel(migrationNumber: 221, migrationText: '''
            ALTER TABLE ${hashersTableHelper.tableName} ADD COLUMN ${hashersTableHelper.colHomeKennelId} TEXT;
         '''),
      
    // MIGRATION 222
    MigrationsModel(migrationNumber: 222, migrationText: '''
            ALTER TABLE ${HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.user)} ADD COLUMN ${HasherKennelMapTableHelper.colKennelEmailAlertPreference} INT;
            ALTER TABLE ${HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.eventAdmin)} ADD COLUMN ${HasherKennelMapTableHelper.colKennelEmailAlertPreference} INT;
            ALTER TABLE ${HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.kennelAdmin)} ADD COLUMN ${HasherKennelMapTableHelper.colKennelEmailAlertPreference} INT;
         '''),

    // MIGRATION 223
    MigrationsModel(migrationNumber: 223, migrationText: '''
            ALTER TABLE ${HasherEventMapTableHelper.getTableName(HasherEventMapTableType.user)} ADD COLUMN ${HasherEventMapTableHelper.colEventEmailAlertPreference} INT;
            ALTER TABLE ${HasherEventMapTableHelper.getTableName(HasherEventMapTableType.eventAdmin)} ADD COLUMN ${HasherKennelMapTableHelper.colKennelEmailAlertPreference} INT;
         '''),


    // MIGRATION 224
    MigrationsModel(migrationNumber: 224, migrationText: '''
            ALTER TABLE ${EventTableHelper.tableName} ADD COLUMN ${EventTableHelper.colEventPriceForExtras} NUM;
            ALTER TABLE ${EventTableHelper.tableName} ADD COLUMN ${EventTableHelper.colExtrasDescription} TEXT;
            ALTER TABLE ${EventTableHelper.tableName} ADD COLUMN ${EventTableHelper.colDoTrackHashCash} INT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelMismanagementTeam} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colDistancePreference} INT;
            ALTER TABLE ${HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.kennelAdmin)} ADD COLUMN ${HasherKennelMapTableHelper.colIsKennelFollowing} INT;
            ALTER TABLE ${HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.kennelAdmin)} ADD COLUMN ${HasherKennelMapTableHelper.colMismanagementRoles} INT;
            ALTER TABLE ${HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.user)} ADD COLUMN ${HasherKennelMapTableHelper.colIsKennelFollowing} INT;
            ALTER TABLE ${HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.user)} ADD COLUMN ${HasherKennelMapTableHelper.colMismanagementRoles} INT;
            ALTER TABLE ${hashersTableHelper.tableName} ADD COLUMN ${hashersTableHelper.colIncludeInGlobalHashDirectory} INT;
            ALTER TABLE ${countriesTableHelper.tableName} ADD COLUMN ${countriesTableHelper.colDistancePreference} INT NOT NULL DEFAULT 0;
         '''),

  // MIGRATION 225
    MigrationsModel(migrationNumber: 225, migrationText: '''
            ALTER TABLE ${hashersTableHelper.tableName} ADD COLUMN ${hashersTableHelper.colPreferences} INT;
         '''),

             // MIGRATION 226
    MigrationsModel(migrationNumber: 226, migrationText: '''
            ALTER TABLE ${HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.eventAdmin)} ADD COLUMN ${HasherKennelMapTableHelper.colIsKennelFollowing} INT;
            ALTER TABLE ${HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.eventAdmin)} ADD COLUMN ${HasherKennelMapTableHelper.colMismanagementRoles} INT;
         '''),


             // MIGRATION 227
    MigrationsModel(migrationNumber: 227, migrationText: '''
            ALTER TABLE ${paymentsTableHelper.tableName} ADD COLUMN ${paymentsTableHelper.colDoPayForExtras} INT;
         '''),

                      // MIGRATION 228
    MigrationsModel(migrationNumber: 228, migrationText: '''
            ALTER TABLE ${EventTableHelper.tableName} ADD COLUMN ${EventTableHelper.colTags1} INT;
            ALTER TABLE ${EventTableHelper.tableName} ADD COLUMN ${EventTableHelper.colTags2} INT;
            ALTER TABLE ${EventTableHelper.tableName} ADD COLUMN ${EventTableHelper.colTags3} INT;
         '''),

  ];
}
