import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class BankTransferQr {
  // the variable below is there to suppress a warning about defining classes with only static members
  int? unusedVariableToSuppressWarning;

  static void showBankTransferSnackbar(
    RunAdminAggregate eventAggregate,
    List<dynamic> results,
    int paymentType,
    BuildContext context,
    String packMemberNameForDisplay,
    int isMember,
    double? otherAmount,
  ) {
    if (eventAggregate.kennel.bankBic != null) {
      String paymentReference = '';
      if ((results.isNotEmpty) && (results[0]['paymentReference'] != null)) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: hc_blue,
            duration: const Duration(seconds: 10),
            content: SizedBox(
              height: 80,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: hc_red),
                child: Text(
                  'Show Payment QR code for\r\n$packMemberNameForDisplay',
                  style: ts_button,
                  textAlign: TextAlign.center,
                ),
                onPressed: () async {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  final String remittanceInfo =
                      '$paymentReference-$packMemberNameForDisplay';
                  await BankTransferQr.showBankTransferQrCode(
                    context,
                    eventAggregate,
                    isMember != 0,
                    remitString: remittanceInfo,
                    remitAmount: otherAmount,
                    packMemberNameForDisplay: packMemberNameForDisplay,
                  );
                },
              ),
            ),
          ),
        );
      }
    }
  }

  static Future<void> showBankTransferQrCode(
    BuildContext context,
    RunAdminAggregate eventAggregate,
    bool member, {
    String? remitString,
    double? remitAmount,
    String? packMemberNameForDisplay,
  }) async {
    if (eventAggregate.kennel.bankBic != null) {
      num amount = eventAggregate.extensions.memberPrice;

      String? runId;

      runId = DateFormat(
        'yy-MM-dd',
      ).format(eventAggregate.event.eventStartDatetime);

      if (eventAggregate.event.isCountedRun != 0) {
        runId = eventAggregate.event.eventNumber.toString();
      }

      //runId ??= Random().nextInt(999999).toString();

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

      //print('Remittance info:$remittanceInfo');
      final String qrPayload =
          '''BCD
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
        key: const Key('6677010439'),
        dialogTitle:
            '${(packMemberNameForDisplay != null) ? '$packMemberNameForDisplay\r\n' : ''}Scan to pay by bank transfer',
        qrText: qrPayload,
      );

      await showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return pp;
        },
      );
    }
  }
}
