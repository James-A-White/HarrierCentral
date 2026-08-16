// ignore_for_file: constant_identifier_names

import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

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

class PaymentReportPage extends StatefulWidget {
  const PaymentReportPage({super.key, required this.eventAggregate});

  final RunAdminAggregate eventAggregate;

  @override
  PaymentReportState createState() => PaymentReportState();
}

class PaymentReportState extends State<PaymentReportPage> {
  PaymentReportState();

  static const int ALL_PAYMENTS_FILTER_VALUE = 255;

  final List<PaymentAggregate> _paymentsList = <PaymentAggregate>[];
  final List<PaymentAggregate> _filteredList = <PaymentAggregate>[];

  bool _isLoading = true;

  int _filterValue = ALL_PAYMENTS_FILTER_VALUE;

  @override
  void initState() {
    super.initState();
    unawaited(initStateAsync());
  }

  Future<void> initStateAsync() async {
    await _refreshSqlTablesFromBackend();
  }

  Future<void> _refreshSqlTablesFromBackend() async {
    setStateIfMounted(() {
      _isLoading = true;
    });

    await tableModel.syncEventAdminService.updateFromBackend(
      EnumDataTables.payments.flag |
          EnumDataTables.hasherEventMap.flag |
          EnumDataTables.hasherKennelMap.flag,
      true,
      widget.eventAggregate.event.eventId,
    );
    //final String resultStr = result ? 'successfully' : 'unsuccessfully';
    //print('Payments data synchronized $resultStr');

    await _refreshListsFromTable();
    await refreshTotals();
    _isLoading = false;
    setStateIfMounted(() {});
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
    LEFT OUTER JOIN ${EnumDataTables.hasherKennelMap.eventTableName} hkm ON hkm.userId = hem.userId AND hkm.kennelId = "${widget.eventAggregate.event.kennelId}"
    LEFT OUTER JOIN ${EnumDataTables.hashers.commonTableName} h ON h.hasherId = hem.userId
    LEFT OUTER JOIN ${EnumDataTables.payments.eventTableName} pay ON pay.hemId = hem.hemId AND pay.CancelledBy IS NULL AND COALESCE(pay.productType, 1) = 1
    LEFT OUTER JOIN ${EnumDataTables.hashers.commonTableName} paidTo ON paidTo.hasherId = pay.paidTo
    LEFT OUTER JOIN ${EnumDataTables.hashers.commonTableName} confBy ON confBy.hasherId = pay.confirmedBy
    WHERE hem.attendenceState >= 20
    ''';

    final List<Map<String, dynamic>> results = await database.rawQuery(sql);

    _paymentsList.clear();

    for (int i = 0; i < results.length; i++) {
      PaymentsModel? paymentItem;

      if (results[i]['paymentId'] != null) {
        paymentItem = tableModel.paymentsTableHelper.fromMap(results[i]);
      }

      final PaymentQueryExtensionsModel extensions =
          PaymentQueryExtensionsModel.fromMap(results[i]);

      _paymentsList.add(
        PaymentAggregate(payment: paymentItem, extensions: extensions),
      );
    }

    // Fold membership + haberdashery payments into the same list as their
    // own rows, then sort everything together by name.
    await _appendNonRunPayments();

    _paymentsList.sort(
      (PaymentAggregate a, PaymentAggregate b) =>
          a.extensions.paidByName.compareTo(b.extensions.paidByName),
    );
    _applyFilter();
    setStateIfMounted(() {});
  }

  List<Map<String, dynamic>> _paymentTotals = <Map<String, dynamic>>[];

  // Per-product footer totals (2026-08-16). Category lines show CONFIRMED
  // money only; unconfirmed bank transfers are split into their own "Card
  // pending" line so the category lines always sum to Total collected.
  double _runGross = 0; // product 1, incl. extras portion
  double _runPending = 0;
  double _memberGross = 0; // product 2
  double _memberPending = 0;
  double _habGross = 0; // product 3
  double _habPending = 0;
  int _pendingCount = 0;
  double _extrasPaid = 0;
  int _transactionCount = 0;

  double get _pendingTotal => _runPending + _memberPending + _habPending;
  double get _totalCollected =>
      _runGross + _memberGross + _habGross - _pendingTotal;

  /// Appends membership (productType 2) and haberdashery (3) payments to
  /// [_paymentsList] as their own rows — one line per non-run payment, so a
  /// hasher who ran, renewed and bought haberdashery on the same day shows
  /// three lines. Each is a real PaymentAggregate (same shape as a run
  /// payment) so it renders and opens the detail popup the same way.
  Future<void> _appendNonRunPayments() async {
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
        ON hkm.userId = hem.userId AND hkm.kennelId = "${widget.eventAggregate.event.kennelId}"
      LEFT OUTER JOIN ${EnumDataTables.hashers.commonTableName} paidTo ON paidTo.hasherId = pay.paidTo
      WHERE pay.cancelledBy IS NULL AND COALESCE(pay.productType, 1) != 1
      ''';
      final List<Map<String, dynamic>> rows = await database.rawQuery(sql);
      for (final Map<String, dynamic> row in rows) {
        _paymentsList.add(
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
    _paymentTotals = <Map<String, dynamic>>[];

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

      setStateIfMounted(() {
        _paymentTotals = results;
        _runGross = 0;
        _runPending = 0;
        _memberGross = 0;
        _memberPending = 0;
        _habGross = 0;
        _habPending = 0;
        _pendingCount = 0;
        _extrasPaid = 0;
        _transactionCount = 0;
        for (final Map<String, dynamic> row in productRows) {
          final int product = (row['productType'] as num?)?.toInt() ?? 1;
          final double gross = (row['gross'] as num?)?.toDouble() ?? 0;
          final double pending =
              (row['pendingAmount'] as num?)?.toDouble() ?? 0;
          _transactionCount += (row['txnCount'] as num?)?.toInt() ?? 0;
          _pendingCount += (row['pendingCount'] as num?)?.toInt() ?? 0;
          if (product == productTypeMembership.value) {
            _memberGross = gross;
            _memberPending = pending;
          } else if (product == productTypeHaberdashery.value) {
            _habGross = gross;
            _habPending = pending;
          } else {
            _runGross = gross;
            _runPending = pending;
            _extrasPaid = (row['extrasPaid'] as num?)?.toDouble() ?? 0;
          }
        }
      });
    } catch (e, s) {
      BootLogger.logError(
        '[PaymentReport._getTransactionCount] eventId=${widget.eventAggregate.event.eventId}',
        e,
        s,
      );
    }
  }

  Future<List<dynamic>> _payForEvent(
    PaymentAggregate item,
    int paymentType,
    double amount, {
    EnumPayForExtras doPayForExtras = payForRunOnly,
    OtherPaymentPopupResult? otherPaymentPopupResult,
  }) {
    final PaymentsService paySrv = PaymentsService();
    return paySrv.payForEvent(
      widget.eventAggregate.event.eventId,
      GUID_EMPTY,
      item.extensions.pkHemId,
      paymentType,
      amount,
      attendenceAtHash.value,
      doPayForExtras,
      AppDomainType.event,
      specialRunPrice: otherPaymentPopupResult?.specialPriceAmount,
      specialRunPriceReason: otherPaymentPopupResult?.specialPriceReason,
      useSpecialPriceAsDefault:
          otherPaymentPopupResult?.useSpecialPriceAsDefault ?? false,
    );
  }

  void _applyFilter() {
    _filteredList.clear();
    _filteredList.addAll(
      _paymentsList
          .where(
            (PaymentAggregate evt) =>
                ((_filterValue == ALL_PAYMENTS_FILTER_VALUE) &&
                    (evt.payment?.paymentType == null)) ||
                ((_filterValue & 1) != 0 &&
                    ((evt.payment?.paymentType == null) ||
                        (((evt.payment?.paymentType ?? paymentTypeUnknown) ==
                            paymentNotPaid.value)))) ||
                ((_filterValue & 2) != 0 &&
                    ((evt.payment?.paymentType ?? paymentTypeUnknown) ==
                        paymentCash.value)) ||
                ((_filterValue & 4) != 0 &&
                    ((evt.payment?.paymentType ?? paymentTypeUnknown) ==
                        paymentCashOtherAmount.value)) ||
                ((_filterValue & 8) != 0 &&
                    ((evt.payment?.paymentType ?? paymentTypeUnknown) ==
                        paymentFreeRun.value)) ||
                ((_filterValue & 16) != 0 &&
                    ((evt.payment?.paymentType ?? paymentTypeUnknown) ==
                        paymentBankTransfer.value)) ||
                ((_filterValue & 32) != 0 &&
                    ((evt.payment?.paymentType ?? paymentTypeUnknown) ==
                        paymentBankTransferOtherAmount.value)) ||
                ((_filterValue & 64) != 0 &&
                    ((evt.payment?.paymentType ?? paymentTypeUnknown) ==
                        paymentHashCredit.value)) ||
                ((_filterValue & 128) != 0 &&
                    ((evt.payment?.paymentType ?? paymentTypeUnknown) ==
                        paymentHashCreditOtherAmount.value)),
          )
          .toList(),
    );

    _filteredList.sort(
      (PaymentAggregate a, PaymentAggregate b) =>
          a.extensions.paidByName.compareTo(b.extensions.paidByName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text(
          widget.eventAggregate.event.eventName,
          style: ts_appBarTitle,
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 25.0),
        child: SpeedDial(
          // both default to 16
          // marginEnd: 18,
          // marginBottom: 20,
          animatedIcon: AnimatedIcons.menu_close,
          animatedIconTheme: const IconThemeData(size: 22.0),
          // this is ignored if animatedIcon is non null
          // child:const  Icon(Icons.add),
          visible: true,
          curve: Curves.bounceIn,
          overlayColor: Colors.black,
          overlayOpacity: 0.5,
          onOpen: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          //onClose: () => //print('DIAL CLOSED'),
          tooltip: 'Speed Dial',
          heroTag: 'speed-dial-hero-tag-62345',
          backgroundColor: hc_red,
          foregroundColor: Colors.white,
          elevation: 8.0,
          shape: const CircleBorder(),
          children: <SpeedDialChild>[
            SpeedDialChild(
              child: const Icon(Icons.mail_outline),
              backgroundColor: Colors.green,
              label: 'Email me payment report',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () async {
                final Map<String, String?> result = await tableModel
                    .paymentsService
                    .sendPaymentReportByEmail(
                      eventId: widget.eventAggregate.event.eventId,
                      eventName: widget.eventAggregate.event.eventName,
                    );

                if (!mounted) return;
                ScaffoldMessenger.of(
                  navigatorKey.currentContext!,
                ).hideCurrentSnackBar();
                if ((result['result'] != null) &&
                    (result['result']!.toLowerCase().startsWith('success'))) {
                  await Utilities.showAlert(
                    'E-mail successfully sent',
                    'Your payment report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.',
                    'OK',
                  );
                } else {
                  await Utilities.showAlert(
                    'Error sending report',
                    'There was a problem sending the report to:\r\n\r\n${result['email']}\r\n\r\nPlease try again later or contact us at harriercentral@gmail.com',
                    'OK',
                  );
                }

                IveCoreUtilities.showInSnackBar(
                  navigatorKey.currentContext!,
                  'Payment Report being processed...',
                  durationInSeconds: 10,
                );
              },
            ),
          ],
        ),
      ),
      body: (_isLoading || (_paymentTotals.isEmpty))
          ? const HcAppCircularProgressIndicator(key: Key('112209596'))
          : Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(
                    // border: new Border.all(width: 1.0, color: Colors.black),
                    //shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color.fromARGB(70, 0, 0, 0),
                        offset: Offset(0.0, 6.0),
                        blurRadius: 10.0,
                      ),
                    ],
                  ),
                  height: 120.0,
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          PaymentTotalsCell(
                            creditAmount: 0,
                            counter:
                                _paymentTotals[0]['count'] +
                                _paymentTotals[paymentNotPaid.value]['count'],
                            color: (_filterValue & 1) != 0
                                ? hc_red
                                : Colors.black26,
                            paymentRecordType: paymentNotPaid,
                            currencySymbol:
                                widget.eventAggregate.extensions.curSym,
                            digitsAfterDecimal:
                                widget.eventAggregate.extensions.digAfterDec,
                            onTap: () {
                              _filterTapped(1);
                            },
                          ),
                          PaymentTotalsCell(
                            creditAmount:
                                _paymentTotals[paymentCash
                                        .value]['totalCollected']
                                    ?.toDouble() ??
                                0.0,
                            counter: _paymentTotals[paymentCash.value]['count'],
                            color: (_filterValue & 2) != 0
                                ? Colors.green
                                : Colors.black26,
                            paymentRecordType: paymentCash,
                            currencySymbol:
                                widget.eventAggregate.extensions.curSym,
                            digitsAfterDecimal:
                                widget.eventAggregate.extensions.digAfterDec,
                            onTap: () {
                              _filterTapped(2);
                            },
                          ),
                          PaymentTotalsCell(
                            creditAmount:
                                _paymentTotals[paymentBankTransfer
                                        .value]['totalCollected']
                                    ?.toDouble() ??
                                0.0,
                            counter:
                                _paymentTotals[paymentBankTransfer
                                    .value]['count'],
                            color: (_filterValue & 16) != 0
                                ? Colors.green
                                : Colors.black26,
                            paymentRecordType: paymentBankTransfer,
                            currencySymbol:
                                widget.eventAggregate.extensions.curSym,
                            digitsAfterDecimal:
                                widget.eventAggregate.extensions.digAfterDec,
                            onTap: () {
                              _filterTapped(16);
                            },
                          ),
                          PaymentTotalsCell(
                            creditAmount:
                                _paymentTotals[paymentFreeRun
                                        .value]['totalCollected']
                                    ?.toDouble() ??
                                0.0,
                            counter:
                                _paymentTotals[paymentFreeRun.value]['count'],
                            color: (_filterValue & 8) != 0
                                ? Colors.green
                                : Colors.black26,
                            paymentRecordType: paymentFreeRun,
                            currencySymbol:
                                widget.eventAggregate.extensions.curSym,
                            digitsAfterDecimal:
                                widget.eventAggregate.extensions.digAfterDec,
                            onTap: () {
                              _filterTapped(8);
                            },
                          ),
                          PaymentTotalsCell(
                            creditAmount:
                                -((_paymentTotals[paymentHashCredit
                                            .value]['totalDebited']
                                        ?.toDouble()) ??
                                    0.0),
                            counter:
                                _paymentTotals[paymentHashCredit
                                    .value]['count'],
                            color: (_filterValue & 64) != 0
                                ? Colors.green
                                : Colors.black26,
                            paymentRecordType: paymentHashCredit,
                            currencySymbol:
                                widget.eventAggregate.extensions.curSym,
                            digitsAfterDecimal:
                                widget.eventAggregate.extensions.digAfterDec,
                            onTap: () {
                              _filterTapped(64);
                            },
                          ),
                          PaymentTotalsCell(
                            creditAmount:
                                _paymentTotals[paymentCashOtherAmount
                                        .value]['totalCollected']
                                    ?.toDouble() ??
                                0.0,
                            counter:
                                _paymentTotals[paymentCashOtherAmount
                                    .value]['count'],
                            color: (_filterValue & 4) != 0
                                ? Colors.green
                                : Colors.black26,
                            paymentRecordType: paymentCashOtherAmount,
                            currencySymbol:
                                widget.eventAggregate.extensions.curSym,
                            digitsAfterDecimal:
                                widget.eventAggregate.extensions.digAfterDec,
                            onTap: () {
                              _filterTapped(4);
                            },
                          ),
                          PaymentTotalsCell(
                            creditAmount:
                                _paymentTotals[paymentBankTransferOtherAmount
                                        .value]['totalCollected']
                                    ?.toDouble() ??
                                0.0,
                            counter:
                                _paymentTotals[paymentBankTransferOtherAmount
                                    .value]['count'],
                            color: (_filterValue & 32) != 0
                                ? Colors.green
                                : Colors.black26,
                            paymentRecordType: paymentBankTransferOtherAmount,
                            currencySymbol:
                                widget.eventAggregate.extensions.curSym,
                            digitsAfterDecimal:
                                widget.eventAggregate.extensions.digAfterDec,
                            onTap: () {
                              _filterTapped(32);
                            },
                          ),
                          PaymentTotalsCell(
                            creditAmount:
                                -((_paymentTotals[paymentHashCreditOtherAmount
                                            .value]['totalDebited']
                                        ?.toDouble()) ??
                                    0.0),
                            counter:
                                _paymentTotals[paymentHashCreditOtherAmount
                                    .value]['count'],
                            color: (_filterValue & 128) != 0
                                ? Colors.green
                                : Colors.black26,
                            paymentRecordType: paymentHashCreditOtherAmount,
                            currencySymbol:
                                widget.eventAggregate.extensions.curSym,
                            digitsAfterDecimal:
                                widget.eventAggregate.extensions.digAfterDec,
                            onTap: () {
                              _filterTapped(128);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: _filteredList.isEmpty
                        ? Center(
                            child: Text(
                              'No transactions available.',
                              style: ts_titleBlack,
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _refreshSqlTablesFromBackend,
                            displacement: 40.0,
                            child: ListView.separated(
                              separatorBuilder:
                                  (BuildContext context, int index) =>
                                      const Divider(
                                        height: 1.0,
                                        color: Colors.black45,
                                      ),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _filteredList.length + 1,
                              itemBuilder: (BuildContext context, int index) {
                                if (index == _filteredList.length) {
                                  return Container(height: 100);
                                }
                                final bool needsConfirm =
                                    (((_filteredList[index]
                                                    .payment
                                                    ?.paymentType ??
                                                paymentTypeUnknown) ==
                                            paymentBankTransfer.value) ||
                                        ((_filteredList[index]
                                                    .payment
                                                    ?.paymentType ??
                                                paymentTypeUnknown) ==
                                            paymentBankTransferOtherAmount
                                                .value)) &&
                                    (_filteredList[index]
                                            .payment
                                            ?.confirmedBy ==
                                        null);
                                return (((_filteredList[index]
                                                    .payment
                                                    ?.paymentType ??
                                                paymentTypeUnknown.value) !=
                                            paymentTypeUnknown.value) &&
                                        (_filteredList[index]
                                                .payment
                                                ?.paymentType !=
                                            paymentNotPaid.value) &&
                                        !needsConfirm)
                                    ? _listItem(_filteredList[index], context)
                                    : Dismissible(
                                        key: Key(index.toString()),
                                        confirmDismiss:
                                            (DismissDirection direction) async {
                                              //print(direction.toString() + ' ' + index.toString() + ' ' + widget.eventAggregate.extensions.nonMemberPrice.toString());
                                              setStateIfMounted(() {
                                                _filteredList[index].isLoading =
                                                    true;
                                              });
                                              if (needsConfirm) {
                                                await _payForEvent(
                                                  _filteredList[index],
                                                  paymentConfirmBankTransfer
                                                      .value,
                                                  -1,
                                                );
                                                await _refreshListsFromTable();
                                                await refreshTotals();
                                                setStateIfMounted(() {});
                                              } else {
                                                final double paymentAmount =
                                                    (_filteredList[index]
                                                            .extensions
                                                            .isMember !=
                                                        0)
                                                    ? _filteredList[index]
                                                          .extensions
                                                          .eventPriceForMembers
                                                    : _filteredList[index]
                                                          .extensions
                                                          .eventPriceForNonMembers;
                                                await _showExtrasDialog(
                                                  context,
                                                  direction ==
                                                          DismissDirection
                                                              .endToStart
                                                      ? paymentCash.value
                                                      : paymentBankTransfer
                                                            .value,
                                                  _filteredList[index],
                                                  paymentAmount,
                                                );
                                              }
                                              return Future<bool>.value(false);
                                            },
                                        background: needsConfirm
                                            ? Container(
                                                color: Colors.purple,
                                                child: Row(
                                                  children: <Widget>[
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 15.0,
                                                          ),
                                                      child: Image.asset(
                                                        'images/icons/payment_type_4.png',
                                                        height: 25.0,
                                                        width: 25.0,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 15.0,
                                                          ),
                                                      child: Text(
                                                        'Confirm Bank Transfer',
                                                        style: ts_titleMedium,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Container(
                                                color: hc_blue,
                                                child: Row(
                                                  children: <Widget>[
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 15.0,
                                                          ),
                                                      child: Image.asset(
                                                        'images/icons/payment_type_4.png',
                                                        height: 25.0,
                                                        width: 25.0,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 15.0,
                                                          ),
                                                      child: Text(
                                                        '${(widget.eventAggregate.event.eventPriceForExtras ?? 0) != 0 ? '' : '${IveCoreUtilities.getFormattedMoney((_filteredList[index].extensions.isMember != 0) ? _filteredList[index].extensions.eventPriceForMembers : _filteredList[index].extensions.eventPriceForNonMembers, widget.eventAggregate.extensions.digAfterDec, widget.eventAggregate.extensions.curSym)} '}Bank Transfer',
                                                        style: ts_titleMedium,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                        secondaryBackground: needsConfirm
                                            ? Container(
                                                color: Colors.purple,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: <Widget>[
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 15.0,
                                                          ),
                                                      child: Image.asset(
                                                        'images/icons/payment_type_4.png',
                                                        height: 25.0,
                                                        width: 25.0,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 15.0,
                                                          ),
                                                      child: Text(
                                                        'Confirm bank transfer',
                                                        style: ts_titleMedium,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Container(
                                                color: Colors.green,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: <Widget>[
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 15.0,
                                                          ),
                                                      child: Image.asset(
                                                        'images/icons/payment_type_3.png',
                                                        height: 25.0,
                                                        width: 25.0,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 15.0,
                                                          ),
                                                      child: Text(
                                                        '${(widget.eventAggregate.event.eventPriceForExtras ?? 0) != 0 ? '' : '${IveCoreUtilities.getFormattedMoney((_filteredList[index].extensions.isMember != 0) ? _filteredList[index].extensions.eventPriceForMembers : _filteredList[index].extensions.eventPriceForNonMembers, widget.eventAggregate.extensions.digAfterDec, widget.eventAggregate.extensions.curSym)} '}Cash',
                                                        style: ts_titleMedium,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                        onDismissed: (DismissDirection direction) {
                                          //print(direction.toString() + ' NOTE: We should never reach this point');
                                        },
                                        child: _listItem(
                                          _filteredList[index],
                                          context,
                                        ),
                                      );
                              },
                            ),
                          ),
                  ),
                ),
                Container(
                  width: 9999.0,
                  padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 16.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color.fromARGB(70, 0, 0, 0),
                        offset: Offset(0.0, -6.0),
                        blurRadius: 10.0,
                      ),
                    ],
                  ),
                  child: _buildTotalsFooter(),
                ),
              ],
            ),
    );
  }

  Future<void> _showExtrasDialog(
    BuildContext context,
    int paymentType,
    PaymentAggregate packMember,
    double paymentAmount, {
    OtherPaymentPopupResult? otherPaymentPopupResult,
  }) async {
    ScaffoldMessenger.of(
      context,
    ).removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
    if (((paymentType == paymentFreeRun.value) ||
            (paymentType == paymentCash.value) ||
            (paymentType == paymentBankTransfer.value) ||
            (paymentType == paymentCashOtherAmount.value) ||
            (paymentType == paymentHashCredit.value) ||
            (paymentType == paymentBankTransferOtherAmount.value) ||
            (paymentType == paymentHashCreditOtherAmount.value)) &&
        ((widget.eventAggregate.event.eventPriceForExtras ?? 0) != 0)) {
      final double runOnlyPrice = packMember.extensions.isMember != 0
          ? widget.eventAggregate.extensions.memberPrice
          : widget.eventAggregate.extensions.nonMemberPrice;
      final double runPlusExtrasPrice =
          runOnlyPrice +
          (widget.eventAggregate.event.eventPriceForExtras ?? 0.0);

      final String runOnlyPriceStr = IveCoreUtilities.getFormattedMoney(
        runOnlyPrice,
        widget.eventAggregate.extensions.digAfterDec,
        widget.eventAggregate.extensions.curSym,
      );
      final String runPlusExtrasPriceStr = IveCoreUtilities.getFormattedMoney(
        runPlusExtrasPrice,
        widget.eventAggregate.extensions.digAfterDec,
        widget.eventAggregate.extensions.curSym,
      );

      final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
        <String, dynamic>{
          'title': 'Run only ($runOnlyPriceStr)',
          'icon': <Widget>[Container()],
          'returnValue': payForRunOnly,
        },
        <String, dynamic>{
          'title':
              'Run + ${widget.eventAggregate.event.extrasDescription} ($runPlusExtrasPriceStr)',
          'icon': <Widget>[Container()],
          'returnValue': payForRunAndExtras,
        },
      ];

      final MultipleChoicePopupHc popup = MultipleChoicePopupHc(
        key: const Key('125550929'),
        title: 'Payment options',
        buttons: buttons,
        cancelButtonTitle: 'Cancel',
        cancelButtonReturnValue: followTypeCancel,
      );

      final dynamic payForExtras = await showDialog<dynamic>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return popup;
        },
      );
      final List<dynamic> results = await _payForEvent(
        packMember,
        paymentType,
        paymentAmount,
        doPayForExtras: payForExtras,
        otherPaymentPopupResult: otherPaymentPopupResult,
      );
      await _refreshListsFromTable();
      await refreshTotals();
      setStateIfMounted(() {
        BankTransferQr.showBankTransferSnackbar(
          widget.eventAggregate,
          results,
          paymentType,
          context,
          packMember.extensions.paidByName,
          packMember.extensions.isMember,
          paymentAmount,
        );
      });
    } else {
      // there are no extras so just pay for the run without any extras dialog
      final List<dynamic> results = await _payForEvent(
        packMember,
        paymentType,
        paymentAmount,
        doPayForExtras: payForRunOnly,
        otherPaymentPopupResult: otherPaymentPopupResult,
      );
      await _refreshListsFromTable();
      await refreshTotals();
      setStateIfMounted(() {
        BankTransferQr.showBankTransferSnackbar(
          widget.eventAggregate,
          results,
          paymentType,
          context,
          packMember.extensions.paidByName,
          packMember.extensions.isMember,
          paymentAmount,
        );
      });
    }
  }

  void _filterTapped(int positionFlag) {
    if (_filterValue == ALL_PAYMENTS_FILTER_VALUE) {
      _filterValue = positionFlag;
    } else {
      _filterValue = _filterValue ^ positionFlag;
    }

    if (_filterValue == 0) {
      _filterValue = ALL_PAYMENTS_FILTER_VALUE;
    }

    _applyFilter();
    setStateIfMounted(() {});
  }

  /// Human label for a payment's product type, shown in the detail popup.
  String _productLabel(int productType) {
    if (productType == productTypeMembership.value) return 'Annual subscription';
    if (productType == productTypeHaberdashery.value) return 'Haberdashery';
    return 'Run fee';
  }

  /// Footer totals: one line per product category with activity (confirmed
  /// money only), extras when the event has them configured, and an explicit
  /// "Card pending" line for unconfirmed bank transfers — the category lines
  /// plus pending always sum to the recorded gross, and "Total collected"
  /// means verified money (2026-08-16, per James's treasurer-reconciliation
  /// reading).
  Widget _buildTotalsFooter() {
    String money(double amount) => IveCoreUtilities.getFormattedMoney(
      amount,
      widget.eventAggregate.extensions.digAfterDec,
      widget.eventAggregate.extensions.curSym,
    );

    final double extrasPrice =
        widget.eventAggregate.event.eventPriceForExtras ?? 0;
    final String? extrasDescription =
        widget.eventAggregate.event.extrasDescription;
    // '<null>' is a legacy sentinel that used to print literally in this
    // footer ("<null> paid: 0 for £0.00" on events with no extras).
    final bool extrasConfigured =
        extrasPrice != 0 &&
        extrasDescription != null &&
        extrasDescription.trim().isNotEmpty &&
        extrasDescription != '<null>';
    final double extrasAmount = extrasConfigured
        ? extrasPrice * _extrasPaid
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Total transactions: $_transactionCount', style: ts_titleBlack),
        Text(
          'Run fees: ${money(_runGross - _runPending - extrasAmount)}',
          style: ts_titleBlack,
        ),
        if (extrasConfigured)
          Text(
            '$extrasDescription paid: ${_extrasPaid.toInt()} for ${money(extrasAmount)}',
            style: ts_titleBlack,
          ),
        if (_memberGross > 0 || _memberPending > 0)
          Text(
            'Memberships: ${money(_memberGross - _memberPending)}',
            style: ts_titleBlack,
          ),
        if (_habGross > 0 || _habPending > 0)
          Text(
            'Haberdashery: ${money(_habGross - _habPending)}',
            style: ts_titleBlack,
          ),
        if (_pendingCount > 0)
          Text(
            'Card pending: ${money(_pendingTotal)} ($_pendingCount to confirm)',
            style: ts_titleBlack.copyWith(color: Colors.amber.shade900),
          ),
        Text(
          'Total collected: ${money(_totalCollected)}',
          style: ts_titleBlack,
        ),
      ],
    );
  }

  Container _listItem(PaymentAggregate item, BuildContext topContext) {
    return Container(
      height: 60.0,
      padding: const EdgeInsets.only(top: 10),
      child: PaymentReportListItem(
        currencySymbol: widget.eventAggregate.extensions.curSym,
        digitsAfterDecimal: widget.eventAggregate.extensions.digAfterDec,
        paymentReportItem: item,
        onTap: () async {
          ScaffoldMessenger.of(topContext).hideCurrentSnackBar();
          if ((item.payment == null) ||
              (item.payment!.paymentType == paymentTypeUnknown.value) ||
              (item.payment!.paymentType == paymentNotPaid.value)) {
            double amountOwed = item.extensions.isMember != 1
                ? widget.eventAggregate.extensions.nonMemberPrice
                : widget.eventAggregate.extensions.memberPrice;
            amountOwed -= item.extensions.discountAmountAvailable;
            amountOwed -=
                amountOwed * (item.extensions.discountPercentAvailable / 100.0);

            final PaymentPopup pp = PaymentPopup(
              amount: amountOwed,
              creditAllowed: widget.eventAggregate.kennel.allowCredit,
              creditRemaining: item.extensions.creditAvailable,
              currencySymbol: widget.eventAggregate.extensions.curSym,
              hemId: item.extensions.pkHemId,
              decimalDigits: widget.eventAggregate.extensions.digAfterDec,
              allowDefaultPricing:
                  (item.extensions.isMember != 0) ||
                  (item.extensions.isFollowing != 0),
              // valueChanged: (num value) {
              //   finalValue = value;
              // },
            );

            final PaymentPopupResult? ppResult =
                await showDialog<PaymentPopupResult>(
                  context: context,
                  barrierDismissible: false, // user must tap button!
                  builder: (BuildContext context) {
                    return pp;
                  },
                );

            if (ppResult != null) {
              if (ppResult.transactionType != -1) {
                setStateIfMounted(() {
                  item.isLoading = true;
                });

                //final num paymentAmount = (item.extensions.isMember != 0) ? item.extensions.eventPriceForMembers : item.extensions.eventPriceForNonMembers;
                if (!mounted) return;
                await _showExtrasDialog(
                  context,
                  ppResult.transactionType,
                  item,
                  ppResult.transactionValue,
                  otherPaymentPopupResult: ppResult.otherPayment,
                );

                // payForEvent(item, paymentValue.transactionType, paymentValue.transactionValue).then((List<dynamic> results) {
                //   _refreshListsFromTable().then((void _) {
                //     setStateIfMounted(() {
                //       refreshTotals();
                //       BankTransferQr.showBankTransferSnackbar(widget.eventAggregate, results, paymentValue.transactionType, topContext, item.extensions.paidByName, item.extensions.isMember, paymentValue.transactionValue);
                //     });
                //   });
                // });
              }
            }
          } else {
            final String action =
                await _displayPaymentDetails(item, context) ?? 'close';

            if (action == 'cancel') {
              setStateIfMounted(() {
                item.isLoading = true;
              });
              await _payForEvent(item, paymentNotPaid.value, 0);
              await _refreshListsFromTable();
              await refreshTotals();
              setStateIfMounted(() {});
            } else if (action == 'confirm') {
              setStateIfMounted(() {
                item.isLoading = true;
              });
              await _payForEvent(item, paymentConfirmBankTransfer.value, -1);
              await _refreshListsFromTable();
              await refreshTotals();
              setStateIfMounted(() {});
            }
          }
        },
      ),
    );
  }

  Future<String?> _displayPaymentDetails(
    PaymentAggregate item,
    BuildContext context,
  ) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        final TextStyle bodyStyleRed = ts_titleMediumBlack.copyWith(
          color: hc_red,
        );

        if (item.payment == null) {
          return AlertDialog(
            title: Text('Payment Detail', style: ts_alertDialogTitle),
            content: Text(
              'No payment record exists for this hasher.',
              style: ts_titleMediumBlack,
            ),
            actions: <Widget>[
              TextButton(
                style: text_button_style,
                child: Text('Close', style: ts_button),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop('close');
                },
              ),
            ],
          );
        } else {
          String paymentTypeStr = '';

          switch (item.payment!.paymentType) {
            case 1:
              paymentTypeStr = 'Not paid';
              break;
            case 2:
              paymentTypeStr = 'Free run';
              break;
            case 3:
              paymentTypeStr = 'Cash';
              break;
            case 4:
              paymentTypeStr = 'Bank transfer';
              break;
            case 5:
              paymentTypeStr = 'Cash (other amount)';
              break;
            case 6:
              paymentTypeStr = 'Hash credit';
              break;
            case 7:
              paymentTypeStr = 'Transfer (other amt)';
              break;
            default:
              paymentTypeStr = 'Other';
          }

          const int flexLeft = 37;
          const int flexRight = 63;
          const double spacer = 6.0;

          final String amountStr = IveCoreUtilities.getFormattedMoney(
            item.payment!.debitAmount,
            widget.eventAggregate.extensions.digAfterDec,
            widget.eventAggregate.extensions.curSym,
          );
          String? topUpStr;

          final double topUpAmount =
              (item.payment!.creditAmount) - (item.payment!.debitAmount);
          if (topUpAmount != 0) {
            topUpStr = IveCoreUtilities.getFormattedMoney(
              topUpAmount.abs(),
              widget.eventAggregate.extensions.digAfterDec,
              widget.eventAggregate.extensions.curSym,
            );
          }
          final String extrasPriceStr = IveCoreUtilities.getFormattedMoney(
            item.extensions.extrasPrice,
            widget.eventAggregate.extensions.digAfterDec,
            widget.eventAggregate.extensions.curSym,
          );
          final String discountAmountStr = IveCoreUtilities.getFormattedMoney(
            item.payment!.discountAmount,
            widget.eventAggregate.extensions.digAfterDec,
            widget.eventAggregate.extensions.curSym,
          );
          final String discountPercentStr =
              '${(item.payment!.discountPercent).toStringAsFixed(0)}%';

          return AlertDialog(
            title: Text('Payment Detail', style: ts_alertDialogTitle),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: flexLeft,
                        child: Text(
                          'Pay Ref:',
                          style: ts_alertDialogBody,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: spacer, height: 10.0),
                      Expanded(
                        flex: flexRight,
                        child: Text(
                          item.payment!.paymentReference ?? '',
                          style: ts_titleMediumBlack,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: flexLeft,
                        child: Text(
                          'Paid by:',
                          style: ts_regularMediumBlack,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: spacer, height: 10.0),
                      Expanded(
                        flex: flexRight,
                        child: Text(
                          item.extensions.paidByName,
                          style: ts_titleMediumBlack,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: flexLeft,
                        child: Text(
                          'Paid to:',
                          style: ts_regularMediumBlack,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: spacer, height: 10.0),
                      Expanded(
                        flex: flexRight,
                        child: Text(
                          item.extensions.paidToName,
                          style: ts_titleMediumBlack,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: flexLeft,
                        child: Text(
                          'Amount:',
                          style: ts_regularMediumBlack,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: spacer, height: 10.0),
                      Expanded(
                        flex: flexRight,
                        child: Text(amountStr, style: ts_titleMediumBlack),
                      ),
                    ],
                  ),
                  if (item
                      .payment!
                      .specialRunPriceReason
                      .isNotEmpty) ...<Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: flexLeft,
                          child: Text(
                            'Reason:',
                            style: ts_regularMediumBlack,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: spacer, height: 10.0),
                        Expanded(
                          flex: flexRight,
                          child: Text(
                            item.payment!.specialRunPriceReason,
                            style: ts_titleMediumBlack,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (topUpStr != null) ...<Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: flexLeft,
                          child: Text(
                            (topUpAmount < 0) ? 'From credit:' : 'Top up:',
                            style: ts_regularMediumBlack,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: spacer, height: 10.0),
                        Expanded(
                          flex: flexRight,
                          child: Text(topUpStr, style: ts_titleMediumBlack),
                        ),
                      ],
                    ),
                  ],
                  if (item.payment!.discountAmount != 0) ...<Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: flexLeft,
                          child: Text(
                            'Discount:',
                            style: ts_regularMediumBlack,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: spacer, height: 10.0),
                        Expanded(
                          flex: flexRight,
                          child: Text(
                            discountAmountStr,
                            style: ts_titleMediumBlack,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (item.payment!.discountAmount != 0) ...<Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: flexLeft,
                          child: Text(
                            'Discount:',
                            style: ts_regularMediumBlack,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: spacer, height: 10.0),
                        Expanded(
                          flex: flexRight,
                          child: Text(
                            discountPercentStr,
                            style: ts_titleMediumBlack,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (item.payment!.discountDescription.isNotEmpty &&
                      ((item.payment!.discountAmount != 0) ||
                          (item.payment!.discountPercent != 0))) ...<Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: flexLeft,
                          child: Text(
                            'Description:',
                            style: ts_regularMediumBlack,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: spacer, height: 10.0),
                        Expanded(
                          flex: flexRight,
                          child: Text(
                            item.payment!.discountDescription,
                            style: ts_titleMediumBlack,
                          ),
                        ),
                      ],
                    ),
                  ],
                  item.extensions.extrasPrice == 0
                      ? Container()
                      : Row(
                          children: <Widget>[
                            Expanded(
                              flex: flexLeft,
                              child: Text(
                                'Extras:',
                                style: ts_regularMediumBlack,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: spacer, height: 10.0),
                            Expanded(
                              flex: flexRight,
                              child: Text(
                                item.extensions.extrasDescription ?? '',
                                style: ts_titleMediumBlack,
                              ),
                            ),
                          ],
                        ),
                  item.extensions.extrasPrice == 0
                      ? Container()
                      : Row(
                          children: <Widget>[
                            Expanded(
                              flex: flexLeft,
                              child: Text(
                                'Ex. Paid:',
                                style: ts_regularMediumBlack,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: spacer, height: 10.0),
                            Expanded(
                              flex: flexRight,
                              child: Text(
                                item.payment!.doPayForExtras == 0
                                    ? 'No'
                                    : extrasPriceStr,
                                style: ts_titleMediumBlack,
                              ),
                            ),
                          ],
                        ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: flexLeft,
                        child: Text(
                          'Date:',
                          style: ts_regularMediumBlack,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: spacer, height: 10.0),
                      Expanded(
                        flex: flexRight,
                        child: Text(
                          DateFormat(
                            'MMM dd, yyyy',
                          ).format(item.payment!.paidDate),
                          style: ts_titleMediumBlack,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: flexLeft,
                        child: Text(
                          'Time:',
                          style: ts_regularMediumBlack,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: spacer, height: 10.0),
                      Expanded(
                        flex: flexRight,
                        child: Text(
                          DateFormat('kk:mm').format(item.payment!.paidDate),
                          style: ts_titleMediumBlack,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: flexLeft,
                        child: Text(
                          'Type:',
                          style: ts_regularMediumBlack,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: spacer, height: 10.0),
                      Expanded(
                        flex: flexRight,
                        child: Text(paymentTypeStr, style: ts_titleMediumBlack),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: flexLeft,
                        child: Text(
                          'Product:',
                          style: ts_regularMediumBlack,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: spacer, height: 10.0),
                      Expanded(
                        flex: flexRight,
                        child: Text(
                          _productLabel(item.payment!.productType),
                          style: ts_titleMediumBlack,
                        ),
                      ),
                    ],
                  ),
                  // Haberdashery item description (Payment.Notes).
                  if (item.payment!.productType ==
                          productTypeHaberdashery.value &&
                      (item.payment!.notes ?? '').trim().isNotEmpty)
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: flexLeft,
                          child: Text(
                            'Item:',
                            style: ts_regularMediumBlack,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: spacer, height: 10.0),
                        Expanded(
                          flex: flexRight,
                          child: Text(
                            item.payment!.notes!.trim(),
                            style: ts_titleMediumBlack,
                          ),
                        ),
                      ],
                    ),
                  item.payment!.surcharge == 0
                      ? Container()
                      : Row(
                          children: <Widget>[
                            Expanded(
                              flex: flexLeft,
                              child: Text(
                                'Surcharge:',
                                style: ts_regularMediumBlack,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: spacer, height: 10.0),
                            Expanded(
                              flex: flexRight,
                              child: Text(
                                IveCoreUtilities.getFormattedMoney(
                                  item.payment!.surcharge,
                                  widget.eventAggregate.extensions.digAfterDec,
                                  widget.eventAggregate.extensions.curSym,
                                ),
                                style: ts_titleMediumBlack,
                              ),
                            ),
                          ],
                        ),
                  (item.payment!.paymentProvider ?? '') == ''
                      ? Container()
                      : Row(
                          children: <Widget>[
                            Expanded(
                              flex: flexLeft,
                              child: Text(
                                'Provider:',
                                style: ts_regularMediumBlack,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: spacer, height: 10.0),
                            Expanded(
                              flex: flexRight,
                              child: Text(
                                item.payment!.paymentProvider!,
                                style: ts_titleMediumBlack,
                              ),
                            ),
                          ],
                        ),
                  ((item.payment!.paymentType != paymentBankTransfer.value) &&
                          (item.payment!.paymentType !=
                              paymentBankTransferOtherAmount.value))
                      ? Container()
                      : Row(
                          children: <Widget>[
                            Expanded(
                              flex: flexLeft,
                              child: Text(
                                'Confirmed:',
                                style: ts_regularMediumBlack,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: spacer, height: 10.0),
                            Expanded(
                              flex: flexRight,
                              child: Text(
                                item.payment!.confirmedDate == null
                                    ? '<not confirmed>'
                                    : item.extensions.confByName ?? '',
                                style: (item.payment!.confirmedDate == null)
                                    ? bodyStyleRed
                                    : ts_titleMediumBlack,
                              ),
                            ),
                          ],
                        ),
                  ((item.payment!.paymentType != paymentBankTransfer.value) &&
                          (item.payment!.paymentType !=
                              paymentBankTransferOtherAmount.value))
                      ? Container()
                      : Row(
                          children: <Widget>[
                            Expanded(
                              flex: flexLeft,
                              child: Text(
                                'Conf on:',
                                style: ts_regularMediumBlack,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: spacer, height: 10.0),
                            Expanded(
                              flex: flexRight,
                              child: Text(
                                (item.payment!.confirmedDate == null)
                                    ? '<not confirmed>'
                                    : DateFormat(
                                        'MMM dd, yyyy kk:mm',
                                      ).format(item.payment!.paidDate),
                                style: (item.payment!.confirmedDate == null)
                                    ? bodyStyleRed
                                    : ts_titleMediumBlack,
                              ),
                            ),
                          ],
                        ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Center(
                      child:
                          (((item.payment!.paymentType !=
                                      paymentBankTransfer.value) &&
                                  (item.payment!.paymentType !=
                                      paymentBankTransferOtherAmount.value)) ||
                              (item.payment!.confirmedBy != null) ||
                              (widget.eventAggregate.kennel.bankBic == null))
                          ? Container()
                          : ElevatedButton(
                              onPressed: () async {
                                final String remittanceInfo =
                                    '${item.payment!.paymentReference}-${item.extensions.paidByName}';
                                await BankTransferQr.showBankTransferQrCode(
                                  context,
                                  widget.eventAggregate,
                                  item.extensions.isMember != 0,
                                  packMemberNameForDisplay:
                                      item.extensions.paidByName,
                                  remitString: remittanceInfo,
                                  remitAmount: item.payment!.creditAmount,
                                );
                              },
                              child: Text('Show Payment QR', style: ts_button),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Center(
                      child:
                          (((item.payment!.paymentType !=
                                      paymentBankTransfer.value) &&
                                  (item.payment!.paymentType !=
                                      paymentBankTransferOtherAmount.value)) ||
                              (item.payment!.confirmedBy != null))
                          ? Container()
                          : ElevatedButton(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop('confirm');
                              },
                              child: Text(
                                'Confirm Bank Transfer',
                                style: ts_button,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            //           ),
            //         ],
            //       ),
            //     ],
            //   ),
            // ),
            actions: <Widget>[
              // Cancel is only wired for run payments — cancelling a
              // membership/haberdashery sale is not yet supported, so hide it
              // on those rows rather than mis-cancel a run payment.
              if (item.payment!.productType == productTypeEvent.value)
                TextButton(
                  style: text_button_style,
                  child: Text('Cancel transaction', style: ts_button),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop('cancel');
                  },
                ),
              TextButton(
                style: text_button_style,
                child: Text('Close', style: ts_button),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop('close');
                },
              ),
            ],
          );
        }
      },
    );
  }
}
