import 'package:flutter/material.dart';
import 'package:harrier_central/widgets/qr_popup.dart';
import 'package:intl/intl.dart';

import 'package:harrier_central/pages/run_admin/run_admin_main.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/styles.dart';



class BankTransferQr
{



    static void showBankTransferSnackbar(RunAdminAggregate eventAggregate, List<dynamic> results, int paymentType, BuildContext context, String packMemberNameForDisplay, int isMember, num otherAmount) {
    String paymentReference = '';
    if ((results != null) && (results.isNotEmpty) && (results[0]['paymentReference'] != null)) {
      //paymentReference = ', HC Payment Ref: ${results[0]['paymentReference']}';
      paymentReference = '${results[0]['paymentReference']}';
    }

    if ((paymentType != paymentBankTransferOtherAmount.value) && (paymentType != paymentCashOtherAmount.value))
    {
      otherAmount = -1;
    }
    
    if ((paymentType == paymentBankTransfer.value) || (paymentType == paymentBankTransferOtherAmount.value)) {
      // String paidFor = 'Run fee, ${eventAggregate.event.eventStartDatetime.toString().substring(0, 10)}, ${eventAggregate.event.eventName}';
      // if (paymentType == paymentBankTransferOtherAmount.value) {
      //   paidFor += ' + credit';
      // }
      Scaffold.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 10),
          content: Container(
            height: 50,
            child: RaisedButton(
              color: Colors.red,
              child: Text('Show Payment QR code', style: buttonLabelStyleMedium),
              textColor: Colors.white,
              onPressed: () {
                Scaffold.of(context).hideCurrentSnackBar();
                final String remittanceInfo = paymentReference + '-$packMemberNameForDisplay';
                BankTransferQr.showBankTransferQrCode(context,eventAggregate, isMember != 0, remitString: remittanceInfo, remitAmount: otherAmount);
              },
            ),
          )));
    }
  }

  static void showBankTransferQrCode(BuildContext context, RunAdminAggregate eventAggregate, bool member, {String remitString, num remitAmount}) {
    num amount = eventAggregate.extensions.memberPrice;

    String runId = DateFormat('yy-MM-dd').format(eventAggregate.event.eventStartDatetime);

    if (eventAggregate.event.isCountedRun != 0)
    {
      runId = eventAggregate.event.eventNumber.toString();
    }

    String remittanceInfo = '${eventAggregate.kennel.kennelShortName}:R-$runId-';
    String beneficiaryInfo = '${eventAggregate.kennel.kennelShortName}:R-$runId-';

    if (remitString != null)
    {
      remittanceInfo += remitString;
      beneficiaryInfo += remitString;
    } else {
      remittanceInfo += eventAggregate.event.eventName;
      beneficiaryInfo += eventAggregate.event.eventName;
    }

    // if (remitString != null) {
    //   remittanceInfo = remitString;
    // }

    if (remittanceInfo.length > 139) {
      remittanceInfo = remittanceInfo.substring(0, 139);
    }

    if (beneficiaryInfo.length > 69) {
      beneficiaryInfo = beneficiaryInfo.substring(0, 69);
    }

    if ((remitAmount != null) && (remitAmount != -1)) {
      amount = remitAmount;
    } else {
      if (!member) {
        amount = eventAggregate.extensions.nonMemberPrice;
      }
    }

    print('Remittance info:$remittanceInfo');

    final QrPopup pp = QrPopup(
      dialogTitle: 'Scan to pay by bank transfer',
      qrText: '''BCD
001
1
SCT
${eventAggregate.kennel.bankBic}
${eventAggregate.kennel.bankBeneficiary}
${eventAggregate.kennel.bankAccountNumber}
${eventAggregate.extensions.curCode}$amount
SCVE

$remittanceInfo
$beneficiaryInfo
''',
    );

    showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return pp;
        });
  }
}