import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/data_models/all_hasher_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/database/database.dart';

class GetAllHashersService {
  Future<num> getLastUpdatedTime() async {
    final Database db = await DBProvider.db.database;
    final List<Map<String, dynamic>> table = await db
        .rawQuery('SELECT MAX(updated_at_value) AS maxDate FROM hashers');
    final num timeValue = table.first['maxDate'];
    print(timeValue.toString());
    return timeValue;
  }

  Future<List<AllHasherListModel>> getHashersFromLocalDb() async {
    final Database db = await DBProvider.db.database;

    final List<Map<String, dynamic>> result = await db.query('hashers');

    final List<AllHasherListModel> hashers = <AllHasherListModel>[];

    if ((result != null) && (result.isNotEmpty)) {
      for (int i = 0; i < result.length; i++) {
        if (result[i]['removed_flag'] == 0) {
          final AllHasherListModel hasher = AllHasherListModel(
              userId: result[i]['user_id'],
              firstName: result[i]['first_name'],
              lastName: result[i]['last_name'],
              hashName: result[i]['hash_name'],
              displayName: result[i]['display_name'],
              photo: result[i]['photo'],
              nameDisplayPref: result[i]['name_display_pref'],
              updatedAt: DateTime.parse(result[i]['updated_at']),
              removed: result[i]['removed_flag']);
          hashers.add(hasher);
        }
      }
    }
    return hashers;
  }

  Future<void> updateDatabase(List<AllHasherListModel> hasherList) async {
    final Database db = await DBProvider.db.database;

    const String q = '\'';

    for (int i = 0; i < hasherList?.length ?? 0; i++) {
      final List<Map<String, dynamic>> table = await db.rawQuery(
          'SELECT * FROM hashers WHERE user_id = "${hasherList[i].userId}"');
      if ((table == null) || (table.isEmpty)) {
        final int result = await db.rawInsert(
            'INSERT INTO hashers (user_id,first_name,last_name,display_name,hash_name,photo,name_display_pref,updated_at,updated_at_value,removed_flag) VALUES (' +
                q +
                hasherList[i].userId.replaceAll('\'', '\'\'') +
                q +
                ',' +
                q +
                hasherList[i].firstName.replaceAll('\'', '\'\'') +
                q +
                ',' +
                q +
                hasherList[i].lastName.replaceAll('\'', '\'\'') +
                q +
                ',' +
                q +
                hasherList[i].displayName.replaceAll('\'', '\'\'') +
                q +
                ',' +
                q +
                hasherList[i].hashName.replaceAll('\'', '\'\'') +
                q +
                ',' +
                q +
                hasherList[i].photo.replaceAll('\'', '\'\'') +
                q +
                ',' +
                hasherList[i].nameDisplayPref.toString() +
                ',' +
                q +
                hasherList[i].updatedAt.toString() +
                q +
                ',' +
                hasherList[i].updatedAt.millisecondsSinceEpoch.toString() +
                ',' +
                hasherList[i].removed.toString() +
                ')');

        print(result.toString());
      } else {
        final String rowId = table.first['id'].toString();

        final int result = await db.rawUpdate('UPDATE hashers SET '
            'first_name = ' +
            q +
            hasherList[i].firstName.replaceAll('\'', '\'\'') +
            q +
            ', last_name = ' +
            q +
            hasherList[i].lastName.replaceAll('\'', '\'\'') +
            q +
            ', display_name = ' +
            q +
            hasherList[i].displayName.replaceAll('\'', '\'\'') +
            q +
            ', hash_name = ' +
            q +
            hasherList[i].hashName.replaceAll('\'', '\'\'') +
            q +
            ', photo = ' +
            q +
            hasherList[i].photo.replaceAll('\'', '\'\'') +
            q +
            ', name_display_pref = ' +
            hasherList[i].nameDisplayPref.toString() +
            ', updated_at = ' +
            q +
            hasherList[i].updatedAt.toString() +
            q +
            ', updated_at_value = ' +
            hasherList[i].updatedAt.millisecondsSinceEpoch.toString() +
            ', removed_flag = ' +
            hasherList[i].removed.toString() +
            ' WHERE id = $rowId');

        print(result.toString() + ' update only');
      }
    }
  }

  Future<List<AllHasherListModel>> getAllHashers(bool forceRefresh) async {
    final num lastLoad = getIntPref(IntPrefsEnum.lastLoadHasherData) ?? 0;

    if (forceRefresh || ((DateTime.now().millisecondsSinceEpoch - lastLoad) > 86400000)) {
      final num timeValue = await getLastUpdatedTime();
      final DateTime updatedAfter = timeValue == null
          ? DateTime(2019, 1, 1)
          : DateTime.fromMillisecondsSinceEpoch(timeValue);

      String userId = getStringPref(StringPrefsEnum.userId);
      if ((userId ?? '').isEmpty) {
        userId = GUID_EMPTY;
      }

      final String accessToken =
          Utilities.generateToken(userId, 'getAllHashers');

      final String body = jsonEncode(<String, String>{
        'userId': userId,
        'accessToken': accessToken,
        'updatedAfter': updatedAfter.toUtc().toString().substring(0, 19)
      });

      final http.Response response = await http
          .post(BASE_API_URL + 'get_all_hashers',
              headers: <String, String>{'content-type': 'application/json'},
              body: body
              // Send authorization headers to your backend
              //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
              )
          .catchError(
        (dynamic error) {
          return false;
        },
      );

      List<AllHasherListModel> updatedHasherRecords =
          AllHasherListModel.itemsFromJson(response.body);

      updatedHasherRecords ??= <AllHasherListModel>[];

      setIntPref(IntPrefsEnum.lastLoadHasherData,
          DateTime.now().millisecondsSinceEpoch);

      if (updatedHasherRecords.isNotEmpty) {
        await updateDatabase(updatedHasherRecords);
      }
    }

    final List<AllHasherListModel> allHasherRecords =
        await getHashersFromLocalDb();

    return allHasherRecords;
  }
}
