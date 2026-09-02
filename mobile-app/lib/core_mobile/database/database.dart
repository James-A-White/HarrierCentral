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

// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';
import 'dart:io';

import 'package:harrier_central/core_mobile/database/migrations.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// [DBProvider] is a lightweight class to help with some common DB functions
class DBProvider {
  /// [deleteDb] does what it says on the tin.  ;-)
  static Future<bool> deleteDb(String dbName) async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, dbName);
    await deleteDatabase(path);

    return true;
  }

  /// [openOrInitDb] will open a database if one exists or will
  /// create a new one if one is not already present. It returns
  /// a pointer to the DB as a Future.
  static Future<Database> openOrInitDb(
    String dbName,
    int dbVersion,
    void Function(String message)? informUser,
    List<MigrationsModel> migrations, {
    required Function createTables,
    required Function openDb,
    required String clientAppIdentifier,
  }) async {
    // DBs are stored in the documents directory on the mobile device.
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, dbName);
    return openDatabase(
      path,
      version: dbVersion,
      onOpen: (Database db) async {
        // run any code that needs to execute once the DB has been opened
        await openDb(db, informUser, clientAppIdentifier);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        // run any required DB migrations
        await MigrationsTableHelper.doDatabaseMigrations(
          db,
          migrations,
          oldVersion,
          dbVersion,
        );
      },
      onCreate: (Database db, int version) async {
        // call back to a function that will create tables and indexes
        await createTables(db, version, informUser, clientAppIdentifier);
      },
      onConfigure: (Database db) async {
        await db.execute('PRAGMA cache_size=1500000');
      },
    );
  }
}
