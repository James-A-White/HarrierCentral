import 'dart:async';

import 'package:flutter/material.dart';

import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/remote_api_data/payment_report_scoped_model.dart';
import 'package:harrier_central/pages/kennel_admin/add_member_page.dart';
import 'package:harrier_central/widgets/payment_report_list_item.dart';
import 'package:harrier_central/data_models/payment_report_model.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:intl/intl.dart';

import 'package:scoped_model/scoped_model.dart';

class PaymentReportPage extends StatelessWidget {
  final String eventId;
  final String currencySymbol;
  final int digitsAfterDecimal;
  final String eventName;

  PaymentReportPage(
      {Key key,
      @required this.eventId,
      @required this.currencySymbol,
      @required this.digitsAfterDecimal,
      @required this.eventName})
      : super(key: key);

  final PaymentReportScopedModel paymentReportModel =
      PaymentReportScopedModel();

  @override
  Widget build(BuildContext context) {
    if ((paymentReportModel?.paymentReportsList?.length ?? 0) == 0) {
      paymentReportModel.getPaymentReportsFromBackend(1, true, eventId);
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          eventName,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: ScopedModel<PaymentReportScopedModel>(
          model: paymentReportModel,
          child: PaymentReportsListPageBody(
            eventId: eventId,
            currencySymbol: currencySymbol,
            digitsAfterDecimal: digitsAfterDecimal,
          )),
    );
  }
}

class PaymentReportsListPageBody extends StatefulWidget {
  final String eventId;
  final String currencySymbol;
  final int digitsAfterDecimal;

  PaymentReportsListPageBody(
      {Key key,
      @required this.eventId,
      @required this.currencySymbol,
      @required this.digitsAfterDecimal})
      : super(key: key);

  _PaymentReportsListPageBodyState createState() =>
      _PaymentReportsListPageBodyState();
}

class _PaymentReportsListPageBodyState
    extends State<PaymentReportsListPageBody> {
  BuildContext context;
  PaymentReportScopedModel model;
  int pageIndex = 1;

  int filterValue = 127;

  @override
  Widget build(BuildContext context) {
    this.context = context;

    return ScopedModelDescendant<PaymentReportScopedModel>(
      builder:
          (BuildContext context, Widget child, PaymentReportScopedModel model) {
        this.model = model;
        return model.isLoading
            ? _buildCircularProgressIndicator()
            : _buildListView();
      },
    );
  }

  Widget _buildCircularProgressIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Future<Null> _handleRefresh() async {
    model.getPaymentReportsFromBackend(1, false, widget.eventId);
    model.notifyListeners();

    return null;
  }

  void filterTapped(int positionFlag, EnumPaymentType paymentType) {
    if (filterValue == 127) {
      filterValue = positionFlag;
    } else {
      filterValue = filterValue ^ positionFlag;
    }

    if (filterValue == 0) {
      filterValue = 127;
    }

    setState(() {});
  }

  Widget _buildListView() {
    List<PaymentReportModel> filteredList = model.paymentReportsList
        .where((PaymentReportModel evt) =>
            ((filterValue & 1) != 0 &&
                (evt.paymentType.value == paymentNotPaid.value)) ||
            ((filterValue & 2) != 0 &&
                (evt.paymentType.value == paymentCash.value)) ||
            ((filterValue & 4) != 0 &&
                (evt.paymentType.value == paymentCashOtherAmount.value)) ||
            ((filterValue & 8) != 0 &&
                (evt.paymentType.value == paymentFreeRun.value)) ||
            ((filterValue & 16) != 0 &&
                (evt.paymentType.value == paymentBankTransfer.value)) ||
            ((filterValue & 32) != 0 &&
                (evt.paymentType.value ==
                    paymentBankTransferOtherAmount.value)) ||
            ((filterValue & 64) != 0 &&
                (evt.paymentType.value == paymentHashCredit.value)))
        .toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(top: 10),
          color: Colors.white,
          height: 120.0,
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  TotalsCell(
                    model.paymentReportTotalsList,
                    color: (filterValue & 1) != 0 ? Colors.red : Colors.black26,
                    paymentRecordType: paymentNotPaid,
                    currencySymbol: widget.currencySymbol,
                    digitsAfterDecimal: widget.digitsAfterDecimal,
                    onTap: () {
                      filterTapped(1, paymentNotPaid);
                    },
                  ),
                  TotalsCell(
                    model.paymentReportTotalsList,
                    color:
                        (filterValue & 2) != 0 ? Colors.green : Colors.black26,
                    paymentRecordType: paymentCash,
                    currencySymbol: widget.currencySymbol,
                    digitsAfterDecimal: widget.digitsAfterDecimal,
                    onTap: () {
                      filterTapped(2, paymentNotPaid);
                    },
                  ),
                  TotalsCell(
                    model.paymentReportTotalsList,
                    color:
                        (filterValue & 4) != 0 ? Colors.green : Colors.black26,
                    paymentRecordType: paymentCashOtherAmount,
                    currencySymbol: widget.currencySymbol,
                    digitsAfterDecimal: widget.digitsAfterDecimal,
                    onTap: () {
                      filterTapped(4, paymentNotPaid);
                    },
                  ),
                  TotalsCell(
                    model.paymentReportTotalsList,
                    color:
                        (filterValue & 8) != 0 ? Colors.green : Colors.black26,
                    paymentRecordType: paymentFreeRun,
                    currencySymbol: widget.currencySymbol,
                    digitsAfterDecimal: widget.digitsAfterDecimal,
                    onTap: () {
                      filterTapped(8, paymentNotPaid);
                    },
                  ),
                  TotalsCell(
                    model.paymentReportTotalsList,
                    color:
                        (filterValue & 16) != 0 ? Colors.green : Colors.black26,
                    paymentRecordType: paymentBankTransfer,
                    currencySymbol: widget.currencySymbol,
                    digitsAfterDecimal: widget.digitsAfterDecimal,
                    onTap: () {
                      filterTapped(16, paymentNotPaid);
                    },
                  ),
                  TotalsCell(
                    model.paymentReportTotalsList,
                    color:
                        (filterValue & 32) != 0 ? Colors.green : Colors.black26,
                    paymentRecordType: paymentBankTransferOtherAmount,
                    currencySymbol: widget.currencySymbol,
                    digitsAfterDecimal: widget.digitsAfterDecimal,
                    onTap: () {
                      filterTapped(32, paymentNotPaid);
                    },
                  ),
                  TotalsCell(
                    model.paymentReportTotalsList,
                    color:
                        (filterValue & 64) != 0 ? Colors.green : Colors.black26,
                    paymentRecordType: paymentHashCredit,
                    currencySymbol: widget.currencySymbol,
                    digitsAfterDecimal: widget.digitsAfterDecimal,
                    onTap: () {
                      filterTapped(64, paymentNotPaid);
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
                    onRefresh: () => _handleRefresh(),
                    displacement: 40.0,
                    child: ListView.separated(
                      separatorBuilder: (context, index) => Divider(
                            height: 1.0,
                            color: Colors.black45,
                          ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filteredList.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                          height: 40.0,
                          padding: const EdgeInsets.all(0.0),
                          child: PaymentReportListItem(
                            paymentReportItem: filteredList[index],
                            currencySymbol: widget.currencySymbol,
                            digitsAfterDecimal: widget.digitsAfterDecimal,
                            onTap: () {
                              _displayPaymentDetails(
                                  filteredList[index], context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<bool> _displayPaymentDetails(
      PaymentReportModel item, BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        const headingStyle = const TextStyle(
            fontFamily: 'AvenirNextMedium',
            fontStyle: FontStyle.normal,
            fontSize: 16.0);

        const bodyStyle = const TextStyle(
            fontFamily: 'AvenirNextDemiBold',
            fontStyle: FontStyle.normal,
            fontSize: 16.0);

        String paymentTypeStr = '';

        switch (item.paymentType.value) {
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

        String amountStr = Utilities.getFormattedMoney(item?.creditAmount ?? 0,
            widget.digitsAfterDecimal, widget.currencySymbol);

        return AlertDialog(
          title: Text('Payment Detail'),
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
                        children: <Widget>[
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
                        padding: EdgeInsets.only(left: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.paymentReference,
                              style: bodyStyle,
                            ),
                            Text(
                              item.paidBy,
                              style: bodyStyle,
                            ),
                            Text(
                              item.paidTo,
                              style: bodyStyle,
                            ),
                            Text(
                              amountStr,
                              style: bodyStyle,
                            ),
                            Text(
                              (item?.paymentDate == null)
                                  ? ''
                                  : DateFormat('MMM dd, yyyy')
                                      .format(item.paymentDate),
                              style: bodyStyle,
                            ),
                            Text(
                              (item?.paymentDate == null)
                                  ? ''
                                  : DateFormat('kk:mm')
                                      .format(item.paymentDate),
                              style: bodyStyle,
                            ),
                            Text(paymentTypeStr,
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
              child: Text("Close"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
}
