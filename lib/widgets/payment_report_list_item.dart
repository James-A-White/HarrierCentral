import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/data_models/payment_report_model.dart';
import 'package:harrier_central/util/utilities.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:harrier_central/pages/kennel_admin/user_secret_qr_page.dart';

class PaymentReportListItem extends StatelessWidget {
  final PaymentReportModel paymentReportItem;
  final String currencySymbol;
  final int digitsAfterDecimal;
  final Function onTap;

  const PaymentReportListItem(
      {@required this.paymentReportItem,
      @required this.currencySymbol,
      @required this.digitsAfterDecimal,
      @required this.onTap});

  @override
  Widget build(BuildContext context) {
    String amountPaid = Utilities.getFormattedMoney(
        paymentReportItem.creditAmount, digitsAfterDecimal, currencySymbol);

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
                  right: 10.0,
                  top: 7.0,
                  child: Image.asset(
                      'images/icons/payment_type_${paymentReportItem.paymentType.value}.png',
                      height: 30.0,
                      width: 30.0,
                      color: paymentReportItem.paymentType.value <=
                              paymentNotPaid.value
                          ? Colors.red
                          : Colors.green[700]),
                ),
                Positioned(
                  left: 10.0,
                  top: 7.0,
                  child: Text(
                    '${paymentReportItem.paidBy}',
                    style: const TextStyle(
                        fontFamily: 'AvenirNextCondensedDemiBold',
                        fontStyle: FontStyle.normal,
                        fontSize: 22.0,
                        height: 1.0),
                    textAlign: TextAlign.center,
                  ),
                ),
                Positioned(
                  right: 50.0,
                  top: 7.0,
                  child: Text(
                    '$amountPaid',
                    style: const TextStyle(
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

class TotalsCell extends StatelessWidget {
  final List<PaymentReportModel> data;
  final EnumPaymentType paymentRecordType;
  final Color color;
  final String currencySymbol;
  final int digitsAfterDecimal;
  final Function onTap;

  const TotalsCell(
    List<PaymentReportModel> this.data, {
    @required this.color,
    @required this.paymentRecordType,
    @required this.currencySymbol,
    @required this.digitsAfterDecimal,
    @required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    PaymentReportModel item = data.firstWhere(
        (PaymentReportModel report) =>
            report.paymentType.value == paymentRecordType.value + 100,
        orElse: () => null);

    String total = (item?.creditAmount ?? 0) <= 0
        ? ''
        : Utilities.getFormattedMoney(
            item?.creditAmount ?? 0, digitsAfterDecimal, currencySymbol);

    const textStyle = const TextStyle(
        color: Colors.black,
        fontSize: 24.0,
        fontFamily: 'AvenirNextCondensedDemiBold');
    return Container(
      width: 40,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 0.0),
            child: Text(
              item?.paymentReference ?? '0',
              style: textStyle,
            ),
          ),
          IconButton(
            padding: EdgeInsets.all(0),
            onPressed: onTap,
            icon: Image.asset(
                'images/icons/payment_type_${paymentRecordType.value}.png',
                height: 35.0,
                width: 35.0,
                color: color),
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
