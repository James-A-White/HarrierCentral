// ignore_for_file: constant_identifier_names

import 'package:harrier_central/imports.dart';

class PaymentAggregate {
  PaymentAggregate({this.payment, required this.extensions});

  final PaymentQueryExtensionsModel extensions;
  final PaymentsModel? payment;

  bool isLoading = false;

  bool get isHashCredit {
    return (payment == null ||
            ((payment!.paymentType != paymentHashCredit.value) &&
                (payment!.paymentType != paymentHashCreditOtherAmount.value)))
        ? false
        : true;
  }
}

/// The footer of the payment report. Category lines show CONFIRMED money
/// only; unconfirmed bank transfers are split into their own "Card pending"
/// line so the category lines always sum to Total collected (2026-08-16, per
/// James's treasurer-reconciliation reading). Immutable and built by
/// [fromProductRows], which is pure and unit-tested.
class PaymentFooterTotals {
  const PaymentFooterTotals({
    this.runGross = 0, // product 1, incl. extras portion
    this.runPending = 0,
    this.memberGross = 0, // product 2
    this.memberPending = 0,
    this.habGross = 0, // product 3
    this.habPending = 0,
    this.pendingCount = 0,
    this.extrasPaid = 0,
    this.transactionCount = 0,
  });

  final double runGross;
  final double runPending;
  final double memberGross;
  final double memberPending;
  final double habGross;
  final double habPending;
  final int pendingCount;
  final double extrasPaid;
  final int transactionCount;

  double get pendingTotal => runPending + memberPending + habPending;
  double get totalCollected => runGross + memberGross + habGross - pendingTotal;

  /// One row per product category from the per-product SQL: gross recorded
  /// money, the unconfirmed bank-transfer slice of it, and extras.
  static PaymentFooterTotals fromProductRows(
    List<Map<String, dynamic>> productRows,
  ) {
    double runGross = 0, runPending = 0;
    double memberGross = 0, memberPending = 0;
    double habGross = 0, habPending = 0;
    int pendingCount = 0, transactionCount = 0;
    double extrasPaid = 0;
    for (final Map<String, dynamic> row in productRows) {
      final int product = (row['productType'] as num?)?.toInt() ?? 1;
      final double gross = (row['gross'] as num?)?.toDouble() ?? 0;
      final double pending = (row['pendingAmount'] as num?)?.toDouble() ?? 0;
      transactionCount += (row['txnCount'] as num?)?.toInt() ?? 0;
      pendingCount += (row['pendingCount'] as num?)?.toInt() ?? 0;
      if (product == productTypeMembership.value) {
        memberGross = gross;
        memberPending = pending;
      } else if (product == productTypeHaberdashery.value) {
        habGross = gross;
        habPending = pending;
      } else {
        runGross = gross;
        runPending = pending;
        extrasPaid = (row['extrasPaid'] as num?)?.toDouble() ?? 0;
      }
    }
    return PaymentFooterTotals(
      runGross: runGross,
      runPending: runPending,
      memberGross: memberGross,
      memberPending: memberPending,
      habGross: habGross,
      habPending: habPending,
      pendingCount: pendingCount,
      extrasPaid: extrasPaid,
      transactionCount: transactionCount,
    );
  }
}

/// State for the run's payment report: every attendee's payment row, the
/// chip filter, the per-type chip totals and the footer.
///
/// Migrated from a 1900-line State on 2026-09-23. The list is built locally
/// and assigned in one step; the paymentDelivered subscription is cancelled
/// in onClose; every `await` is followed by an `isClosed` check. The chip
/// filter and the footer maths are pure statics.
class PaymentReportController extends GetxController {
  PaymentReportController({required this.eventAggregate});

  final RunAdminAggregate eventAggregate;

  static const int ALL_PAYMENTS_FILTER_VALUE = 255;

  static String tagFor(String eventId) => 'payreport-$eventId';

  String get _eventId => eventAggregate.event.eventId;

  List<PaymentAggregate> _all = <PaymentAggregate>[];
  final RxList<PaymentAggregate> filteredList = <PaymentAggregate>[].obs;
  final RxBool isLoading = true.obs;
  final RxInt filterValue = ALL_PAYMENTS_FILTER_VALUE.obs;

  /// Indexed by paymentType (row 0 is "not paid"); the chips read it.
  final RxList<Map<String, dynamic>> paymentTotals =
      <Map<String, dynamic>>[].obs;
  final Rx<PaymentFooterTotals> footer = Rx<PaymentFooterTotals>(
    const PaymentFooterTotals(),
  );

  StreamSubscription<DataChangeEvent>? _paymentDeliveredSub;

  @override
  void onInit() {
    super.onInit();
    // A queued payment delivering while this report is open updates the
    // local tables — re-read them (no backend round trip needed) so the
    // rows and totals include it immediately.
    if (Get.isRegistered<DataChangeService>()) {
      _paymentDeliveredSub = Get.find<DataChangeService>().stream.listen((
        DataChangeEvent event,
      ) {
        if (event.type == DataChangeType.paymentDelivered &&
            event.id.toLowerCase() == _eventId.toLowerCase()) {
          unawaited(reload());
        }
      });
    }
    unawaited(pullToRefresh());
  }

  @override
  void onClose() {
    unawaited(_paymentDeliveredSub?.cancel());
    super.onClose();
  }

  /// Sync this run's admin data from the server, then re-read everything.
  Future<void> pullToRefresh() async {
    isLoading.value = true;
    await tableModel.syncEventAdminService.updateFromBackend(
      EnumDataTables.payments.flag |
          EnumDataTables.hasherEventMap.flag |
          EnumDataTables.hasherKennelMap.flag,
      true,
      _eventId,
    );
    if (isClosed) return;
    await reload();
    if (isClosed) return;
    isLoading.value = false;
  }

  /// Re-read the local tables: rows, then chip totals and footer.
  Future<void> reload() async {
    await _refreshListsFromTable();
    await refreshTotals();
  }

  /// A row's own spinner while its write is in flight.
  void markRowLoading(PaymentAggregate item) {
    item.isLoading = true;
    filteredList.refresh();
  }

  Future<void> _refreshListsFromTable() async {
    final offsetFromGmtToLocal = Utilities.getSqfliteTimeOffset();

    final String sql =
        '''
SELECT
    -- Payment table
    pay.*,
    -- Extensions
    hem.hemId AS pkHemId,
    COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colKennelHashName},
             COALESCE(
                CASE
                    WHEN hem.displayName IS NULL THEN NULL
                    ELSE hem.displayName || CASE
                        WHEN hem.virginVisitorType = 1 THEN ' (Virgin)'
                        ELSE ' (Visitor)'
                    END
                END, 
                h.dispName,
                '<hasher not found>'
             )
    ) AS paidByName,
    COALESCE(paidTo.dispName, '<hasher not found>') AS paidToName,
    CASE
        WHEN ((hkm.membershipExpirationDate IS NOT NULL) AND (julianday(hkm.membershipExpirationDate) >= julianday('now', '$offsetFromGmtToLocal'))) THEN 1
        ELSE 0
    END AS isMember,
    COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colDiscountAmount}, 0) AS discountAmountAvailable,
    COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colDiscountPercent}, 0) AS discountPercentAvailable,
    COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colDiscountDescription}, '') AS discountAvailableDescription,
    COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colFollowing}, 0) AS isFollowing,
    COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colKennelCredit}, 0) AS creditAvailable,
    COALESCE(e.eventPriceForMembers, k.defaultPriceForMembers, 0) AS eventPriceForMembers,
    COALESCE(e.eventPriceForNonMembers, k.defaultPriceForNonMembers, 0) AS eventPriceForNonMembers,
    COALESCE(confBy.dispName, '') AS confByName,
    COALESCE(e.${tableModel.eventsTableHelper.colExtrasDescription}, '<unknown>') AS extrasDescription,
    COALESCE(e.${tableModel.eventsTableHelper.colEventPriceForExtras}, 0) AS extrasPrice
    FROM ${EnumDataTables.hasherEventMap.eventTableName} hem
    INNER JOIN ${EnumDataTables.events.commonTableName} e ON e.eventId = hem.eventId
    INNER JOIN ${EnumDataTables.kennels.commonTableName} k ON k.kennelId = e.kennelId
    LEFT OUTER JOIN ${EnumDataTables.hasherKennelMap.eventTableName} hkm ON hkm.userId = hem.userId AND hkm.kennelId = "${eventAggregate.event.kennelId}"
    LEFT OUTER JOIN ${EnumDataTables.hashers.commonTableName} h ON h.hasherId = hem.userId
    LEFT OUTER JOIN ${EnumDataTables.payments.eventTableName} pay ON pay.hemId = hem.hemId AND pay.CancelledBy IS NULL AND COALESCE(pay.productType, 1) = 1
    LEFT OUTER JOIN ${EnumDataTables.hashers.commonTableName} paidTo ON paidTo.hasherId = pay.paidTo
    LEFT OUTER JOIN ${EnumDataTables.hashers.commonTableName} confBy ON confBy.hasherId = pay.confirmedBy
    WHERE hem.attendenceState >= 20
    ''';

    final List<PaymentAggregate> next = <PaymentAggregate>[];
    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(sql);
      for (int i = 0; i < results.length; i++) {
        PaymentsModel? paymentItem;
        if (results[i]['paymentId'] != null) {
          paymentItem = tableModel.paymentsTableHelper.fromMap(results[i]);
        }
        final PaymentQueryExtensionsModel extensions =
            PaymentQueryExtensionsModel.fromMap(results[i]);
        next.add(
          PaymentAggregate(payment: paymentItem, extensions: extensions),
        );
      }
    } catch (e, s) {
      BootLogger.logError(
        '[PaymentReport._refreshListsFromTable] eventId=$_eventId',
        e,
        s,
      );
    }

    // Fold membership + haberdashery payments into the same list as their
    // own rows, then sort everything together by name.
    await _appendNonRunPayments(next);

    next.sort(
      (PaymentAggregate a, PaymentAggregate b) =>
          a.extensions.paidByName.compareTo(b.extensions.paidByName),
    );
    if (isClosed) return;
    _all = next;
    _applyFilter();
  }

  /// Appends membership (productType 2) and haberdashery (3) payments to
  /// [target] as their own rows — one line per non-run payment, so a
  /// hasher who ran, renewed and bought haberdashery on the same day shows
  /// three lines. Each is a real PaymentAggregate (same shape as a run
  /// payment) so it renders and opens the detail popup the same way.
  Future<void> _appendNonRunPayments(List<PaymentAggregate> target) async {
    final String offsetFromGmtToLocal = Utilities.getSqfliteTimeOffset();
    try {
      final String sql =
          '''
      SELECT pay.*,
        hem.hemId AS pkHemId,
        COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colKennelHashName},
                 h.dispName, hem.displayName, '<no name>') AS paidByName,
        COALESCE(paidTo.dispName, '') AS paidToName,
        CASE
          WHEN ((hkm.membershipExpirationDate IS NOT NULL) AND (julianday(hkm.membershipExpirationDate) >= julianday('now', '$offsetFromGmtToLocal'))) THEN 1
          ELSE 0
        END AS isMember
      FROM ${EnumDataTables.payments.eventTableName} pay
      INNER JOIN ${EnumDataTables.hasherEventMap.eventTableName} hem ON hem.hemId = pay.hemId
      LEFT OUTER JOIN ${EnumDataTables.hashers.commonTableName} h ON h.hasherId = hem.userId
      LEFT OUTER JOIN ${EnumDataTables.hasherKennelMap.eventTableName} hkm
        ON hkm.userId = hem.userId AND hkm.kennelId = "${eventAggregate.event.kennelId}"
      LEFT OUTER JOIN ${EnumDataTables.hashers.commonTableName} paidTo ON paidTo.hasherId = pay.paidTo
      WHERE pay.cancelledBy IS NULL AND COALESCE(pay.productType, 1) != 1
      ''';
      final List<Map<String, dynamic>> rows = await database.rawQuery(sql);
      for (final Map<String, dynamic> row in rows) {
        target.add(
          PaymentAggregate(
            payment: tableModel.paymentsTableHelper.fromMap(row),
            extensions: PaymentQueryExtensionsModel.fromMap(row),
          ),
        );
      }
    } catch (e, s) {
      BootLogger.logError('[PaymentReport._appendNonRunPayments]', e, s);
    }
  }

  Future<void> refreshTotals() async {
    try {
      final String sql =
          '''

          -- start with the 'not paid' case
          SELECT 0 as paymentType, 
          (
            SELECT COUNT(*) 
            FROM ${EnumDataTables.hasherEventMap.eventTableName} hem 
            WHERE  hem.attendenceState >= 20
            AND hem.hemId not in (SELECT hemId from ${EnumDataTables.payments.eventTableName} pay3 where pay3.cancelledBy IS NULL AND COALESCE(pay3.productType, 1) = 1) 
          ) as count, 
          0.0 as totalCollected,
          0.0 as totalDebited,
          0.0 as extrasPaid
            
          UNION
          -- Per-payment-type chip totals across ALL products (2026-08-16):
          -- run payments keep their attendee (>= 20) scope; membership and
          -- haberdashery rows count regardless of attendance, matching the
          -- rows the list shows when a chip's filter is tapped.
          SELECT paymentType,
            (
                SELECT COUNT(*)
                FROM ${EnumDataTables.payments.eventTableName} pay
                INNER JOIN ${EnumDataTables.hasherEventMap.eventTableName} hem on hem.hemId = pay.hemId
                WHERE pay.paymentType = x.paymentType AND pay.cancelledBy IS NULL
                  AND (COALESCE(pay.productType, 1) != 1 OR hem.attendenceState >= 20)

            ) as count,
            (
                SELECT SUM(pay2.creditAmount)
                FROM ${EnumDataTables.payments.eventTableName} pay2
                INNER JOIN ${EnumDataTables.hasherEventMap.eventTableName} hem2 on hem2.hemId = pay2.hemId
                WHERE pay2.paymentType = x.paymentType AND pay2.cancelledBy IS NULL
                  AND (COALESCE(pay2.productType, 1) != 1 OR hem2.attendenceState >= 20)
            ) as totalCollected,
            (
                SELECT SUM(pay2.${tableModel.paymentsTableHelper.colDebitAmount})
                FROM ${EnumDataTables.payments.eventTableName} pay2
                INNER JOIN ${EnumDataTables.hasherEventMap.eventTableName} hem2 on hem2.hemId = pay2.hemId
                WHERE pay2.paymentType = x.paymentType AND pay2.cancelledBy IS NULL
                  AND (COALESCE(pay2.productType, 1) != 1 OR hem2.attendenceState >= 20)
            ) as totalDebited,
            (
                SELECT SUM(pay2.${tableModel.paymentsTableHelper.colDoPayForExtras})
                FROM ${EnumDataTables.payments.eventTableName} pay2
                INNER JOIN ${EnumDataTables.hasherEventMap.eventTableName} hem2 on hem2.hemId = pay2.hemId
                WHERE pay2.paymentType = x.paymentType AND pay2.cancelledBy IS NULL
                  AND (COALESCE(pay2.productType, 1) != 1 OR hem2.attendenceState >= 20)
            ) as extrasPaid
          FROM (SELECT 1 as paymentType union values (2), (3), (4), (5), (6), (7), (8) ) x

          ''';

      final List<Map<String, dynamic>> results = await database.rawQuery(sql);

      // Per-product footer totals: gross recorded money, the unconfirmed
      // bank-transfer slice of it, and extras, per product category.
      final String productSql =
          '''
          SELECT COALESCE(pay.productType, 1) AS productType,
            COUNT(*) AS txnCount,
            SUM(pay.creditAmount) AS gross,
            SUM(CASE WHEN pay.paymentType IN (${paymentBankTransfer.value}, ${paymentBankTransferOtherAmount.value})
                      AND pay.confirmedBy IS NULL THEN pay.creditAmount ELSE 0 END) AS pendingAmount,
            SUM(CASE WHEN pay.paymentType IN (${paymentBankTransfer.value}, ${paymentBankTransferOtherAmount.value})
                      AND pay.confirmedBy IS NULL THEN 1 ELSE 0 END) AS pendingCount,
            SUM(pay.${tableModel.paymentsTableHelper.colDoPayForExtras}) AS extrasPaid
          FROM ${EnumDataTables.payments.eventTableName} pay
          INNER JOIN ${EnumDataTables.hasherEventMap.eventTableName} hem ON hem.hemId = pay.hemId
          WHERE pay.cancelledBy IS NULL AND pay.paymentType > 1
            AND (COALESCE(pay.productType, 1) != 1 OR hem.attendenceState >= 20)
          GROUP BY COALESCE(pay.productType, 1)
          ''';
      final List<Map<String, dynamic>> productRows = await database.rawQuery(
        productSql,
      );
      if (isClosed) return;
      paymentTotals.assignAll(results);
      footer.value = PaymentFooterTotals.fromProductRows(productRows);
    } catch (e, s) {
      BootLogger.logError(
        '[PaymentReport._getTransactionCount] eventId=$_eventId',
        e,
        s,
      );
    }
  }

  Future<List<dynamic>> payForEvent(
    PaymentAggregate item,
    int paymentType,
    double amount, {
    EnumPayForExtras doPayForExtras = payForRunOnly,
    OtherPaymentPopupResult? otherPaymentPopupResult,
  }) async {
    // Through the outbox: captured before sending, retried idempotently
    // until the server acknowledges (covers corrections, confirms and
    // cancels made from this report too).
    final PaymentSubmitOutcome outcome = await Get.find<PaymentOutboxService>()
        .submit(
          PaymentsService.buildPending(
            eventId: _eventId,
            hasherId: GUID_EMPTY,
            hasherEventMapId: item.extensions.pkHemId,
            paymentType: paymentType,
            paymentAmount: amount,
            minimumAttendenceValue: attendenceAtHash.value,
            doPayForExtras: doPayForExtras,
            appDomainType: AppDomainType.event,
            specialRunPrice: otherPaymentPopupResult?.specialPriceAmount,
            specialRunPriceReason: otherPaymentPopupResult?.specialPriceReason,
            useSpecialPriceAsDefault:
                otherPaymentPopupResult?.useSpecialPriceAsDefault ?? false,
            displayLabel: 'Payment update — ${item.extensions.paidByName}',
          ),
        );
    if (outcome.queued) {
      showHcSnackbar(
        'No connection — the change for ${item.extensions.paidByName} '
        'is saved on this phone and will send automatically.',
      );
    }
    return outcome.results;
  }

  /// Which rows the chip filter keeps. [filterValue] is a bit set over the
  /// payment types; ALL_PAYMENTS_FILTER_VALUE shows only the unpaid. Pure.
  static List<PaymentAggregate> filtered(
    List<PaymentAggregate> all,
    int filterValue,
  ) {
    int typeOf(PaymentAggregate evt) =>
        evt.payment?.paymentType ?? paymentTypeUnknown.value;
    final List<PaymentAggregate> out = all
        .where(
          (PaymentAggregate evt) =>
              ((filterValue == ALL_PAYMENTS_FILTER_VALUE) &&
                  (evt.payment?.paymentType == null)) ||
              ((filterValue & 1) != 0 &&
                  ((evt.payment?.paymentType == null) ||
                      (typeOf(evt) == paymentNotPaid.value))) ||
              ((filterValue & 2) != 0 && typeOf(evt) == paymentCash.value) ||
              ((filterValue & 4) != 0 &&
                  typeOf(evt) == paymentCashOtherAmount.value) ||
              ((filterValue & 8) != 0 && typeOf(evt) == paymentFreeRun.value) ||
              ((filterValue & 16) != 0 &&
                  typeOf(evt) == paymentBankTransfer.value) ||
              ((filterValue & 32) != 0 &&
                  typeOf(evt) == paymentBankTransferOtherAmount.value) ||
              ((filterValue & 64) != 0 &&
                  typeOf(evt) == paymentHashCredit.value) ||
              ((filterValue & 128) != 0 &&
                  typeOf(evt) == paymentHashCreditOtherAmount.value),
        )
        .toList();
    out.sort(
      (PaymentAggregate a, PaymentAggregate b) =>
          a.extensions.paidByName.compareTo(b.extensions.paidByName),
    );
    return out;
  }

  void _applyFilter() {
    filteredList.assignAll(filtered(_all, filterValue.value));
  }

  /// A chip tap: from "all" to just that type; then toggles types; back to
  /// "all" when nothing is left selected. Pure in [nextFilter].
  static int nextFilter(int current, int positionFlag) {
    int next = current == ALL_PAYMENTS_FILTER_VALUE
        ? positionFlag
        : current ^ positionFlag;
    if (next == 0) next = ALL_PAYMENTS_FILTER_VALUE;
    return next;
  }

  void filterTapped(int positionFlag) {
    filterValue.value = nextFilter(filterValue.value, positionFlag);
    _applyFilter();
  }
}
