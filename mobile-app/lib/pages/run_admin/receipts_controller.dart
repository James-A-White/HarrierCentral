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

  /// Receipts whose swipe is still uploading. Checked and set in the frame
  /// of the swipe, before any await: the GUID_8/GUID_9 marker is written
  /// to the table only after an await, and while it is on the row the
  /// row's own fields read as the OPPOSITE state — a second swipe would
  /// send the reverse change. Held in memory rather than read from the
  /// marker, because a failed upload leaves the marker on the row.
  final Set<String> _inFlight = <String>{};

  Future<void> setReimbursementStatus(
    String receiptId,
    bool cancelReimbursement,
  ) async {
    if (!_inFlight.add(receiptId)) return;
    try {
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
    } finally {
      _inFlight.remove(receiptId);
    }
  }

  Future<void> setRemovedStatus(String receiptId, bool removed) async {
    if (!_inFlight.add(receiptId)) return;
    try {
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
    } finally {
      _inFlight.remove(receiptId);
    }
  }
}
