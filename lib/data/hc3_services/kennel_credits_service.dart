import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/data/hc3_services/base_service.dart';

import 'package:json_annotation/json_annotation.dart';

part 'kennel_credits_service.g.dart';

@JsonSerializable(fieldRename: FieldRename.none)
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

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        final KennelCreditsModel item = _$KennelCreditsModelFromJson(jsonItem);

        items.add(item);
      },
    );

    if (items.isEmpty) {
      return null;
    }

    return items;
  }
}

class KennelCreditsTableHelper with BaseFields implements BaseTableHelper {
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

  final String colKennelCreditId = 'kennelCreditId';
  final String colUserId = 'userId';
  final String colKennelId = 'kennelId';
  final String colCurrentBalance = 'currentBalance';
  final String colBalanceAsOfEventId = 'balanceAsOfEventId';

  @override
  Future<dynamic> createTable(Database db, int version, TableType tableType) async {
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
    final Map<String, dynamic> map = _$KennelCreditsModelToJson(item);
    return map;
  }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    final KennelCreditsModel item = _$KennelCreditsModelFromJson(inputMap);
    final Map<String, dynamic> outputMap = _$KennelCreditsModelToJson(item);
    return outputMap;
  }

  @override
  KennelCreditsModel fromMap(Map<String, dynamic> map) {
    final KennelCreditsModel item = _$KennelCreditsModelFromJson(map);
    return item;
  }
}
