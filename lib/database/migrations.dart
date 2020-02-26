import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/data/hc3_services/base_service.dart';
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

  static int dbVersion = 232;

  static List<MigrationsModel> migrationList = <MigrationsModel>[

    // MIGRATION 221
    MigrationsModel(migrationNumber: 221, migrationText: '''
            ALTER TABLE ${hashersTableHelper.tableName} ADD COLUMN ${hashersTableHelper.colHomeKennelId} TEXT;
         '''),
      
    // MIGRATION 222
    MigrationsModel(migrationNumber: 222, migrationText: '''
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmUser)} ADD COLUMN ${hasherKennelMapTableHelper.colKennelEmailAlertPreference} INT;
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmEventAdmin)} ADD COLUMN ${hasherKennelMapTableHelper.colKennelEmailAlertPreference} INT;
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmKennelAdmin)} ADD COLUMN ${hasherKennelMapTableHelper.colKennelEmailAlertPreference} INT;
         '''),

    // MIGRATION 223
    MigrationsModel(migrationNumber: 223, migrationText: '''
            ALTER TABLE ${hasherEventMapTableHelper.getTableName(TableType.hemUser)} ADD COLUMN ${hasherEventMapTableHelper.colEventEmailAlertPreference} INT;
            ALTER TABLE ${hasherEventMapTableHelper.getTableName(TableType.hemEventAdmin)} ADD COLUMN ${hasherKennelMapTableHelper.colKennelEmailAlertPreference} INT;
         '''),


    // MIGRATION 224
    MigrationsModel(migrationNumber: 224, migrationText: '''
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colEventPriceForExtras} NUM;
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colExtrasDescription} TEXT;
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colDoTrackHashCash} INT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelMismanagementTeam} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colDistancePreference} INT;
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmKennelAdmin)} ADD COLUMN ${hasherKennelMapTableHelper.colIsKennelFollowing} INT;
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmKennelAdmin)} ADD COLUMN ${hasherKennelMapTableHelper.colMismanagementRoles} INT;
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmUser)} ADD COLUMN ${hasherKennelMapTableHelper.colIsKennelFollowing} INT;
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmUser)} ADD COLUMN ${hasherKennelMapTableHelper.colMismanagementRoles} INT;
            ALTER TABLE ${hashersTableHelper.tableName} ADD COLUMN ${hashersTableHelper.colIncludeInGlobalHashDirectory} INT;
            ALTER TABLE ${countriesTableHelper.tableName} ADD COLUMN ${countriesTableHelper.colDistancePreference} INT NOT NULL DEFAULT 0;
         '''),

  // MIGRATION 225
    MigrationsModel(migrationNumber: 225, migrationText: '''
            ALTER TABLE ${hashersTableHelper.tableName} ADD COLUMN ${hashersTableHelper.colPreferences} INT;
         '''),

             // MIGRATION 226
    MigrationsModel(migrationNumber: 226, migrationText: '''
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmEventAdmin)} ADD COLUMN ${hasherKennelMapTableHelper.colIsKennelFollowing} INT;
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmEventAdmin)} ADD COLUMN ${hasherKennelMapTableHelper.colMismanagementRoles} INT;
         '''),


             // MIGRATION 227
    MigrationsModel(migrationNumber: 227, migrationText: '''
            ALTER TABLE ${paymentsTableHelper.tableName} ADD COLUMN ${paymentsTableHelper.colDoPayForExtras} INT;
         '''),

                      // MIGRATION 228
    MigrationsModel(migrationNumber: 228, migrationText: '''
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colTags1} INT;
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colTags2} INT;
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colTags3} INT;
         '''),

     MigrationsModel(migrationNumber: 229, migrationText: '''
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colEventPaymentScheme} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentScheme} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentScheme2} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentScheme3} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentUrl2} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentUrl3} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentUrlExpires2} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentUrlExpires3} TEXT;
         '''),

        MigrationsModel(migrationNumber: 230, migrationText: '''
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentMemberSurcharge} NUM;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentNonMemberSurcharge} NUM;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentMemberSurcharge2} NUM;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentNonMemberSurcharge2} NUM;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentMemberSurcharge3} NUM;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentNonMemberSurcharge3} NUM;
         '''),

        MigrationsModel(migrationNumber: 231, migrationText: '''
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colAllowSelfPayment} INT;
         '''),

        MigrationsModel(migrationNumber: 232, migrationText: '''
            ALTER TABLE ${paymentsTableHelper.tableName} ADD COLUMN ${paymentsTableHelper.colSurcharge} INT;
            ALTER TABLE ${paymentsTableHelper.tableName} ADD COLUMN ${paymentsTableHelper.colPaymentProvider} INT;
         '''),

  ];
}
