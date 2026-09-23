// ignore_for_file: constant_identifier_names

import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

/// The run's payment report. Stateless over [PaymentReportController]; the
/// dialogs and swipe panes live here, the queries, filter and totals there.
class PaymentReportPage extends StatelessWidget {
  const PaymentReportPage({super.key, required this.eventAggregate});

  final RunAdminAggregate eventAggregate;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PaymentReportController>(
      init: PaymentReportController(eventAggregate: eventAggregate),
      tag: PaymentReportController.tagFor(eventAggregate.event.eventId),
      builder: (PaymentReportController c) => AppScaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
          title: Text(eventAggregate.event.eventName, style: ts_appBarTitle),
        ),
        floatingActionButton: Container(
          margin: const EdgeInsets.only(bottom: 25.0),
          child: SpeedDial(
            // both default to 16
            // marginEnd: 18,
            // marginBottom: 20,
            animatedIcon: AnimatedIcons.menu_close,
            animatedIconTheme: const IconThemeData(size: 22.0),
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
                        eventId: eventAggregate.event.eventId,
                        eventName: eventAggregate.event.eventName,
                      );

                  if (!context.mounted) return;
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
        body: Obx(() => _body(context, c)),
      ),
    );
  }

  Widget _body(BuildContext context, PaymentReportController c) {
    // Snapshots inside the Obx so the chips, list and footer agree.
    final List<Map<String, dynamic>> totals = c.paymentTotals;
    final List<PaymentAggregate> filtered = c.filteredList;
    final int filterValue = c.filterValue.value;
    return (c.isLoading.value || totals.isEmpty)
        ? const HcAppCircularProgressIndicator(key: Key('112209596'))
        : Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              // Queued charges are NOT in the totals below — the banner
              // says so and opens the outbox viewer.
              const PaymentOutboxBanner(),
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
                              totals[0]['count'] +
                              totals[paymentNotPaid.value]['count'],
                          color: (filterValue & 1) != 0
                              ? hc_red
                              : Colors.black26,
                          paymentRecordType: paymentNotPaid,
                          currencySymbol: eventAggregate.extensions.curSym,
                          digitsAfterDecimal:
                              eventAggregate.extensions.digAfterDec,
                          onTap: () {
                            c.filterTapped(1);
                          },
                        ),
                        PaymentTotalsCell(
                          creditAmount:
                              totals[paymentCash.value]['totalCollected']
                                  ?.toDouble() ??
                              0.0,
                          counter: totals[paymentCash.value]['count'],
                          color: (filterValue & 2) != 0
                              ? Colors.green
                              : Colors.black26,
                          paymentRecordType: paymentCash,
                          currencySymbol: eventAggregate.extensions.curSym,
                          digitsAfterDecimal:
                              eventAggregate.extensions.digAfterDec,
                          onTap: () {
                            c.filterTapped(2);
                          },
                        ),
                        PaymentTotalsCell(
                          creditAmount:
                              totals[paymentBankTransfer
                                      .value]['totalCollected']
                                  ?.toDouble() ??
                              0.0,
                          counter: totals[paymentBankTransfer.value]['count'],
                          color: (filterValue & 16) != 0
                              ? Colors.green
                              : Colors.black26,
                          paymentRecordType: paymentBankTransfer,
                          currencySymbol: eventAggregate.extensions.curSym,
                          digitsAfterDecimal:
                              eventAggregate.extensions.digAfterDec,
                          onTap: () {
                            c.filterTapped(16);
                          },
                        ),
                        PaymentTotalsCell(
                          creditAmount:
                              totals[paymentFreeRun.value]['totalCollected']
                                  ?.toDouble() ??
                              0.0,
                          counter: totals[paymentFreeRun.value]['count'],
                          color: (filterValue & 8) != 0
                              ? Colors.green
                              : Colors.black26,
                          paymentRecordType: paymentFreeRun,
                          currencySymbol: eventAggregate.extensions.curSym,
                          digitsAfterDecimal:
                              eventAggregate.extensions.digAfterDec,
                          onTap: () {
                            c.filterTapped(8);
                          },
                        ),
                        PaymentTotalsCell(
                          creditAmount:
                              -((totals[paymentHashCredit.value]['totalDebited']
                                      ?.toDouble()) ??
                                  0.0),
                          counter: totals[paymentHashCredit.value]['count'],
                          color: (filterValue & 64) != 0
                              ? Colors.green
                              : Colors.black26,
                          paymentRecordType: paymentHashCredit,
                          currencySymbol: eventAggregate.extensions.curSym,
                          digitsAfterDecimal:
                              eventAggregate.extensions.digAfterDec,
                          onTap: () {
                            c.filterTapped(64);
                          },
                        ),
                        PaymentTotalsCell(
                          creditAmount:
                              totals[paymentCashOtherAmount
                                      .value]['totalCollected']
                                  ?.toDouble() ??
                              0.0,
                          counter:
                              totals[paymentCashOtherAmount.value]['count'],
                          color: (filterValue & 4) != 0
                              ? Colors.green
                              : Colors.black26,
                          paymentRecordType: paymentCashOtherAmount,
                          currencySymbol: eventAggregate.extensions.curSym,
                          digitsAfterDecimal:
                              eventAggregate.extensions.digAfterDec,
                          onTap: () {
                            c.filterTapped(4);
                          },
                        ),
                        PaymentTotalsCell(
                          creditAmount:
                              totals[paymentBankTransferOtherAmount
                                      .value]['totalCollected']
                                  ?.toDouble() ??
                              0.0,
                          counter:
                              totals[paymentBankTransferOtherAmount
                                  .value]['count'],
                          color: (filterValue & 32) != 0
                              ? Colors.green
                              : Colors.black26,
                          paymentRecordType: paymentBankTransferOtherAmount,
                          currencySymbol: eventAggregate.extensions.curSym,
                          digitsAfterDecimal:
                              eventAggregate.extensions.digAfterDec,
                          onTap: () {
                            c.filterTapped(32);
                          },
                        ),
                        PaymentTotalsCell(
                          creditAmount:
                              -((totals[paymentHashCreditOtherAmount
                                          .value]['totalDebited']
                                      ?.toDouble()) ??
                                  0.0),
                          counter:
                              totals[paymentHashCreditOtherAmount
                                  .value]['count'],
                          color: (filterValue & 128) != 0
                              ? Colors.green
                              : Colors.black26,
                          paymentRecordType: paymentHashCreditOtherAmount,
                          currencySymbol: eventAggregate.extensions.curSym,
                          digitsAfterDecimal:
                              eventAggregate.extensions.digAfterDec,
                          onTap: () {
                            c.filterTapped(128);
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
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No transactions available.',
                            style: ts_titleBlack,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: c.pullToRefresh,
                          displacement: 40.0,
                          child: ListView.separated(
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const Divider(
                                      height: 1.0,
                                      color: Colors.black45,
                                    ),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: filtered.length + 1,
                            itemBuilder: (BuildContext context, int index) {
                              if (index == filtered.length) {
                                return Container(height: 100);
                              }
                              final bool needsConfirm =
                                  (((filtered[index].payment?.paymentType ??
                                              paymentTypeUnknown) ==
                                          paymentBankTransfer.value) ||
                                      ((filtered[index].payment?.paymentType ??
                                              paymentTypeUnknown) ==
                                          paymentBankTransferOtherAmount
                                              .value)) &&
                                  (filtered[index].payment?.confirmedBy ==
                                      null);
                              return (((filtered[index].payment?.paymentType ??
                                              paymentTypeUnknown.value) !=
                                          paymentTypeUnknown.value) &&
                                      (filtered[index].payment?.paymentType !=
                                          paymentNotPaid.value) &&
                                      !needsConfirm)
                                  ? _listItem(filtered[index], context, c)
                                  : Dismissible(
                                      key: Key(index.toString()),
                                      confirmDismiss:
                                          (DismissDirection direction) async {
                                            //print(direction.toString() + ' ' + index.toString() + ' ' + eventAggregate.extensions.nonMemberPrice.toString());
                                            c.markRowLoading(filtered[index]);
                                            if (needsConfirm) {
                                              await c.payForEvent(
                                                filtered[index],
                                                paymentConfirmBankTransfer
                                                    .value,
                                                -1,
                                              );
                                              await c.reload();
                                            } else {
                                              final double paymentAmount =
                                                  (filtered[index]
                                                          .extensions
                                                          .isMember !=
                                                      0)
                                                  ? filtered[index]
                                                        .extensions
                                                        .eventPriceForMembers
                                                  : filtered[index]
                                                        .extensions
                                                        .eventPriceForNonMembers;
                                              await _showExtrasDialog(
                                                context,
                                                c,
                                                direction ==
                                                        DismissDirection
                                                            .endToStart
                                                    ? paymentCash.value
                                                    : paymentBankTransfer.value,
                                                filtered[index],
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
                                                      '${(eventAggregate.event.eventPriceForExtras ?? 0) != 0 ? '' : '${IveCoreUtilities.getFormattedMoney((filtered[index].extensions.isMember != 0) ? filtered[index].extensions.eventPriceForMembers : filtered[index].extensions.eventPriceForNonMembers, eventAggregate.extensions.digAfterDec, eventAggregate.extensions.curSym)} '}Bank Transfer',
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
                                                      '${(eventAggregate.event.eventPriceForExtras ?? 0) != 0 ? '' : '${IveCoreUtilities.getFormattedMoney((filtered[index].extensions.isMember != 0) ? filtered[index].extensions.eventPriceForMembers : filtered[index].extensions.eventPriceForNonMembers, eventAggregate.extensions.digAfterDec, eventAggregate.extensions.curSym)} '}Cash',
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
                                        filtered[index],
                                        context,
                                        c,
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
                child: _buildTotalsFooter(c),
              ),
            ],
          );
  }

  Future<void> _showExtrasDialog(
    BuildContext context,
    PaymentReportController c,
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
        ((eventAggregate.event.eventPriceForExtras ?? 0) != 0)) {
      final double runOnlyPrice = packMember.extensions.isMember != 0
          ? eventAggregate.extensions.memberPrice
          : eventAggregate.extensions.nonMemberPrice;
      final double runPlusExtrasPrice =
          runOnlyPrice + (eventAggregate.event.eventPriceForExtras ?? 0.0);

      final String runOnlyPriceStr = IveCoreUtilities.getFormattedMoney(
        runOnlyPrice,
        eventAggregate.extensions.digAfterDec,
        eventAggregate.extensions.curSym,
      );
      final String runPlusExtrasPriceStr = IveCoreUtilities.getFormattedMoney(
        runPlusExtrasPrice,
        eventAggregate.extensions.digAfterDec,
        eventAggregate.extensions.curSym,
      );

      final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
        <String, dynamic>{
          'title': 'Run only ($runOnlyPriceStr)',
          'icon': <Widget>[Container()],
          'returnValue': payForRunOnly,
        },
        <String, dynamic>{
          'title':
              'Run + ${eventAggregate.event.extrasDescription} ($runPlusExtrasPriceStr)',
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
      final List<dynamic> results = await c.payForEvent(
        packMember,
        paymentType,
        paymentAmount,
        doPayForExtras: payForExtras,
        otherPaymentPopupResult: otherPaymentPopupResult,
      );
      await c.reload();
      if (!context.mounted) return;
      BankTransferQr.showBankTransferSnackbar(
        eventAggregate,
        results,
        paymentType,
        context,
        packMember.extensions.paidByName,
        packMember.extensions.isMember,
        paymentAmount,
      );
    } else {
      // there are no extras so just pay for the run without any extras dialog
      final List<dynamic> results = await c.payForEvent(
        packMember,
        paymentType,
        paymentAmount,
        doPayForExtras: payForRunOnly,
        otherPaymentPopupResult: otherPaymentPopupResult,
      );
      await c.reload();
      if (!context.mounted) return;
      BankTransferQr.showBankTransferSnackbar(
        eventAggregate,
        results,
        paymentType,
        context,
        packMember.extensions.paidByName,
        packMember.extensions.isMember,
        paymentAmount,
      );
    }
  }

  /// Human label for a payment's product type, shown in the detail popup.
  String _productLabel(int productType) {
    if (productType == productTypeMembership.value) {
      return 'Annual subscription';
    }
    if (productType == productTypeHaberdashery.value) return 'Haberdashery';
    return 'Run fee';
  }

  /// Footer totals: one line per product category with activity (confirmed
  /// money only), extras when the event has them configured, and an explicit
  /// "Card pending" line for unconfirmed bank transfers — the category lines
  /// plus pending always sum to the recorded gross, and "Total collected"
  /// means verified money (2026-08-16, per James's treasurer-reconciliation
  /// reading).
  Widget _buildTotalsFooter(PaymentReportController c) {
    final PaymentFooterTotals f = c.footer.value;
    String money(double amount) => IveCoreUtilities.getFormattedMoney(
      amount,
      eventAggregate.extensions.digAfterDec,
      eventAggregate.extensions.curSym,
    );

    final double extrasPrice = eventAggregate.event.eventPriceForExtras ?? 0;
    final String? extrasDescription = eventAggregate.event.extrasDescription;
    // '<null>' is a legacy sentinel that used to print literally in this
    // footer ("<null> paid: 0 for £0.00" on events with no extras).
    final bool extrasConfigured =
        extrasPrice != 0 &&
        extrasDescription != null &&
        extrasDescription.trim().isNotEmpty &&
        extrasDescription != '<null>';
    final double extrasAmount = extrasConfigured
        ? extrasPrice * f.extrasPaid
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Total transactions: $f.transactionCount', style: ts_titleBlack),
        Text(
          'Run fees: ${money(f.runGross - f.runPending - extrasAmount)}',
          style: ts_titleBlack,
        ),
        if (extrasConfigured)
          Text(
            '$extrasDescription paid: ${f.extrasPaid.toInt()} for ${money(extrasAmount)}',
            style: ts_titleBlack,
          ),
        if (f.memberGross > 0 || f.memberPending > 0)
          Text(
            'Memberships: ${money(f.memberGross - f.memberPending)}',
            style: ts_titleBlack,
          ),
        if (f.habGross > 0 || f.habPending > 0)
          Text(
            'Haberdashery: ${money(f.habGross - f.habPending)}',
            style: ts_titleBlack,
          ),
        if (f.pendingCount > 0)
          Text(
            'Card pending: ${money(f.pendingTotal)} ($f.pendingCount to confirm)',
            style: ts_titleBlack.copyWith(color: Colors.amber.shade900),
          ),
        Text(
          'Total collected: ${money(f.totalCollected)}',
          style: ts_titleBlack,
        ),
      ],
    );
  }

  Container _listItem(
    PaymentAggregate item,
    BuildContext context,
    PaymentReportController c,
  ) {
    return Container(
      height: 60.0,
      padding: const EdgeInsets.only(top: 10),
      child: PaymentReportListItem(
        currencySymbol: eventAggregate.extensions.curSym,
        digitsAfterDecimal: eventAggregate.extensions.digAfterDec,
        paymentReportItem: item,
        onTap: () async {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          if ((item.payment == null) ||
              (item.payment!.paymentType == paymentTypeUnknown.value) ||
              (item.payment!.paymentType == paymentNotPaid.value)) {
            double amountOwed = item.extensions.isMember != 1
                ? eventAggregate.extensions.nonMemberPrice
                : eventAggregate.extensions.memberPrice;
            amountOwed -= item.extensions.discountAmountAvailable;
            amountOwed -=
                amountOwed * (item.extensions.discountPercentAvailable / 100.0);

            final PaymentPopup pp = PaymentPopup(
              amount: amountOwed,
              creditAllowed: eventAggregate.kennel.allowCredit,
              creditRemaining: item.extensions.creditAvailable,
              currencySymbol: eventAggregate.extensions.curSym,
              hemId: item.extensions.pkHemId,
              decimalDigits: eventAggregate.extensions.digAfterDec,
              allowDefaultPricing:
                  (item.extensions.isMember != 0) ||
                  (item.extensions.isFollowing != 0),
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
                c.markRowLoading(item);

                //final num paymentAmount = (item.extensions.isMember != 0) ? item.extensions.eventPriceForMembers : item.extensions.eventPriceForNonMembers;
                if (!context.mounted) return;
                await _showExtrasDialog(
                  context,
                  c,
                  ppResult.transactionType,
                  item,
                  ppResult.transactionValue,
                  otherPaymentPopupResult: ppResult.otherPayment,
                );
              }
            }
          } else {
            final String action =
                await _displayPaymentDetails(item, context) ?? 'close';

            if (action == 'cancel') {
              c.markRowLoading(item);
              await c.payForEvent(item, paymentNotPaid.value, 0);
              await c.reload();
            } else if (action == 'confirm') {
              c.markRowLoading(item);
              await c.payForEvent(item, paymentConfirmBankTransfer.value, -1);
              await c.reload();
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
            eventAggregate.extensions.digAfterDec,
            eventAggregate.extensions.curSym,
          );
          String? topUpStr;

          final double topUpAmount =
              (item.payment!.creditAmount) - (item.payment!.debitAmount);
          if (topUpAmount != 0) {
            topUpStr = IveCoreUtilities.getFormattedMoney(
              topUpAmount.abs(),
              eventAggregate.extensions.digAfterDec,
              eventAggregate.extensions.curSym,
            );
          }
          final String extrasPriceStr = IveCoreUtilities.getFormattedMoney(
            item.extensions.extrasPrice,
            eventAggregate.extensions.digAfterDec,
            eventAggregate.extensions.curSym,
          );
          final String discountAmountStr = IveCoreUtilities.getFormattedMoney(
            item.payment!.discountAmount,
            eventAggregate.extensions.digAfterDec,
            eventAggregate.extensions.curSym,
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
                                  eventAggregate.extensions.digAfterDec,
                                  eventAggregate.extensions.curSym,
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
                              (eventAggregate.kennel.bankBic == null))
                          ? Container()
                          : ElevatedButton(
                              onPressed: () async {
                                final String remittanceInfo =
                                    '${item.payment!.paymentReference}-${item.extensions.paidByName}';
                                await BankTransferQr.showBankTransferQrCode(
                                  context,
                                  eventAggregate,
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
