import 'package:harrier_central/imports.dart';

class PaymentReportListItem extends StatelessWidget {
  const PaymentReportListItem({
    super.key,
    required this.paymentReportItem,
    required this.currencySymbol,
    required this.digitsAfterDecimal,
    required this.onTap,
  });

  final PaymentAggregate paymentReportItem;
  final String currencySymbol;
  final int digitsAfterDecimal;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    final String amountPaid = IveCoreUtilities.getFormattedMoney(
        paymentReportItem.extensions.isHashCredit ? -(paymentReportItem.payment.debitAmount) : paymentReportItem.payment.creditAmount, digitsAfterDecimal, currencySymbol);

    return InkWell(
      onTap: onTap(),
      child: Row(
        //mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Row(
              children: <Widget>[
                const SizedBox(width: 10.0),
                Expanded(
                  child: AutoSizeText(
                    paymentReportItem.extensions.paidByName,
                    maxLines: 3,
                    //'xxxx xxxx xxx xxx xxxx xxxx xxxx xxxx',
                    style: TextStyle(
                        fontFamily: (paymentReportItem.extensions.isMember != 0) ? 'AvenirNextCondensedDemiBold' : 'AvenirNextCondensedMedium',
                        fontStyle: FontStyle.normal,
                        fontSize: 22.0,
                        height: 1.0),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  amountPaid,
                  style: TextStyle(
                      color: (((paymentReportItem.payment.paymentType == paymentBankTransfer.value) || (paymentReportItem.payment.paymentType == paymentBankTransferOtherAmount.value)) &&
                              (paymentReportItem.payment.confirmedBy == null))
                          ? Colors.red
                          : Colors.black,
                      fontFamily: 'AvenirNextCondensedDemiBold',
                      fontStyle: FontStyle.normal,
                      fontSize: 22.0,
                      height: 1.0),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: paymentReportItem.isLoading
                      ? Icon(delayIcon, color: Colors.blue[800], size: 37.0)
                      : Image.asset('images/icons/payment_type_${paymentReportItem.payment.paymentType}.png',
                          height: 30.0, width: 30.0, color: (paymentReportItem.payment.paymentType) <= paymentNotPaid.value ? Colors.red : Colors.green[700]),
                ),
                const SizedBox(width: 10),
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
    super.key,
    required this.creditAmount,
    required this.counter,
    required this.color,
    required this.paymentRecordType,
    required this.currencySymbol,
    required this.digitsAfterDecimal,
    required this.onTap,
  });

  final EnumPaymentType<int> paymentRecordType;
  final Color color;
  final String currencySymbol;
  final int digitsAfterDecimal;
  final Function onTap;
  final double creditAmount;
  final int counter;

  @override
  Widget build(BuildContext context) {
    final String total = creditAmount == 0 ? '' : IveCoreUtilities.getFormattedMoney(creditAmount, digitsAfterDecimal, currencySymbol);

    const TextStyle textStyle = TextStyle(color: Colors.black, fontSize: 24.0, fontFamily: 'AvenirNextCondensedDemiBold');
    return SizedBox(
      width: 40,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 0.0),
            child: Text(
              counter.toString(),
              style: textStyle,
            ),
          ),
          IconButton(
            padding: const EdgeInsets.all(0),
            onPressed: onTap(),
            icon: Image.asset('images/icons/payment_type_${paymentRecordType.value}.png', height: 35.0, width: 35.0, color: color),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: SizedBox(
              height: 20,
              child: AutoSizeText(
                total,
                style: textStyle,
                maxLines: 1,
                minFontSize: 2.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
