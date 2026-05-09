import 'package:harrier_central/imports.dart';

class ReceiptsTableHelper extends BaseTableHelper with BaseFields {
  ReceiptsTableHelper() {
    remoteDbId = 'receiptId';
    humanReadableTableName = 'Receipts';
    pageSize = 250;
  }

  // @override
  // String tableName = 'receipts';

  @override
  String getTableName(dynamic appDomainType) {
    String tableName;
    switch (appDomainType) {
      // case AppDomainType.event:
      //   tableName = 'Payments';
      //   break;
      // // case AppDomainType.kennel:
      // //   break;
      // case AppDomainType.user:
      //   tableName = 'userPayments';
      //   break;
      default:
        tableName = 'receipts';
    }
    return tableName;
  }

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
  Future<dynamic> createTable(
    Database db,
    int version,
    dynamic appDomainType,
  ) async {
    final String tableName = getTableName(appDomainType);
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colReceiptId TEXT NOT NULL,
            $colEventId TEXT NOT NULL,
            $colUserId TEXT NOT NULL,
            $colReceiptAmount NUM NOT NULL,
            $colCostCategory INT NOT NULL,
            $colDateUploaded TEXT NOT NULL,
            $colImageUrl TEXT,
            $colReceiptShortDescription TEXT,
            $colNotes TEXT,
            $colReimbursedBy TEXT,
            $colReimbursedOn TEXT,
            $colReimbursedAmount NUM,
            $colReimbursedNotes TEXT,
            $colRemoved INT NOT NULL,
            $colUpdatedAt TEXT NOT NULL,
            $colUpdatedAtValue INT NULL
          )
          ''');
  }

  @override
  Future<void> createIndexes(
    Database db,
    int version,
    dynamic appDomainType,
  ) async {
    await db.execute(
      'CREATE INDEX idx_${getTableName(appDomainType)}_id ON ${getTableName(appDomainType)}($remoteDbId);',
    );
    await db.execute(
      'CREATE INDEX idx_${getTableName(appDomainType)}_update_at_value ON ${getTableName(appDomainType)}($colUpdatedAtValue);',
    );
  }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    return ReceiptsModel.fromJson(inputMap).toJson();
  }

  @override
  ReceiptsModel fromMap(Map<String, dynamic> map) {
    return ReceiptsModel.fromJson(map);
  }

  String toQueryBody(
    String deviceId,
    String accessToken,
    ReceiptsModel item,
    String receiptsUploadedAfter,
  ) {
    final String map = jsonEncode(<String, Object?>{
      'queryType': 'addEditReceipt',
      'deviceId': deviceId,
      'accessToken': accessToken,
      colReceiptId: item.receiptId,
      colEventId: item.eventId,
      colReceiptShortDescription: item.receiptShortDesc,
      colReceiptAmount: item.receiptAmount,
      colNotes: item.notes,
      colReimbursedBy: item.reimbursedBy,
      colReimbursedOn: item.reimbursedOn,
      colReimbursedAmount: item.reimbursedAmount,
      colReimbursedNotes: item.reimbursedNotes,
      colImageUrl: item.imageUrl,
      'receiptsUpdatedAfter': receiptsUploadedAfter,
      colRemoved: item.removed,
    });
    return map;
  }
}

class ReceiptsService {
  Future<String> uploadReceipt(ReceiptsModel item) async {
    final String userId = getStringPref(StringPrefsEnum.userId)!;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final String accessToken = Utilities.generateToken(
      userId,
      'hcapp_addEditReceipt',
      paramString: deviceSecret,
    );

    final int receiptsLastUpdated = await tableModel.baseService
        .getLastUpdatedTime(
          database,
          tableModel.receiptsTableHelper,
          tableModel.receiptsTableHelper.getTableName(AppDomainType.event),
          tableModel.receiptsTableHelper.colUpdatedAtValue,
        );
    final DateTime receiptsUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
      receiptsLastUpdated + 1,
    );

    final String body = tableModel.receiptsTableHelper.toQueryBody(
      deviceId,
      accessToken,
      item,
      receiptsUpdatedAfter.toString(),
    );

    final String responseBody = await ServiceCommon.sendHttpPostV2(body);

    // callers are properly handling Error conditions
    return responseBody;
  }
}
