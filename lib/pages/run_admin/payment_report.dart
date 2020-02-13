import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:harrier_central/pages/run_admin/run_admin_main.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

import 'package:harrier_central/pages/run_admin/payment_popup.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/widgets/payment_report_list_item.dart';
import 'package:harrier_central/widgets/circular_progress_indicator.dart';
import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/data/hc3_services/payments_service.dart';
import 'package:harrier_central/data/hc3_services/hashers_service.dart';
import 'package:harrier_central/data/hc3_services/narrow_event_service.dart';
import 'package:harrier_central/data/hc3_services/kennels_service.dart';
import 'package:harrier_central/data/hc3_services/sync_event_admin_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_event_map_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';
import 'package:harrier_central/data/hc3_services/kennel_credits_service.dart';
import 'package:harrier_central/util/bank_transfer_qr.dart';
import 'package:harrier_central/widgets/multiple_choice_popup.dart';

class PaymentAggregate {
  PaymentAggregate({
    this.payment,
    this.extensions,
  });

  final PaymentQueryExtensions extensions;
  final PaymentsModel payment;
}

class PaymentQueryExtensions {
  PaymentQueryExtensions({
    this.pkHemId,
    this.paidByName,
    this.paidToName,
    this.isMember,
    this.creditAvailable,
    this.eventPriceForMembers,
    this.eventPriceForNonMembers,
    this.confByName,
    this.extrasPrice,
    this.extrasDescription,
  });

  final String pkHemId;
  final String paidByName;
  final String paidToName;
  final int isMember;
  final num creditAvailable;
  final num eventPriceForMembers;
  final num eventPriceForNonMembers;
  final String confByName;
  final num extrasPrice;
  final String extrasDescription;

  bool isLoading = false;

  static PaymentQueryExtensions fromMap(Map<String, dynamic> map) {
    final PaymentQueryExtensions item = PaymentQueryExtensions(
        pkHemId: map['pkHemId'],
        paidByName: map['paidByName'],
        paidToName: map['paidToName'],
        isMember: map['isMember'],
        creditAvailable: map['creditAvailable'],
        eventPriceForMembers: map['eventPriceForMembers'],
        eventPriceForNonMembers: map['eventPriceForNonMembers'],
        confByName: map['confByName'],
        extrasDescription: map['extrasDescription'],
        extrasPrice: map['extrasPrice']);
    return item;
  }
}

class PaymentReportPage extends StatefulWidget {
  const PaymentReportPage({Key key, @required this.eventAggregate}) : super(key: key);

  final RunDetailAggregate eventAggregate;

  @override
  PaymentReportState createState() => PaymentReportState();
}

class PaymentReportState extends State<PaymentReportPage> {
  PaymentReportState();

  List<PaymentAggregate> paymentsList = <PaymentAggregate>[];
  List<PaymentAggregate> filteredList = <PaymentAggregate>[];

  bool _isLoading = true;

  int filterValue = 127;

  @override
  void initState() {
    _refreshSqlTablesFromBackend();

    super.initState();
  }

  Future<void> _refreshSqlTablesFromBackend() async {
    setState(() {
      _isLoading = true;
    });

    DBProvider.db.database.then((Database db) async {
      final SyncEventAdminService cSrv = SyncEventAdminService();
      final bool result = await cSrv.updateFromBackend(db, SyncEventAdminService.flagPaymentsTable | SyncEventAdminService.flagHasherEventMapTable | SyncEventAdminService.flagHasherKennelMapTable, true, widget.eventAggregate.event.eventId);
      final String resultStr = result ? 'successfully' : 'unsuccessfully';
      print('Payments data synchronized $resultStr');

      _refreshListsFromTable().then((void dummy) {
        setState(() {
          _isLoading = false;
          refreshTotals();
        });
      });
    });
  }

  Future<void> _refreshListsFromTable() async {
    final Database db = await DBProvider.db.database;

    final String sql = '''

          SELECT
          -- Payment table
          pay.*,
          -- Extensions
          hem.hemId as pkHemId,
          COALESCE(CASE WHEN hem.displayName IS NULL THEN NULL ELSE hem.displayName || CASE WHEN hem.virginVisitorType = 1 THEN " (Virgin)" ELSE " (Visitor)" END END, h.dispName,'<hasher not found>') as paidByName,
          COALESCE(paidTo.dispName,'<hasher not found>') as paidToName,
          COALESCE(hkm.isMember,0) as isMember,
          COALESCE(credits.currentBalance,0) as creditAvailable,
          coalesce(e.eventPriceForMembers,k.defaultPriceForMembers,0) as eventPriceForMembers,
          coalesce(e.eventPriceForNonMembers,k.defaultPriceForNonMembers,0) as eventPriceForNonMembers,
          COALESCE(confBy.dispName,'') as confByName,
          COALESCE(e.${EventTableHelper.colExtrasDescription},'<unknown>') as extrasDescription,
          COALESCE(e.${EventTableHelper.colEventPriceForExtras},0) as extrasPrice
          FROM ${HasherEventMapTableHelper.getTableName(HasherEventMapTableType.eventAdmin)} hem
          INNER JOIN ${EventTableHelper.tableName} e on e.eventId = hem.eventId
          INNER JOIN ${kennelsTableHelper.tableName} k on k.kennelId = e.kennelId
          LEFT OUTER JOIN ${HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.eventAdmin)} hkm on hkm.userId = hem.userId and hkm.kennelId = "${widget.eventAggregate.event.kennelId}"
          LEFT OUTER JOIN ${hashersTableHelper.tableName} h on h.hasherId = hem.userId
          LEFT OUTER JOIN ${paymentsTableHelper.tableName} pay on pay.hemId = hem.hemId and pay.CancelledBy IS NULL
          LEFT OUTER JOIN ${hashersTableHelper.tableName} paidTo on paidTo.hasherId = pay.paidTo
          LEFT OUTER JOIN ${kennelCreditsTableHelper.tableName} credits on credits.userId = hkm.userId and credits.kennelId = hkm.kennelId
          LEFT OUTER JOIN ${hashersTableHelper.tableName} confBy on confBy.hasherId = pay.confirmedBy
          WHERE hem.attendenceState >= 20
          ''';

    final List<Map<String, dynamic>> results = await db.rawQuery(sql);

    paymentsList.clear();

    for (int i = 0; i < results.length; i++) {
      final PaymentsModel paymentItem = paymentsTableHelper.fromMap(results[i]);
      final PaymentQueryExtensions extensions = PaymentQueryExtensions.fromMap(results[i]);
      final PaymentAggregate item = PaymentAggregate(payment: paymentItem, extensions: extensions);

      paymentsList.add(item);
      if (i == results.length - 1) {
        paymentsList.sort((PaymentAggregate a, PaymentAggregate b) => a.extensions.paidByName.compareTo(b.extensions.paidByName));
        applyFilter();
        setState(() {});
      }
    }
  }

  List<Map<String, dynamic>> paymentTotals;

  void refreshTotals() {
    paymentTotals = <Map<String, dynamic>>[];
    DBProvider.db.database.then((Database db) {
      try {
        final String sql = '''

          select 0 as paymentType, (SELECT COUNT(*) from ${HasherEventMapTableHelper.getTableName(HasherEventMapTableType.eventAdmin)} hem 
          WHERE  hem.attendenceState >= 20
          AND hem.hemId not in (SELECT hemId from ${paymentsTableHelper.tableName} pay3 where pay3.cancelledBy IS NULL) ) as count, 5.55 as totalCollected
            
          UNION
          select paymentType, 
            (
                SELECT COUNT(*) 
                FROM ${paymentsTableHelper.tableName} pay 
                INNER JOIN ${HasherEventMapTableHelper.getTableName(HasherEventMapTableType.eventAdmin)} hem on hem.hemId = pay.hemId AND hem.attendenceState >= 20
                WHERE pay.paymentType = x.paymentType AND pay.cancelledBy IS NULL

            ) as count,
            (
                SELECT SUM(pay2.creditAmount) 
                FROM ${paymentsTableHelper.tableName} pay2 
                INNER JOIN ${HasherEventMapTableHelper.getTableName(HasherEventMapTableType.eventAdmin)} hem2 on hem2.hemId = pay2.hemId AND hem2.attendenceState >= 20
                WHERE pay2.paymentType = x.paymentType AND pay2.cancelledBy IS NULL
            ) as totalCollected
          FROM (select 1 as paymentType union values (2), (3), (4), (5), (6), (7) ) x


          ''';

        db.rawQuery(sql).then((List<Map<String, dynamic>> results) {
          setState(() {
            paymentTotals = results;
          });
        });
      } catch (e) {
        print(e);
      }
    });
    print('Payment totals refreshed at ' + DateTime.now().millisecondsSinceEpoch.toString());
  }

  Future<List<dynamic>> payForEvent(PaymentAggregate item, int paymentType, num amount, {EnumPayForExtras<int> doPayForExtras = payForRunOnly}) {
    final PaymentsService paySrv = PaymentsService();
    return paySrv.payForEvent(widget.eventAggregate.event.eventId, GUID_EMPTY, item.extensions.pkHemId, paymentType, amount, attendenceAtHash.value, doPayForExtras);
  }

  void applyFilter() {
    filteredList = paymentsList
        .where((PaymentAggregate evt) =>
            ((filterValue & 1) != 0 && ((evt.payment.paymentType ?? paymentNotPaid.value) == paymentNotPaid.value)) ||
            ((filterValue & 2) != 0 && (evt.payment.paymentType == paymentCash.value)) ||
            ((filterValue & 4) != 0 && (evt.payment.paymentType == paymentCashOtherAmount.value)) ||
            ((filterValue & 8) != 0 && (evt.payment.paymentType == paymentFreeRun.value)) ||
            ((filterValue & 16) != 0 && (evt.payment.paymentType == paymentBankTransfer.value)) ||
            ((filterValue & 32) != 0 && (evt.payment.paymentType == paymentBankTransferOtherAmount.value)) ||
            ((filterValue & 64) != 0 && (evt.payment.paymentType == paymentHashCredit.value)))
        .toList();

    filteredList.sort((PaymentAggregate a, PaymentAggregate b) => a.extensions.paidByName.compareTo(b.extensions.paidByName));
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          title: Text(
            widget.eventAggregate.event.eventName,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        floatingActionButton: SpeedDial(
          // both default to 16
          marginRight: 18,
          marginBottom: 20,
          animatedIcon: AnimatedIcons.menu_close,
          animatedIconTheme: const IconThemeData(size: 22.0),
          // this is ignored if animatedIcon is non null
          // child:const  Icon(Icons.add),
          visible: true,
          curve: Curves.bounceIn,
          overlayColor: Colors.black,
          overlayOpacity: 0.5,
          onOpen: () {
            _scaffoldKey.currentState.hideCurrentSnackBar();
          },
          onClose: () => print('DIAL CLOSED'),
          tooltip: 'Speed Dial',
          heroTag: 'speed-dial-hero-tag',
          backgroundColor: Theme.of(context).accentColor,
          foregroundColor: Colors.white,
          elevation: 8.0,
          shape: const CircleBorder(),
          children: <SpeedDialChild>[
            SpeedDialChild(
              child: const Icon(Icons.mail_outline),
              backgroundColor: Colors.green,
              label: 'Email me payment report',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () {
                paymentsService.sendPaymentReportByEmail(eventId: widget.eventAggregate.event.eventId, eventName: widget.eventAggregate.event.eventName).then((Map<String, String> result) {
                  _scaffoldKey.currentState?.hideCurrentSnackBar();
                  if (result['result'].toLowerCase().startsWith('success')) {
                    Utilities.showAlert(context, 'E-mail successfully sent', 'Your payment report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.', 'OK');
                  } else {
                    Utilities.showAlert(context, 'Error sending report', 'There was a problem sending the report to:\r\n\r\n${result['email']}\r\n\r\nPlease try again later or contact us at connect@harriercentral.com', 'OK');
                  }
                });
                Utilities.showInSnackBar(context, _scaffoldKey, 'Payment Report being processed...', durationInSeconds: 10);
              },
            ),
          ],
        ),
        body: (_isLoading || (paymentTotals == null) || (paymentTotals.isEmpty))
            ? const HcCircularProgressIndicator()
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
                              counter: paymentTotals[0]['count'] + paymentTotals[paymentNotPaid.value]['count'],
                              color: (filterValue & 1) != 0 ? Colors.red : Colors.black26,
                              paymentRecordType: paymentNotPaid,
                              currencySymbol: widget.eventAggregate.extensions.curSym,
                              digitsAfterDecimal: widget.eventAggregate.extensions.digAfterDec,
                              onTap: () {
                                filterTapped(1);
                              },
                            ),
                            PaymentTotalsCell(
                              creditAmount: paymentTotals[paymentCash.value]['totalCollected'],
                              counter: paymentTotals[paymentCash.value]['count'],
                              color: (filterValue & 2) != 0 ? Colors.green : Colors.black26,
                              paymentRecordType: paymentCash,
                              currencySymbol: widget.eventAggregate.extensions.curSym,
                              digitsAfterDecimal: widget.eventAggregate.extensions.digAfterDec,
                              onTap: () {
                                filterTapped(2);
                              },
                            ),
                            PaymentTotalsCell(
                              creditAmount: paymentTotals[paymentBankTransfer.value]['totalCollected'],
                              counter: paymentTotals[paymentBankTransfer.value]['count'],
                              color: (filterValue & 16) != 0 ? Colors.green : Colors.black26,
                              paymentRecordType: paymentBankTransfer,
                              currencySymbol: widget.eventAggregate.extensions.curSym,
                              digitsAfterDecimal: widget.eventAggregate.extensions.digAfterDec,
                              onTap: () {
                                filterTapped(16);
                              },
                            ),
                            PaymentTotalsCell(
                              creditAmount: paymentTotals[paymentFreeRun.value]['totalCollected'],
                              counter: paymentTotals[paymentFreeRun.value]['count'],
                              color: (filterValue & 8) != 0 ? Colors.green : Colors.black26,
                              paymentRecordType: paymentFreeRun,
                              currencySymbol: widget.eventAggregate.extensions.curSym,
                              digitsAfterDecimal: widget.eventAggregate.extensions.digAfterDec,
                              onTap: () {
                                filterTapped(8);
                              },
                            ),
                            PaymentTotalsCell(
                              creditAmount: paymentTotals[paymentHashCredit.value]['totalCollected'],
                              counter: paymentTotals[paymentHashCredit.value]['count'],
                              color: (filterValue & 64) != 0 ? Colors.green : Colors.black26,
                              paymentRecordType: paymentHashCredit,
                              currencySymbol: widget.eventAggregate.extensions.curSym,
                              digitsAfterDecimal: widget.eventAggregate.extensions.digAfterDec,
                              onTap: () {
                                filterTapped(64);
                              },
                            ),
                            PaymentTotalsCell(
                              creditAmount: paymentTotals[paymentCashOtherAmount.value]['totalCollected'],
                              counter: paymentTotals[paymentCashOtherAmount.value]['count'],
                              color: (filterValue & 4) != 0 ? Colors.green : Colors.black26,
                              paymentRecordType: paymentCashOtherAmount,
                              currencySymbol: widget.eventAggregate.extensions.curSym,
                              digitsAfterDecimal: widget.eventAggregate.extensions.digAfterDec,
                              onTap: () {
                                filterTapped(4);
                              },
                            ),
                            PaymentTotalsCell(
                              creditAmount: paymentTotals[paymentBankTransferOtherAmount.value]['totalCollected'],
                              counter: paymentTotals[paymentBankTransferOtherAmount.value]['count'],
                              color: (filterValue & 32) != 0 ? Colors.green : Colors.black26,
                              paymentRecordType: paymentBankTransferOtherAmount,
                              currencySymbol: widget.eventAggregate.extensions.curSym,
                              digitsAfterDecimal: widget.eventAggregate.extensions.digAfterDec,
                              onTap: () {
                                filterTapped(32);
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
                      child: filteredList.isEmpty
                          ? const Center(child: Text('No transactions available.'))
                          : RefreshIndicator(
                              onRefresh: () => _refreshSqlTablesFromBackend(),
                              displacement: 40.0,
                              child: ListView.separated(
                                separatorBuilder: (BuildContext context, int index) => const Divider(
                                  height: 1.0,
                                  color: Colors.black45,
                                ),
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: filteredList.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final bool needsConfirm = ((filteredList[index].payment.paymentType == paymentBankTransfer.value) || (filteredList[index].payment.paymentType == paymentBankTransferOtherAmount.value)) && (filteredList[index].payment.confirmedBy == null);
                                  return (((filteredList[index].payment.paymentType ?? paymentNotPaid.value) != paymentNotPaid.value) && !needsConfirm)
                                      ? listItem(filteredList[index], context)
                                      : Dismissible(
                                          key: Key(index.toString()),
                                          confirmDismiss: (DismissDirection direction) {
                                            print(direction.toString() + ' ' + index.toString() + ' ' + widget.eventAggregate.extensions.nonMemberPrice.toString());
                                            setState(() {
                                              filteredList[index].extensions.isLoading = true;
                                            });
                                            if (needsConfirm) {
                                              payForEvent(filteredList[index], paymentConfirmBankTransfer.value, -1).then((List<dynamic> results) {
                                                _refreshListsFromTable().then((void dummy) {
                                                  setState(() {
                                                    refreshTotals();
                                                  });
                                                });
                                              });
                                            } else {
                                              final num paymentAmount = (filteredList[index].extensions.isMember != 0) ? filteredList[index].extensions.eventPriceForMembers : filteredList[index].extensions.eventPriceForNonMembers;
                                              showExtrasDialog(context, _scaffoldKey.currentState, direction == DismissDirection.endToStart ? paymentCash.value : paymentBankTransfer.value, filteredList[index], paymentAmount);
                                            }
                                            return Future<bool>.value(false);
                                          },
                                          background: needsConfirm
                                              ? Container(
                                                  color: Colors.purple,
                                                  child: Row(children: <Widget>[
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 15.0),
                                                      child: Image.asset('images/icons/payment_type_4.png', height: 25.0, width: 25.0, color: Colors.white),
                                                    ),
                                                    const Padding(
                                                      padding: EdgeInsets.only(left: 15.0),
                                                      child: Text('Confirm Bank Transfer', style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 17.0, height: 1.0)),
                                                    )
                                                  ]))
                                              : Container(
                                                  color: Colors.blue,
                                                  child: Row(children: <Widget>[
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 15.0),
                                                      child: Image.asset('images/icons/payment_type_4.png', height: 25.0, width: 25.0, color: Colors.white),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 15.0),
                                                      child: Text(
                                                          '${(widget.eventAggregate.event.eventPriceForExtras ?? 0) != 0 ? '' : Utilities.getFormattedMoney((filteredList[index].extensions.isMember != 0) ? filteredList[index].extensions.eventPriceForMembers : filteredList[index].extensions.eventPriceForNonMembers, widget.eventAggregate.extensions.digAfterDec, widget.eventAggregate.extensions.curSym) + ' '}Bank Transfer',
                                                          style: const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 17.0, height: 1.0)),
                                                    )
                                                  ])),
                                          secondaryBackground: needsConfirm
                                              ? Container(
                                                  color: Colors.purple,
                                                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
                                                    Padding(
                                                      padding: const EdgeInsets.only(right: 15.0),
                                                      child: Image.asset('images/icons/payment_type_4.png', height: 25.0, width: 25.0, color: Colors.white),
                                                    ),
                                                    const Padding(
                                                      padding: EdgeInsets.only(right: 15.0),
                                                      child: Text('Confirm bank transfer', style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 17.0, height: 1.0)),
                                                    )
                                                  ]))
                                              : Container(
                                                  color: Colors.green,
                                                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
                                                    Padding(
                                                      padding: const EdgeInsets.only(right: 15.0),
                                                      child: Image.asset('images/icons/payment_type_3.png', height: 25.0, width: 25.0, color: Colors.white),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.only(right: 15.0),
                                                      child: Text(
                                                          '${(widget.eventAggregate.event.eventPriceForExtras ?? 0) != 0 ? '' : Utilities.getFormattedMoney((filteredList[index].extensions.isMember != 0) ? filteredList[index].extensions.eventPriceForMembers : filteredList[index].extensions.eventPriceForNonMembers, widget.eventAggregate.extensions.digAfterDec, widget.eventAggregate.extensions.curSym) + ' '}Cash',
                                                          style: const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 17.0, height: 1.0)),
                                                    )
                                                  ])),
                                          onDismissed: (DismissDirection direction) {
                                            print(direction.toString() + ' NOTE: We should never reach this point');
                                          },
                                          child: listItem(filteredList[index], context),
                                        );
                                },
                              ),
                            ),
                    ),
                  ),
                ],
              ));
  }

  void showExtrasDialog(BuildContext context, ScaffoldState scaffoldState, int paymentType, PaymentAggregate packMember, num otherAmount) {
    scaffoldState.removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
    if (((paymentType == paymentFreeRun.value) || (paymentType == paymentCash.value) || (paymentType == paymentBankTransfer.value) || (paymentType == paymentCashOtherAmount.value) || (paymentType == paymentHashCredit.value) || (paymentType == paymentBankTransferOtherAmount.value)) &&
        ((widget.eventAggregate.event.eventPriceForExtras ?? 0) != 0)) {
      final num runOnlyPrice = packMember.extensions.isMember != 0 ? widget.eventAggregate.extensions.memberPrice : widget.eventAggregate.extensions.nonMemberPrice;
      final num runPlusExtrasPrice = runOnlyPrice + widget.eventAggregate.event.eventPriceForExtras;

      final String runOnlyPriceStr = Utilities.getFormattedMoney(runOnlyPrice, widget.eventAggregate.extensions.digAfterDec, widget.eventAggregate.extensions.curSym);
      final String runPlusExtrasPriceStr = Utilities.getFormattedMoney(runPlusExtrasPrice, widget.eventAggregate.extensions.digAfterDec, widget.eventAggregate.extensions.curSym);

      final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
        <String, dynamic>{
          'title': 'Run only ($runOnlyPriceStr)',
          'icon': <Widget>[
            Container(),
          ],
          'returnValue': payForRunOnly,
        },
        <String, dynamic>{
          'title': 'Run + ' + widget.eventAggregate.event.extrasDescription + ' ($runPlusExtrasPriceStr)',
          'icon': <Widget>[
            Container(),
          ],
          'returnValue': payForRunAndExtras
        },
      ];

      final MultipleChoicePopup popup = MultipleChoicePopup(
          title: 'Payment options',
          buttons: buttons,
          cancelButtonTitle: 'Cancel',
          buttonPress: (dynamic payForExtras) {
            payForEvent(packMember, paymentType, otherAmount, doPayForExtras: payForExtras).then((List<dynamic> results) {
              _refreshListsFromTable().then((void dummy) {
                setState(() {
                  refreshTotals();
                  BankTransferQr.showBankTransferSnackbar(widget.eventAggregate, results, paymentType, context, packMember.extensions.paidByName, packMember.extensions.isMember, otherAmount);
                });
              });
            });
          });

      showDialog<void>(
          context: context,
          barrierDismissible: false, // user must tap button!
          builder: (BuildContext context) {
            return popup;
          });
    } else {
      // there are no extras so just pay for the run without any extras dialog
      payForEvent(packMember, paymentType, otherAmount, doPayForExtras: payForRunOnly).then((List<dynamic> results) {
        _refreshListsFromTable().then((void dummy) {
          setState(() {
            refreshTotals();
            BankTransferQr.showBankTransferSnackbar(widget.eventAggregate, results, paymentType, context, packMember.extensions.paidByName, packMember.extensions.isMember, otherAmount);
          });
        });
      });
    }
  }

  void filterTapped(int positionFlag) {
    if (filterValue == 127) {
      filterValue = positionFlag;
    } else {
      filterValue = filterValue ^ positionFlag;
    }

    if (filterValue == 0) {
      filterValue = 127;
    }

    applyFilter();
    setState(() {});
  }

  Container listItem(PaymentAggregate item, BuildContext topContext) {
    return Container(
      height: 60.0,
      padding: const EdgeInsets.only(top: 10),
      child: PaymentReportListItem(
        currencySymbol: widget.eventAggregate.extensions.curSym,
        digitsAfterDecimal: widget.eventAggregate.extensions.digAfterDec,
        paymentReportItem: item,
        onTap: () {
          Scaffold.of(topContext).hideCurrentSnackBar();
          if ((item.payment.paymentType == null) || (item.payment.paymentType == paymentNotPaid.value)) {
            final PaymentPopup pp = PaymentPopup(
              amount: (item.extensions.isMember != 0) ? item.extensions.eventPriceForMembers : item.extensions.eventPriceForNonMembers,
              creditAllowed: 1, // TODO(James): fix this in the DB so that Kennnels can disable credit
              creditRemaining: item.extensions.creditAvailable,
              currencySymbol: widget.eventAggregate.extensions.curSym,
              hemId: item.extensions.pkHemId,
              decimalDigits: widget.eventAggregate.extensions.digAfterDec,
              // valueChanged: (num value) {
              //   finalValue = value;
              // },
            );

            final Future<PaymentPopupResult> dlg = showDialog<PaymentPopupResult>(
                context: context,
                barrierDismissible: false, // user must tap button!
                builder: (BuildContext context) {
                  return pp;
                });

            dlg.then(
              (PaymentPopupResult paymentValue) {
                if (paymentValue.transactionType != -1) {
                  setState(() {
                    item.extensions.isLoading = true;
                  });

                  //final num paymentAmount = (item.extensions.isMember != 0) ? item.extensions.eventPriceForMembers : item.extensions.eventPriceForNonMembers;
                  showExtrasDialog(context, _scaffoldKey.currentState, paymentValue.transactionType, item, paymentValue.transactionValue);

                  // payForEvent(item, paymentValue.transactionType, paymentValue.transactionValue).then((List<dynamic> results) {
                  //   _refreshListsFromTable().then((void dummy) {
                  //     setState(() {
                  //       refreshTotals();
                  //       BankTransferQr.showBankTransferSnackbar(widget.eventAggregate, results, paymentValue.transactionType, topContext, item.extensions.paidByName, item.extensions.isMember, paymentValue.transactionValue);
                  //     });
                  //   });
                  // });
                }
              },
            );
          } else {
            _displayPaymentDetails(item, context).then((String action) {
              if (action == 'cancel') {
                setState(() {
                  item.extensions.isLoading = true;
                });
                payForEvent(item, paymentNotPaid.value, 0).then((List<dynamic> results) {
                  _refreshListsFromTable().then((void dummy) {
                    setState(() {
                      refreshTotals();
                    });
                  });
                });
              } else if (action == 'confirm') {
                setState(() {
                  item.extensions.isLoading = true;
                });
                payForEvent(item, paymentConfirmBankTransfer.value, -1).then((List<dynamic> results) {
                  _refreshListsFromTable().then((void dummy) {
                    setState(() {
                      refreshTotals();
                    });
                  });
                });
              }
            });
          }
        },
      ),
    );
  }

  Future<String> _displayPaymentDetails(PaymentAggregate item, BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        const TextStyle headingStyle = TextStyle(fontFamily: 'AvenirNextMedium', fontStyle: FontStyle.normal, fontSize: 16.0);

        const TextStyle bodyStyle = TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, fontSize: 16.0);
        final TextStyle bodyStyleRed = TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, fontSize: 16.0, color: Colors.red[600]);

        String paymentTypeStr = '';

        switch (item.payment.paymentType) {
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
        const num spacer = 6.0;

        final String amountStr = Utilities.getFormattedMoney(item?.payment?.creditAmount ?? 0, widget.eventAggregate.extensions.digAfterDec, widget.eventAggregate.extensions.curSym);
        final String extrasPriceStr = Utilities.getFormattedMoney(item?.extensions?.extrasPrice ?? 0, widget.eventAggregate.extensions.digAfterDec, widget.eventAggregate.extensions.curSym);

        return AlertDialog(
          title: const Text('Payment Detail'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Pay Ref:',
                      style: headingStyle,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    flex: flexLeft,
                  ),
                  const SizedBox(width: spacer, height: 10.0),
                  Expanded(
                      child: Text(
                        item.payment.paymentReference,
                        style: bodyStyle,
                      ),
                      flex: flexRight),
                ]),
                Row(children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Paid by:',
                      style: headingStyle,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    flex: flexLeft,
                  ),
                  const SizedBox(width: spacer, height: 10.0),
                  Expanded(
                      child: Text(
                        item.extensions.paidByName,
                        style: bodyStyle,
                      ),
                      flex: flexRight),
                ]),
                Row(children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Paid to:',
                      style: headingStyle,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    flex: flexLeft,
                  ),
                  const SizedBox(width: spacer, height: 10.0),
                  Expanded(
                      child: Text(
                        item.extensions.paidToName,
                        style: bodyStyle,
                      ),
                      flex: flexRight),
                ]),
                Row(children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Amount:',
                      style: headingStyle,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    flex: flexLeft,
                  ),
                  const SizedBox(width: spacer, height: 10.0),
                  Expanded(
                      child: Text(
                        amountStr,
                        style: bodyStyle,
                      ),
                      flex: flexRight),
                ]),
                item.extensions.extrasPrice == 0
                    ? Container()
                    : Row(children: <Widget>[
                        const Expanded(
                          child: Text(
                            'Extras:',
                            style: headingStyle,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          flex: flexLeft,
                        ),
                        const SizedBox(width: spacer, height: 10.0),
                        Expanded(
                            child: Text(
                              item.extensions.extrasDescription,
                              style: bodyStyle,
                            ),
                            flex: flexRight),
                      ]),
                item.extensions.extrasPrice == 0
                    ? Container()
                    : Row(children: <Widget>[
                        const Expanded(
                          child: Text(
                            'Ex. Paid:',
                            style: headingStyle,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          flex: flexLeft,
                        ),
                        const SizedBox(width: spacer, height: 10.0),
                        Expanded(
                            child: Text(
                              item.payment.doPayForExtras == 0 ? 'No' : extrasPriceStr,
                              style: bodyStyle,
                            ),
                            flex: flexRight),
                      ]),
                Row(children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Date:',
                      style: headingStyle,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    flex: flexLeft,
                  ),
                  const SizedBox(width: spacer, height: 10.0),
                  Expanded(
                      child: Text(
                        (item?.payment?.paidDate == null) ? '' : DateFormat('MMM dd, yyyy').format(item.payment.paidDate),
                        style: bodyStyle,
                      ),
                      flex: flexRight),
                ]),
                Row(children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Time:',
                      style: headingStyle,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    flex: flexLeft,
                  ),
                  const SizedBox(width: spacer, height: 10.0),
                  Expanded(
                      child: Text(
                        (item?.payment?.paidDate == null) ? '' : DateFormat('kk:mm').format(item.payment.paidDate),
                        style: bodyStyle,
                      ),
                      flex: flexRight),
                ]),
                Row(children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Type:',
                      style: headingStyle,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    flex: flexLeft,
                  ),
                  const SizedBox(width: spacer, height: 10.0),
                  Expanded(
                      child: Text(
                        paymentTypeStr,
                        style: bodyStyle,
                      ),
                      flex: flexRight),
                ]),
                ((item.payment.paymentType != paymentBankTransfer.value) && (item.payment.paymentType != paymentBankTransferOtherAmount.value))
                    ? Container()
                    : Row(children: <Widget>[
                        const Expanded(
                          child: Text(
                            'Confirmed:',
                            style: headingStyle,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          flex: flexLeft,
                        ),
                        const SizedBox(width: spacer, height: 10.0),
                        Expanded(
                            child: Text(
                              (item?.payment?.confirmedDate == null) ? '<not confirmed>' : item.extensions.confByName,
                              style: (item?.payment?.confirmedDate == null) ? bodyStyleRed : bodyStyle,
                            ),
                            flex: flexRight),
                      ]),
                ((item.payment.paymentType != paymentBankTransfer.value) && (item.payment.paymentType != paymentBankTransferOtherAmount.value))
                    ? Container()
                    : Row(children: <Widget>[
                        const Expanded(
                          child: Text(
                            'Conf on:',
                            style: headingStyle,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          flex: flexLeft,
                        ),
                        const SizedBox(width: spacer, height: 10.0),
                        Expanded(
                            child: Text(
                              (item?.payment?.confirmedDate == null) ? '<not confirmed>' : DateFormat('MMM dd, yyyy kk:mm').format(item.payment.paidDate),
                              style: (item?.payment?.confirmedDate == null) ? bodyStyleRed : bodyStyle,
                            ),
                            flex: flexRight),
                      ]),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Center(
                    child: (((item.payment.paymentType != paymentBankTransfer.value) && (item.payment.paymentType != paymentBankTransferOtherAmount.value)) || (item.payment.confirmedBy != null) || (widget.eventAggregate.kennel.bankBic == null))
                        ? Container()
                        : RaisedButton(
                            onPressed: () {
                              final String remittanceInfo = item.payment.paymentReference + '-${item.extensions.paidByName}';
                              BankTransferQr.showBankTransferQrCode(context, widget.eventAggregate, item.extensions.isMember != 0, packMemberNameForDisplay: item.extensions.paidByName, remitString: remittanceInfo, remitAmount: item.payment.creditAmount);
                            },
                            child: Text('Show Payment QR Code', style: buttonTextStyle),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Center(
                    child: (((item.payment.paymentType != paymentBankTransfer.value) && (item.payment.paymentType != paymentBankTransferOtherAmount.value)) || (item.payment.confirmedBy != null))
                        ? Container()
                        : RaisedButton(
                            onPressed: () {
                              Navigator.of(context, rootNavigator: true).pop('confirm');
                            },
                            child: Text('Confirm Bank Transfer', style: buttonTextStyle),
                          ),
                  ),
                )
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
            FlatButton(
              child: const Text('Cancel transaction'),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop('cancel');
              },
            ),
            FlatButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop('close');
              },
            ),
          ],
        );
      },
    );
  }
}
