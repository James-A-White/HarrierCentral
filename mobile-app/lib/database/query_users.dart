import 'package:harrier_central/imports.dart';

class QueryUsers {
  // it is important to have the beginning and end of the search field have a space
  // character to ensure that searches run properly.

  static Future<List<Map<String, dynamic>>> querySingleUser(
    String? userId,
  ) async {
    String query =
        '''
        SELECT  
          h.*
          FROM ${EnumDataTables.hashers.commonTableName} h
          WHERE h.${tableModel.hashersTableHelper.colHasherId} = "$userId"
          LIMIT 1
          ''';

    return database.rawQuery(query);
  }
}
