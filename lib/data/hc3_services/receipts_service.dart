import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:harrier_central/util/globals.dart';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/data/hc3_services/base_service.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/data/services/service_common.dart';

class ReceiptsModel implements BaseModel {
  ReceiptsModel({
    this.receiptId,
    this.eventId,
    this.userId,
    this.receiptAmount,
    this.costCategory = 0,
    this.dateUploaded,
    this.imageUrl,
    this.receiptShortDescription,
    this.notes,
    this.reimbursedBy,
    this.reimbursedOn,
    this.reimbursedAmount,
    this.reimbursedNotes,
    this.removed,
    this.updatedAt,
  });

  final String receiptId;
  final String eventId;
  final String userId;
  final num receiptAmount;
  final int costCategory;
  final DateTime dateUploaded;
  final String imageUrl;
  final String receiptShortDescription;
  final String notes;
  final String reimbursedBy;
  final String reimbursedOn;
  final num reimbursedAmount;
  final String reimbursedNotes;
  final int removed;
  final DateTime updatedAt;

  @override
  List<ReceiptsModel> itemsFromJson(String jsonResult) {
    final List<ReceiptsModel> items = <ReceiptsModel>[];

    ReceiptsModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = ReceiptsModel(
            receiptId: jsonItem['receiptId'],
            eventId: jsonItem['eventId'],
            userId: jsonItem['userId'],
            receiptAmount: jsonItem['receiptAmount'],
            costCategory: jsonItem['costCategory'],
            dateUploaded: DateTime.parse(jsonItem['dateUploaded'].toString().substring(0, 19)),
            imageUrl: jsonItem['imageUrl'],
            receiptShortDescription: jsonItem['receiptShortDescription'],
            notes: jsonItem['notes'],
            reimbursedBy: jsonItem['reimbursedBy'],
            reimbursedOn: jsonItem['reimbursedOn'],
            reimbursedAmount: jsonItem['reimbursedAmount'],
            reimbursedNotes: jsonItem['reimbursedNotes'],
            updatedAt: DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19)),
            removed: jsonItem['removed']);

        items.add(item);
      },
    );

    if (items.isEmpty) {
      return null;
    }

    return items;
  }
}

class ReceiptsTableHelper with BaseFields implements BaseTableHelper {
  ReceiptsTableHelper();

  @override
  num forceRequeryInterval;

  @override
  num cacheDuration;

  @override
  String tableName = 'receipts';

  @override
  String getTableName(TableType type) {
    return tableName;
  }

  @override
  String remoteDbId = 'receiptId';

  final String colReceiptId = 'receiptId';
  final String colEventId = 'eventId';
  final String colUserId = 'userId';
  final String colReceiptAmount = 'receiptAmount';
  final String colCostCategory = 'costCategory';
  final String colDateUploaded = 'dateUploaded';
  final String colImageUrl = 'imageUrl';
  final String colReceiptShortDescription = 'receiptShortDesc';
  final String colNotes = 'notes';
  final String colReimbursedBy = 'reimbursedBy';
  final String colReimbursedOn = 'reimbursedOn';
  final String colReimbursedAmount = 'reimbursedAmount';
  final String colReimbursedNotes = 'reimbursedNotes';

  @override
  Future<dynamic> createTable(Database db, int version,TableType tableType) async {
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colReceiptId TEXT NOT NULL,
            $colEventId TEXT NOT NULL,
            $colUserId TEXT NOT NULL,
            $colReceiptAmount NUM,
            $colCostCategory INT,
            $colDateUploaded TEXT,
            $colImageUrl TEXT,
            $colReceiptShortDescription TEXT,
            $colNotes TEXT,
            $colReimbursedBy TEXT,
            $colReimbursedOn TEXT,
            $colReimbursedAmount NUM,
            $colReimbursedNotes TEXT,

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
      colReceiptId: item.receiptId,
      colEventId: item.eventId,
      colUserId: item.userId,
      colReceiptAmount: item.receiptAmount,
      colCostCategory: item.costCategory,
      colDateUploaded: item.dateUploaded,
      colImageUrl: item.imageUrl,
      colReceiptShortDescription: item.receiptShortDescription,
      colNotes: item.notes,
      colReimbursedBy: item.reimbursedBy,
      colReimbursedOn: item.reimbursedOn,
      colReimbursedAmount: item.reimbursedAmount,
      colReimbursedNotes: item.reimbursedNotes,
      colUpdatedAt: item.updatedAt.toString(),
      colUpdatedAtValue: item.updatedAt.millisecondsSinceEpoch,
      colRemoved: item.removed
    };

    return map;
  }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    final Map<String, dynamic> outputMap = <String, dynamic>{
      colReceiptId: inputMap[colReceiptId],
      colEventId: inputMap[colEventId],
      colUserId: inputMap[colUserId],
      colReceiptAmount: inputMap[colReceiptAmount],
      colCostCategory: inputMap[colCostCategory],
      colDateUploaded: inputMap[colDateUploaded],
      colImageUrl: inputMap[colImageUrl],
      colReceiptShortDescription: inputMap[colReceiptShortDescription],
      colNotes: inputMap[colNotes],
      colReimbursedBy: inputMap[colReimbursedBy],
      colReimbursedOn: inputMap[colReimbursedOn],
      colReimbursedAmount: inputMap[colReimbursedAmount],
      colReimbursedNotes: inputMap[colReimbursedNotes],
      colUpdatedAt: inputMap[colUpdatedAt],
      colUpdatedAtValue: DateTime.parse(inputMap[colUpdatedAt].toString().substring(0, 19)).millisecondsSinceEpoch,
      colRemoved: inputMap[colRemoved],
    };

    return outputMap;
  }

  @override
  ReceiptsModel fromMap(Map<String, dynamic> map) {
    final ReceiptsModel item = ReceiptsModel(
      receiptId: map[colReceiptId],
      eventId: map[colEventId],
      userId: map[colUserId],
      receiptAmount: map[colReceiptAmount],
      costCategory: map[colCostCategory],
      dateUploaded: DateTime.parse(map[colDateUploaded].toString().substring(0, 19)),
      imageUrl: map[colImageUrl],
      receiptShortDescription: map[colReceiptShortDescription],
      notes: map[colNotes],
      reimbursedBy: map[colReimbursedBy],
      reimbursedOn: map[colReimbursedOn],
      reimbursedAmount: map[colReimbursedAmount],
      reimbursedNotes: map[colReimbursedNotes],
      updatedAt: DateTime.parse(map[colUpdatedAt].toString().substring(0, 19)),
      removed: map[colRemoved],
    );

    return item;
  }

  String toQueryBody(String userId, String accessToken, ReceiptsModel item, String receiptsUploadedAfter) {
    final String map = jsonEncode(<String, Object>{
      'userId': userId,
      'accessToken': accessToken,
      colReceiptId: item.receiptId,
      colEventId: item.eventId,
      colReceiptShortDescription: item.receiptShortDescription,
      colReceiptAmount: item.receiptAmount,
      colNotes: item.notes,
      colReimbursedBy: item.reimbursedBy,
      colReimbursedOn: item.reimbursedOn,
      colReimbursedAmount: item.reimbursedAmount,
      colReimbursedNotes: item.reimbursedNotes,
      colImageUrl: item.imageUrl,
      'receiptsUpdatedAfter': receiptsUploadedAfter,
      colRemoved: item.removed
    });
    return map;
  }
}

class ReceiptsService {
  Future<String> uploadReceipt(BuildContext context, ReceiptsModel item) async {
    final String userId = getStringPref(StringPrefsEnum.userId);
    final String accessToken = Utilities.generateToken(userId.toUpperCase(), 'addEditReceipt');

    final num _receiptsLastUpdated = await baseService.getLastUpdatedTime(receiptsTableHelper, receiptsTableHelper.colUpdatedAtValue);
    final DateTime receiptsUpdatedAfter = _receiptsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_receiptsLastUpdated + 1000);

    final String body = receiptsTableHelper.toQueryBody(userId, accessToken, item, receiptsUpdatedAfter.toString());

    final String responseBody = await ServiceCommon.sendRequest(context, 'hc3_add_edit_receipt', body);

    return responseBody;
  }
}
