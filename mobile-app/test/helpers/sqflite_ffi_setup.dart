import 'package:sqflite_common_ffi/ffi.dart';
import 'package:sqflite/sqflite.dart';

/// Redirect sqflite to an in-memory FFI implementation for widget/unit tests.
///
/// Call once before any test that opens the local SQLite database.
/// The in-memory factory is process-global — calling it multiple times is safe.
void initSqfliteFfi() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
