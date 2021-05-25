import 'package:harrier_central/imports.dart';

part 'receipts_service.g.dart';

@JsonSerializable(fieldRename: FieldRename.none)
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

  factory ReceiptsModel.fromJson(Map<String, dynamic> json) =>
      _$ReceiptsModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReceiptsModelToJson(this);

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
}

class ReceiptsTableHelper extends BaseTableHelper with BaseFields {
  ReceiptsTableHelper() {
    remoteDbId = 'receiptId';
    humanReadableTableName = 'Receipts';
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
      Database db, int version, dynamic appDomainType) async {
    final String tableName = getTableName(appDomainType);
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
  }

  @override
  Future<void> createIndexes(
      Database db, int version, dynamic appDomainType) async {
    await db.execute(
        'CREATE INDEX idx_${getTableName(appDomainType)}_id ON ${getTableName(appDomainType)}($remoteDbId);');
    await db.execute(
        'CREATE INDEX idx_${getTableName(appDomainType)}_update_at_value ON ${getTableName(appDomainType)}($colUpdatedAtValue);');
  }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    return ReceiptsModel.fromJson(inputMap).toJson();
  }

  @override
  ReceiptsModel fromMap(Map<String, dynamic> map) {
    return ReceiptsModel.fromJson(map);
  }

  String toQueryBody(String userId, String accessToken, ReceiptsModel item,
      String receiptsUploadedAfter) {
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
    final String accessToken =
        IveCoreUtilities.generateToken(userId.toUpperCase(), 'addEditReceipt');

    final num _receiptsLastUpdated =
        await G0<TableModel>().baseService.getLastUpdatedTime(
              G0<Database>(),
              G0<TableModel>().receiptsTableHelper,
              G0<TableModel>()
                  .receiptsTableHelper
                  .getTableName(AppDomainType.event),
              G0<TableModel>().receiptsTableHelper.colUpdatedAtValue,
            );
    final DateTime receiptsUpdatedAfter = _receiptsLastUpdated == null
        ? DateTime(2000, 1, 1)
        : DateTime.fromMillisecondsSinceEpoch(_receiptsLastUpdated + 1000);

    final String body = G0<TableModel>().receiptsTableHelper.toQueryBody(
        userId, accessToken, item, receiptsUpdatedAfter.toString());

    final String responseBody =
        await ServiceCommon.sendRequest(context, 'hc3_add_edit_receipt', body);

    return responseBody;
  }
}
