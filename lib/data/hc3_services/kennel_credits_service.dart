import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/data/hc3_services/base_service.dart';
import 'package:harrier_central/util/preferences.dart';

class KennelCreditsModel implements BaseModel {
  KennelCreditsModel({
    this.kennelCreditId,
    this.userId,
    this.kennelId,
    this.currentBalance,
    this.balanceAsOfEventId,
    this.updatedAt,
    this.removed,
  });

  final String kennelCreditId;
  final String userId;
  final String kennelId;
  final num currentBalance;
  final String balanceAsOfEventId;
  final DateTime updatedAt;
  final int removed;

  @override
  List<KennelCreditsModel> itemsFromJson(String jsonResult) {
    final List<KennelCreditsModel> items = <KennelCreditsModel>[];

    KennelCreditsModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = KennelCreditsModel(kennelCreditId: jsonItem['kennelCreditId'], userId: jsonItem['userId'], kennelId: jsonItem['kennelId'], currentBalance: jsonItem['currentBalance'], balanceAsOfEventId: jsonItem['balanceAsOfEventId'], updatedAt: jsonItem['updatedAt'], removed: jsonItem['removed']);

        items.add(item);
      },
    );

    if (items.isEmpty) {
      return null;
    }

    return items;
  }
}

class KennelCreditsTableHelper implements BaseTableHelper {
  KennelCreditsTableHelper();

  @override
  num forceRequeryInterval;

  @override
  num cacheDuration;

  @override
  String tableName = 'kennelCredits';

  @override
  String getTableName(TableType type) {
    return tableName;
  }

  @override
  String remoteDbId = 'kennelCreditId';

  final String colId = 'id';
  final String colKennelCreditId = 'kennelCreditId';
  final String colUserId = 'userId';
  final String colKennelId = 'kennelId';
  final String colCurrentBalance = 'currentBalance';
  final String colBalanceAsOfEventId = 'balanceAsOfEventId';
  final String colUpdatedAt = 'updatedAt';
  final String colRemoved = 'removed';
  final String colUpdatedAtValue = 'updatedAtValue';

  @override
  Future<dynamic> createTable(Database db, int version,TableType tableType) async {
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colKennelCreditId TEXT,
            $colUserId TEXT,
            $colKennelId TEXT,
            $colCurrentBalance NUM,
            $colBalanceAsOfEventId TEXT,

            $colRemoved NUM,
            $colUpdatedAt TEXT,
            $colUpdatedAtValue NUM NULL
          )
          ''');

    await db.execute('CREATE INDEX idx_${tableName}_id ON $tableName($remoteDbId);');
    await db.execute('CREATE INDEX idx_${tableName}_update_at_value ON $tableName($colUpdatedAtValue);');
  }

  @override
  Map<String, dynamic> toMap(dynamic item) {
    final Map<String, dynamic> map = <String, dynamic>{
      colKennelCreditId: item.kennelCreditId,
      colUserId: item.userId,
      colKennelId: item.kennelId,
      colCurrentBalance: item.currentBalance,
      colBalanceAsOfEventId: item.balanceAsOfEventId,
      colUpdatedAt: item.updatedAt,
      colRemoved: item.removed,
      colUpdatedAtValue: item.updatedAt.millisecondsSinceEpoch,
    };

    return map;
  }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    final Map<String, dynamic> outputMap = <String, dynamic>{
      colKennelCreditId: inputMap[colKennelCreditId],
      colUserId: inputMap[colUserId],
      colKennelId: inputMap[colKennelId],
      colCurrentBalance: inputMap[colCurrentBalance],
      colBalanceAsOfEventId: inputMap[colBalanceAsOfEventId],
      colUpdatedAt: inputMap[colUpdatedAt],
      colUpdatedAtValue: DateTime.parse(inputMap[colUpdatedAt].toString().substring(0, 19)).millisecondsSinceEpoch,
      colRemoved: inputMap[colRemoved],
    };

    return outputMap;
  }

  @override
  KennelCreditsModel fromMap(Map<String, dynamic> map) {
    final KennelCreditsModel item = KennelCreditsModel(
      kennelCreditId: map[colKennelCreditId],
      userId: map[colUserId],
      kennelId: map[colKennelId],
      currentBalance: map[colCurrentBalance],
      balanceAsOfEventId: map[colBalanceAsOfEventId],
      updatedAt: DateTime.parse(map[colUpdatedAt].toString().substring(0, 19)),
      removed: map[colRemoved],
    );

    return item;
  }
}
