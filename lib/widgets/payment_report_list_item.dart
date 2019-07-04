import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';

import 'package:harrier_central/util/enums.dart';
//import 'package:harrier_central/data/hc3_services/payments_service.dart';
import 'package:harrier_central/pages/run_admin/payment_report.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/styles.dart';

class PaymentReportListItem extends StatelessWidget {
  const PaymentReportListItem({@required this.paymentReportItem, @required this.currencySymbol, @required this.digitsAfterDecimal, @required this.onTap});

  final PaymentAggregate paymentReportItem;
  final String currencySymbol;
  final int digitsAfterDecimal;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    final String amountPaid = Utilities.getFormattedMoney(paymentReportItem.payment.creditAmount ?? 0, digitsAfterDecimal, currencySymbol);

    return InkWell(
      onTap: onTap,
      child: Row(
        //mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width,
            child: Stack(
              //fit: StackFit.expand,
              children: <Widget>[
                Positioned(
                  right: paymentReportItem.extensions.isLoading ? 6.0 : 10.0,
                  top: paymentReportItem.extensions.isLoading ? 2.5 : 7.0,
                  child: paymentReportItem.extensions.isLoading
                      ? Icon(delayIcon, color: Colors.blue[800], size: 37.0)
                      : Image.asset('images/icons/payment_type_${paymentReportItem.payment.paymentType ?? paymentNotPaid.value}.png', height: 30.0, width: 30.0, color: (paymentReportItem.payment.paymentType ?? paymentNotPaid.value) <= paymentNotPaid.value ? Colors.red : Colors.green[700]),
                ),
                Positioned(
                  left: 10.0,
                  top: 7.0,
                  child: Text(
                    '${paymentReportItem.extensions.paidByName}',
                    style: TextStyle(fontFamily: (paymentReportItem.extensions.isMember != 0) ? 'AvenirNextCondensedDemiBold' : 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 22.0, height: 1.0),
                    textAlign: TextAlign.center,
                  ),
                ),
                Positioned(
                  right: 50.0,
                  top: 7.0,
                  child: Text(
                    '$amountPaid',
                    style: TextStyle(
                        color: (((paymentReportItem.payment.paymentType == paymentBankTransfer.value) || (paymentReportItem.payment.paymentType == paymentBankTransferOtherAmount.value)) && (paymentReportItem.payment.confirmedBy == null)) ? Colors.red : Colors.black,
                        fontFamily: 'AvenirNextCondensedDemiBold',
                        fontStyle: FontStyle.normal,
                        fontSize: 22.0,
                        height: 1.0),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
        //),
      ),
    );
  }
}

class PaymentTotalsCell extends StatelessWidget {
  const PaymentTotalsCell({
    @required this.creditAmount,
    @required this.counter,
    @required this.color,
    @required this.paymentRecordType,
    @required this.currencySymbol,
    @required this.digitsAfterDecimal,
    @required this.onTap,
  });

  final EnumPaymentType<int> paymentRecordType;
  final Color color;
  final String currencySymbol;
  final int digitsAfterDecimal;
  final Function onTap;
  final num creditAmount;
  final num counter;

  @override
  Widget build(BuildContext context) {
    final String total = (creditAmount ?? 0) <= 0 ? '' : Utilities.getFormattedMoney(creditAmount ?? 0, digitsAfterDecimal, currencySymbol);

    const TextStyle textStyle = TextStyle(color: Colors.black, fontSize: 24.0, fontFamily: 'AvenirNextCondensedDemiBold');
    return Container(
      width: 40,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 0.0),
            child: Text(
              (counter ?? 0).toString(),
              style: textStyle,
            ),
          ),
          IconButton(
            padding: const EdgeInsets.all(0),
            onPressed: onTap,
            icon: Image.asset('images/icons/payment_type_${paymentRecordType.value}.png', height: 35.0, width: 35.0, color: color),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Container(
              child: AutoSizeText(
                total,
                style: textStyle,
                maxLines: 1,
                minFontSize: 2.0,
              ),
              height: 20,
            ),
          ),
        ],
      ),
    );
  }
}
