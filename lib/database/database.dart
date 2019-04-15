// import 'dart:async';
// import 'dart:io';

// import 'package:path/path.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:sqflite/sqflite.dart';

// class DBProvider {
//   DBProvider._();
//   static final DBProvider db = DBProvider._();

//   Database _database;

//   Future<Database> get database async {
//     if (_database != null) {
//       return _database;
//     }
//     // if _database is null we instantiate it
//     _database = await initDB();
//     return _database;
//   }

//   dynamic initDB() async {
//     final Directory documentsDirectory =
//         await getApplicationDocumentsDirectory();
//     final String path = join(documentsDirectory.path, 'hashers.db');
//     return await openDatabase(path, version: 1, onOpen: (Database db) {},
//         onCreate: (Database db, int version) async {
//       await db.execute('CREATE TABLE hashers ('
//           'id INTEGER PRIMARY KEY,'
//           'user_id TEXT,'
//           'first_name TEXT,'
//           'last_name TEXT,'
//           'display_name TEXT,'
//           'hash_name TEXT,'
//           'photo TEXT,'
//           'name_display_pref NUM,'
//           'updated_at TEXT,'
//           'updated_at_value NUM,'
//           'removed_flag NUM'
//           ')');
//     });
//   }
// }
