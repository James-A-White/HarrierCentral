import 'package:flutter/material.dart';

import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/data_models/payment_report_model.dart';
import 'package:harrier_central/util/utilities.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:harrier_central/pages/kennel_admin/user_secret_qr_page.dart';

class PaymentReportListItem extends StatelessWidget {
  final PaymentReportModel paymentReportItem;
  final String currencySymbol;
  final int digitsAfterDecimal;

  const PaymentReportListItem(
      {@required this.paymentReportItem,
      @required this.currencySymbol,
      @required this.digitsAfterDecimal});

  @override
  Widget build(BuildContext context) {
    String amountPaid = Utilities.getFormattedMoney(
        paymentReportItem.creditAmount, digitsAfterDecimal, currencySymbol);

    return InkWell(
      onTap: () {
        // Navigator.push<dynamic>(
        //           context,
        //           MaterialPageRoute<dynamic>(
        //             builder: (context) => UserSecretQrPage(
        //                   paymentReportItemModel: paymentReportItem
        //                 ),),);
      },
      child: 
      
      //SizedBox.expand(child:

      
      Row(
        //mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width,
            child:
          Stack(
            //fit: StackFit.expand,
            children: <Widget>[
              Positioned(
                right: 10.0,
                top:7.0,
                child: Image.asset(
                    'images/icons/payment_type_${paymentReportItem.paymentType.value}.png',
                    height: 30.0,
                    width: 30.0,
                    color: paymentReportItem.paymentType == paymentNotPaid
                        ? Colors.red
                        : Colors.green[700]),
              ),
              Positioned(
                left:10.0,
                top:7.0,
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
                right:50.0,
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
