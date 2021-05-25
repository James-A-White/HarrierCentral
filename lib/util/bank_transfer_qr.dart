import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class BankTransferQr {
  static void showBankTransferSnackbar(
      RunDetailAggregate eventAggregate,
      List<dynamic> results,
      int paymentType,
      BuildContext context,
      String packMemberNameForDisplay,
      int isMember,
      num otherAmount) {
    if (eventAggregate.kennel.bankBic != null) {
      String paymentReference = '';
      if ((results != null) &&
          (results.isNotEmpty) &&
          (results[0]['paymentReference'] != null)) {
        //paymentReference = ', HC Payment Ref: ${results[0]['paymentReference']}';
        paymentReference = '${results[0]['paymentReference']}';
      }

      if ((paymentType != paymentBankTransferOtherAmount.value) &&
          (paymentType != paymentCashOtherAmount.value)) {
        otherAmount = -1;
      }

      if ((paymentType == paymentBankTransfer.value) ||
          (paymentType == paymentBankTransferOtherAmount.value)) {
        // String paidFor = 'Run fee, ${eventAggregate.event.eventStartDatetime.toString().substring(0, 10)}, ${eventAggregate.event.eventName}';
        // if (paymentType == paymentBankTransferOtherAmount.value) {
        //   paidFor += ' + credit';
        // }
        Scaffold.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 10),
            content: Container(
              height: 80,
              child: RaisedButton(
                color: Colors.red,
                child: Text(
                  'Show Payment QR code for\r\n$packMemberNameForDisplay',
                  style: buttonLabelStyleMedium,
                  textAlign: TextAlign.center,
                ),
                textColor: Colors.white,
                onPressed: () {
                  Scaffold.of(context).hideCurrentSnackBar();
                  final String remittanceInfo =
                      paymentReference + '-$packMemberNameForDisplay';
                  BankTransferQr.showBankTransferQrCode(
                      context, eventAggregate, isMember != 0,
                      remitString: remittanceInfo,
                      remitAmount: otherAmount,
                      packMemberNameForDisplay: packMemberNameForDisplay);
                },
              ),
            )));
      }
    }
  }

  static void showBankTransferQrCode(
      BuildContext context, RunDetailAggregate eventAggregate, bool member,
      {String remitString, num remitAmount, String packMemberNameForDisplay}) {
    if (eventAggregate.kennel.bankBic != null) {
      num amount = eventAggregate.extensions.memberPrice;

      String runId = DateFormat('yy-MM-dd')
          .format(eventAggregate.event.eventStartDatetime);

      if (eventAggregate.event.isCountedRun != 0) {
        runId = eventAggregate.event.eventNumber.toString();
      }

      String remittanceInfo =
          '${eventAggregate.kennel.kennelShortName}:R-$runId-';
      String beneficiaryInfo =
          '${eventAggregate.kennel.kennelShortName}:R-$runId-';

      if (remitString != null) {
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
      final String qrPayload = '''BCD
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
''';

      final QrPopup pp = QrPopup(
        key: UniqueKey(),
        dialogTitle:
            '${(packMemberNameForDisplay != null) ? packMemberNameForDisplay + '\r\n' : ''}Scan to pay by bank transfer',
        qrText: qrPayload,
      );

      showDialog<void>(
          context: context,
          barrierDismissible: false, // user must tap button!
          builder: (BuildContext context) {
            return pp;
          });
    }
  }
}
