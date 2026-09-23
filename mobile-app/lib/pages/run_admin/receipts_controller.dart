import 'package:harrier_central/imports.dart';

/// State for the run's receipts list: the rows from the event-domain receipts
/// table and the two swipe actions (reimbursed / ignored), each of which
/// marks the row locally, uploads, and re-reads the table.
///
/// Migrated from a State on 2026-09-23. Receipts exist only in the EVENT
/// domain (no common_ or kennel_ table), which the query below relies on.
class ReceiptsListController extends GetxController {
  ReceiptsListController({required this.eventAggregate});

  final RunAdminAggregate eventAggregate;

  static String tagFor(String eventId) => 'receipts-$eventId';

  final RxList<Map<String, dynamic>> receipts = <Map<String, dynamic>>[].obs;

  String get _eventId => eventAggregate.event.eventId;

  @override
  void onInit() {
    super.onInit();
    unawaited(refreshFromTable());
  }

  Future<void> refreshFromTable() async {
    try {
      final rows = await database.query(EnumDataTables.receipts.eventTableName);
      if (isClosed) return;
      receipts.assignAll(rows);
    } catch (e, s) {
      debugPrint(e.toString());
      BootLogger.logError('[ReceiptsPage.refreshFromTable]', e, s);
    }
  }

  Future<void> pullToRefresh() async {
    await tableModel.syncEventAdminService.updateFromBackend(
      EnumDataTables.receipts.flag,
      true,
      _eventId,
    );
    if (isClosed) return;
    await refreshFromTable();
  }

  /// GUID_8 / GUID_9 in reimbursedBy are the "upload in flight" markers the
  /// row shows as a clock while the server answers.
  Future<void> _markPending(String receiptId, bool flagNine) async {
    await database.transaction<dynamic>((Transaction txn) async {
      final String guidFlag = flagNine ? GUID_9 : GUID_8;
      final String sql =
          'UPDATE ${EnumDataTables.receipts.eventTableName} SET reimbursedBy = "$guidFlag" where receiptId = "$receiptId"';
      await txn.rawUpdate(sql);
    });
    await refreshFromTable();
  }

  Future<void> _upload(ReceiptsModel item) async {
    final ReceiptsService srv = ReceiptsService();
    final String responseBody = await srv.uploadReceipt(item);
    if (isClosed) return;
    if (!responseBody.startsWith(ERROR_PREFIX)) {
      await tableModel.baseService.bulkUpdateDatabase(
        tableModel.receiptsTableHelper,
        EnumDataTables.receipts.eventTableName,
        responseBody,
        database,
      );
      await refreshFromTable();
    } else {
      await Utilities.showAlert(
        'Error uploading receipt',
        'There was an error uploading the receipt. Check your Internet connection and try again.\r\n\r\nSorry for the inconvenience!',
        'OK',
      );
    }
  }

  Future<void> setReimbursementStatus(
    String receiptId,
    bool cancelReimbursement,
  ) async {
    final String userId = currentUserId;
    await _markPending(receiptId, cancelReimbursement);
    await _upload(
      ReceiptsModel(
        userId: userId,
        receiptId: receiptId,
        eventId: _eventId,
        receiptShortDesc: '',
        receiptAmount: -1,
        notes: '',
        reimbursedBy: cancelReimbursement ? GUID_MAX : userId,
        reimbursedAmount: 0,
        reimbursedOn: '1999/1/1',
        reimbursedNotes: '',
        imageUrl: '',
        removed: -1,
      ),
    );
  }

  Future<void> setRemovedStatus(String receiptId, bool removed) async {
    await _markPending(receiptId, removed);
    await _upload(
      ReceiptsModel(
        userId: currentUserId,
        receiptId: receiptId,
        eventId: _eventId,
        receiptShortDesc: '',
        receiptAmount: -1,
        notes: '',
        reimbursedBy: GUID_EMPTY,
        reimbursedAmount: -1,
        reimbursedOn: '1999/1/1',
        reimbursedNotes: '',
        imageUrl: '',
        removed: removed ? 0 : 1,
      ),
    );
  }
}
