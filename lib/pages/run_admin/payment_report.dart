import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

import 'package:harrier_central/pages/run_admin/payment_popup.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/styles.dart';
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

class PaymentReportPage extends StatefulWidget {
  const PaymentReportPage({Key key, @required this.event}) : super(key: key);

  final Map<String, dynamic> event;

  @override
  PaymentReportState createState() => PaymentReportState();
}

class PaymentReportState extends State<PaymentReportPage> {
  PaymentReportState();

  List<PaymentsModel> paymentsList = <PaymentsModel>[];
  List<PaymentsModel> filteredList = <PaymentsModel>[];

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
      final bool result = await cSrv.updateFromBackend(db, SyncEventAdminService.flagPaymentsTable | SyncEventAdminService.flagHasherEventMapTable | SyncEventAdminService.flagHasherKennelMapTable, true, widget.event['eventId']);
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
          hem.hemId as pkHemId,
          COALESCE(CASE WHEN hem.displayName IS NULL THEN NULL ELSE hem.displayName || CASE WHEN hem.virginVisitorType = 1 THEN " (Virgin)" ELSE " (Visitor)" END END, h.dispName,'<hasher not found>') as paidByName,
          COALESCE(paidTo.dispName,'<hasher not found>') as paidToName,
          COALESCE(hkm.isMember,0) as isMember,
          COALESCE(credits.currentBalance,0) as creditAvailable,
          pay.*,
          coalesce(e.eventPriceForMembers,k.defaultPriceForMembers,0) as eventPriceForMembers,
          coalesce(e.eventPriceForNonMembers,k.defaultPriceForNonMembers,0) as eventPriceForNonMembers
          FROM ${HasherEventMapTableHelper.getTableName(HasherEventMapTableType.eventAdmin)} hem
          INNER JOIN ${NarrowEventsTableHelper.tableName} e on e.eventId = hem.eventId
          INNER JOIN ${KennelsTableHelper.tableName} k on k.kennelId = e.kennelId
          LEFT OUTER JOIN ${HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.eventAdmin)} hkm on hkm.userId = hem.userId and hkm.kennelId = "${widget.event['kennelId']}"
          LEFT OUTER JOIN ${HashersTableHelper.tableName} h on h.hasherId = hem.userId
          LEFT OUTER JOIN ${PaymentsTableHelper.tableName} pay on pay.hemId = hem.hemId and pay.CancelledBy IS NULL
          LEFT OUTER JOIN ${HashersTableHelper.tableName} paidTo on paidTo.hasherId = pay.paidTo
          LEFT OUTER JOIN ${KennelCreditsTableHelper.tableName} credits on credits.userId = hkm.userId and credits.kennelId = hkm.kennelId
          WHERE hem.attendenceState >= 20
          ''';

    final List<Map<String, dynamic>> results = await db.rawQuery(sql);
    // TODO(James): Split this into aggregates and clean up!
    paymentsList = PaymentsTableHelper.listFromMap(results);
    applyFilter();
  }

  List<Map<String, dynamic>> paymentTotals;

  void refreshTotals() {
    paymentTotals = <Map<String, dynamic>>[];
    DBProvider.db.database.then((Database db) {
      try {
        final String sql = '''

          select 0 as paymentType, (SELECT COUNT(*) from ${HasherEventMapTableHelper.getTableName(HasherEventMapTableType.eventAdmin)} hem 
          WHERE  hem.attendenceState >= 20
          AND hem.hemId not in (SELECT hemId from ${PaymentsTableHelper.tableName} pay3 where pay3.cancelledBy IS NULL) ) as count, 5.55 as totalCollected
            
          UNION
          select paymentType, 
            (
                SELECT COUNT(*) 
                FROM ${PaymentsTableHelper.tableName} pay 
                INNER JOIN ${HasherEventMapTableHelper.getTableName(HasherEventMapTableType.eventAdmin)} hem on hem.hemId = pay.hemId AND hem.attendenceState >= 20
                WHERE pay.paymentType = x.paymentType AND pay.cancelledBy IS NULL

            ) as count,
            (
                SELECT SUM(pay2.creditAmount) 
                FROM ${PaymentsTableHelper.tableName} pay2 
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

  void payForEvent(PaymentsModel item, int paymentType, num amount) {
    final PaymentsService paySrv = PaymentsService();
    final Future<void> retVal = paySrv.payForEvent(
      widget.event['eventId'],
      GUID_EMPTY,
      item.pkHemId,
      paymentType,
      amount,
      attendenceAtHash.value,
    );
    retVal.then(
      (void paymentResult) {
        _refreshListsFromTable().then((void dummy) {
          setState(() {
            refreshTotals();
          });
        });
      },
    );
  }

  void applyFilter() {
    filteredList = paymentsList
        .where((PaymentsModel evt) =>
            ((filterValue & 1) != 0 && ((evt.paymentType ?? paymentNotPaid.value) == paymentNotPaid.value)) ||
            ((filterValue & 2) != 0 && (evt.paymentType == paymentCash.value)) ||
            ((filterValue & 4) != 0 && (evt.paymentType == paymentCashOtherAmount.value)) ||
            ((filterValue & 8) != 0 && (evt.paymentType == paymentFreeRun.value)) ||
            ((filterValue & 16) != 0 && (evt.paymentType == paymentBankTransfer.value)) ||
            ((filterValue & 32) != 0 && (evt.paymentType == paymentBankTransferOtherAmount.value)) ||
            ((filterValue & 64) != 0 && (evt.paymentType == paymentHashCredit.value)))
        .toList();

    filteredList.sort((PaymentsModel a, PaymentsModel b) => a.paidByName.compareTo(b.paidByName));
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
            widget.event['eventName'],
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
          onOpen: () => print('OPENING DIAL'),
          onClose: () => print('DIAL CLOSED'),
          tooltip: 'Speed Dial',
          heroTag: 'speed-dial-hero-tag',
          backgroundColor: Theme.of(context).accentColor,
          foregroundColor: Colors.white,
          elevation: 8.0,
          shape: CircleBorder(),
          children: <SpeedDialChild>[
            SpeedDialChild(
              child: const Icon(Icons.mail_outline),
              backgroundColor: Colors.green,
              label: 'Email me payment report',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () {
                PaymentsService.sendPaymentReportByEmail(eventId: widget.event['eventId'], eventName: widget.event['eventName']).then((Map<String, String> result) {
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
                              currencySymbol: widget.event['currencySymbol'],
                              digitsAfterDecimal: widget.event['digitsAfterDecimal'],
                              onTap: () {
                                filterTapped(1);
                              },
                            ),
                            PaymentTotalsCell(
                              creditAmount: paymentTotals[paymentCash.value]['totalCollected'],
                              counter: paymentTotals[paymentCash.value]['count'],
                              color: (filterValue & 2) != 0 ? Colors.green : Colors.black26,
                              paymentRecordType: paymentCash,
                              currencySymbol: widget.event['currencySymbol'],
                              digitsAfterDecimal: widget.event['digitsAfterDecimal'],
                              onTap: () {
                                filterTapped(2);
                              },
                            ),
                                                        PaymentTotalsCell(
                              creditAmount: paymentTotals[paymentBankTransfer.value]['totalCollected'],
                              counter: paymentTotals[paymentBankTransfer.value]['count'],
                              color: (filterValue & 16) != 0 ? Colors.green : Colors.black26,
                              paymentRecordType: paymentBankTransfer,
                              currencySymbol: widget.event['currencySymbol'],
                              digitsAfterDecimal: widget.event['digitsAfterDecimal'],
                              onTap: () {
                                filterTapped(16);
                              },
                            ),
                                                        PaymentTotalsCell(
                              creditAmount: paymentTotals[paymentFreeRun.value]['totalCollected'],
                              counter: paymentTotals[paymentFreeRun.value]['count'],
                              color: (filterValue & 8) != 0 ? Colors.green : Colors.black26,
                              paymentRecordType: paymentFreeRun,
                              currencySymbol: widget.event['currencySymbol'],
                              digitsAfterDecimal: widget.event['digitsAfterDecimal'],
                              onTap: () {
                                filterTapped(8);
                              },
                            ),
                                                        PaymentTotalsCell(
                              creditAmount: paymentTotals[paymentHashCredit.value]['totalCollected'],
                              counter: paymentTotals[paymentHashCredit.value]['count'],
                              color: (filterValue & 64) != 0 ? Colors.green : Colors.black26,
                              paymentRecordType: paymentHashCredit,
                              currencySymbol: widget.event['currencySymbol'],
                              digitsAfterDecimal: widget.event['digitsAfterDecimal'],
                              onTap: () {
                                filterTapped(64);
                              },
                            ),
                            PaymentTotalsCell(
                              creditAmount: paymentTotals[paymentCashOtherAmount.value]['totalCollected'],
                              counter: paymentTotals[paymentCashOtherAmount.value]['count'],
                              color: (filterValue & 4) != 0 ? Colors.green : Colors.black26,
                              paymentRecordType: paymentCashOtherAmount,
                              currencySymbol: widget.event['currencySymbol'],
                              digitsAfterDecimal: widget.event['digitsAfterDecimal'],
                              onTap: () {
                                filterTapped(4);
                              },
                            ),

                            PaymentTotalsCell(
                              creditAmount: paymentTotals[paymentBankTransferOtherAmount.value]['totalCollected'],
                              counter: paymentTotals[paymentBankTransferOtherAmount.value]['count'],
                              color: (filterValue & 32) != 0 ? Colors.green : Colors.black26,
                              paymentRecordType: paymentBankTransferOtherAmount,
                              currencySymbol: widget.event['currencySymbol'],
                              digitsAfterDecimal: widget.event['digitsAfterDecimal'],
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
                                  return (filteredList[index].paymentType ?? paymentNotPaid.value) != paymentNotPaid.value
                                      ? listItem(filteredList[index])
                                      : Dismissible(
                                          key: Key(index.toString()),
                                          confirmDismiss: (DismissDirection direction) {
                                            print(direction.toString() + ' ' + index.toString() + ' ' + widget.event['eventPriceForNonMembers'].toString());
                                            setState(() {
                                              filteredList[index].isLoading = true;
                                            });
                                            payForEvent(filteredList[index], direction == DismissDirection.endToStart ? 3 : 4, (filteredList[index].isMember != 0) ? filteredList[index].eventPriceForMembers : filteredList[index].eventPriceForNonMembers);
                                            return Future<bool>.value(false);
                                          },
                                          background: Container(
                                              color: Colors.blue,
                                              child: Row(children: <Widget>[
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 15.0),
                                                  child: Image.asset('images/icons/payment_type_4.png', height: 25.0, width: 25.0, color: Colors.white),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 15.0),
                                                  child: Text(
                                                      '${Utilities.getFormattedMoney((filteredList[index].isMember != 0) ? filteredList[index].eventPriceForMembers : filteredList[index].eventPriceForNonMembers, widget.event['digitsAfterDecimal'], widget.event['currencySymbol'])} Bank Transfer',
                                                      style: const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 17.0, height: 1.0)),
                                                )
                                              ])),
                                          secondaryBackground: Container(
                                              color: Colors.green,
                                              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
                                                Padding(
                                                  padding: const EdgeInsets.only(right: 15.0),
                                                  child: Image.asset('images/icons/payment_type_3.png', height: 25.0, width: 25.0, color: Colors.white),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(right: 15.0),
                                                  child: Text('${Utilities.getFormattedMoney((filteredList[index].isMember != 0) ? filteredList[index].eventPriceForMembers : filteredList[index].eventPriceForNonMembers, widget.event['digitsAfterDecimal'], widget.event['currencySymbol'])} Cash',
                                                      style: const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 17.0, height: 1.0)),
                                                )
                                              ])),
                                          onDismissed: (DismissDirection direction) {
                                            print(direction.toString() + ' NOTE: We should never reach this point');
                                          },
                                          child: listItem(filteredList[index]),
                                        );
                                },
                              ),
                            ),
                    ),
                  ),
                ],
              ));
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

  Container listItem(PaymentsModel item) {
    return Container(
      height: 60.0,
      padding: const EdgeInsets.only(top: 10),
      child: PaymentReportListItem(
        paymentReportItem: item,
        currencySymbol: widget.event['currencySymbol'],
        digitsAfterDecimal: widget.event['digitsAfterDecimal'],
        onTap: () {
          if ((item.paymentType == null) || (item.paymentType == paymentNotPaid.value)) {
            final PaymentPopup pp = PaymentPopup(
              amount: (item.isMember != 0) ? item.eventPriceForMembers : item.eventPriceForNonMembers,
              creditAllowed: 1, // TODO(James): fix this in the DB so that Kennnels can disable credit
              creditRemaining: item.creditAvailable,
              currencySymbol: widget.event['currencySymbol'],
              hemId: item.pkHemId,
              decimalDigits: widget.event['decimalDigits'],
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
                    item.isLoading = true;
                  });
                  payForEvent(item, paymentValue.transactionType, paymentValue.transactionValue);
                }
              },
            );
          } else {
            _displayPaymentDetails(item, context).then((bool doCancelTransaction) {
              if (doCancelTransaction) {
                setState(() {
                  item.isLoading = true;
                });
                payForEvent(item, paymentNotPaid.value, 0);
              }
            });
          }
        },
      ),
    );
  }

  Future<bool> _displayPaymentDetails(PaymentsModel item, BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        const TextStyle headingStyle = TextStyle(fontFamily: 'AvenirNextMedium', fontStyle: FontStyle.normal, fontSize: 16.0);

        const TextStyle bodyStyle = TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, fontSize: 16.0);

        String paymentTypeStr = '';

        switch (item.paymentType) {
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

        final String amountStr = Utilities.getFormattedMoney(item?.creditAmount ?? 0, widget.event['digitsAfterDecimal'], widget.event['currencySymbol']);

        return AlertDialog(
          title: const Text('Payment Detail'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const <Widget>[
                          Text(
                            'Pay Ref:',
                            style: headingStyle,
                          ),
                          Text(
                            'Paid by:',
                            style: headingStyle,
                          ),
                          Text(
                            'Paid to:',
                            style: headingStyle,
                          ),
                          Text(
                            'Amount:',
                            style: headingStyle,
                          ),
                          Text(
                            'Date:',
                            style: headingStyle,
                          ),
                          Text(
                            'Time:',
                            style: headingStyle,
                          ),
                          Text(
                            'Type:',
                            style: headingStyle,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.paymentReference,
                              style: bodyStyle,
                            ),
                            Text(
                              item.paidByName,
                              style: bodyStyle,
                              maxLines: 1,
                            ),
                            // AutoSizeText(
                            //   item.paidBy,
                            //   style: bodyStyle,
                            //   maxLines: 1,
                            //   minFontSize: 12.0,
                            // ),
                            Text(
                              item.paidToName,
                              style: bodyStyle,
                              maxLines: 1,
                            ),

                            // AutoSizeText(
                            //   item.paidTo,
                            //   style: bodyStyle,
                            //   maxLines: 1,
                            //   minFontSize: 12.0,
                            // ),
                            Text(
                              amountStr,
                              style: bodyStyle,
                            ),
                            Text(
                              (item?.paidDate == null) ? '' : DateFormat('MMM dd, yyyy').format(item.paidDate),
                              style: bodyStyle,
                            ),
                            Text(
                              (item?.paidDate == null) ? '' : DateFormat('kk:mm').format(item.paidDate),
                              style: bodyStyle,
                            ),
                            Text(
                              paymentTypeStr,
                              style: bodyStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: const Text('Cancel transaction'),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop(true);
              },
            ),
            FlatButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop(false);
              },
            ),
          ],
        );
      },
    );
  }
}
