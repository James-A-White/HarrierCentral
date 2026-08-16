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

  /// Icon marking the product this line represents. Run payments (and the
  /// "not paid" rows, where payment is null) show the run icon.
  IconData _productIcon(int? productType) {
    if (productType == productTypeMembership.value) {
      return Icons.card_membership;
    }
    if (productType == productTypeHaberdashery.value) {
      return Icons.checkroom;
    }
    return Icons.directions_run;
  }

  /// Bank transfer awaiting confirmation — shown as a pending clock badge on
  /// the payment icon. Text stays black (red is reserved for unpaid rows);
  /// the swipe/tap-to-confirm behaviour is unchanged.
  bool get _needsConfirm =>
      (((paymentReportItem.payment?.paymentType ?? paymentTypeUnknown.value) ==
              paymentBankTransfer.value) ||
          ((paymentReportItem.payment?.paymentType ??
                  paymentTypeUnknown.value) ==
              paymentBankTransferOtherAmount.value)) &&
      (paymentReportItem.payment?.confirmedBy == null);

  @override
  Widget build(BuildContext context) {
    final String amountPaid = IveCoreUtilities.getFormattedMoney(
      paymentReportItem.extensions.isHashCredit
          ? -(paymentReportItem.payment?.debitAmount ?? 0)
          : paymentReportItem.payment?.creditAmount ?? 0,
      digitsAfterDecimal,
      currencySymbol,
    );

    String? extrasPaid;
    if ((paymentReportItem.payment?.doPayForExtras ?? 0) != 0) {
      extrasPaid = IveCoreUtilities.getFormattedMoney(
        paymentReportItem.extensions.extrasPrice,
        digitsAfterDecimal,
        currencySymbol,
      );
    }

    return InkWell(
      onTap: () {
        onTap();
      },
      child: Row(
        //mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: MediaQuery.sizeOf(context).width,
            child: Row(
              children: <Widget>[
                const SizedBox(width: 10.0),
                // Product-type marker before the name: run fee / annual
                // subscription / haberdashery.
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    _productIcon(paymentReportItem.payment?.productType),
                    size: 22.0,
                    color: Colors.black54,
                  ),
                ),
                Expanded(
                  child: AutoSizeText(
                    paymentReportItem.extensions.paidByName,
                    maxLines: 3,
                    //'xxxx xxxx xxx xxx xxxx xxxx xxxx xxxx',
                    style: TextStyle(
                      fontFamily: (paymentReportItem.extensions.isMember != 0)
                          ? 'AvenirNextCondensedDemiBold'
                          : 'AvenirNextCondensedMedium',
                      color: Colors.black,
                      fontStyle: FontStyle.normal,
                      fontSize: 22.0,
                      height: 1.0,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amountPaid,
                      style: const TextStyle(
                        color: Colors.black,
                        fontFamily: 'AvenirNextCondensedDemiBold',
                        fontStyle: FontStyle.normal,
                        fontSize: 22.0,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    if (extrasPaid != null)
                      Text(
                        'includes $extrasPaid for ${paymentReportItem.extensions.extrasDescription}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: 'AvenirNextCondensedDemiBold',
                          fontStyle: FontStyle.normal,
                          fontSize: 16.0,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.right,
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: paymentReportItem.isLoading
                      ? Icon(delayIcon, color: hc_blue, size: 37.0)
                      : Stack(
                          clipBehavior: Clip.none,
                          children: <Widget>[
                            Image.asset(
                              'images/icons/payment_type_${paymentReportItem.payment?.paymentType ?? 0}.png',
                              height: 30.0,
                              width: 30.0,
                              color:
                                  (paymentReportItem.payment?.paymentType ??
                                          paymentTypeUnknown.value) <=
                                      paymentNotPaid.value
                                  ? hc_red
                                  : Colors.green[700],
                            ),
                            // Awaiting-confirmation badge: the card icon stays
                            // (it IS a card payment); the clock says "not
                            // verified yet" and disappears on confirmation.
                            if (_needsConfirm)
                              Positioned(
                                right: -4,
                                bottom: -4,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(1),
                                  child: Icon(
                                    Icons.schedule,
                                    size: 15,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ),
                          ],
                        ),
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

  final EnumPaymentType paymentRecordType;
  final Color color;
  final String currencySymbol;
  final int digitsAfterDecimal;
  final Function onTap;
  final double creditAmount;
  final int counter;

  @override
  Widget build(BuildContext context) {
    final String total = creditAmount == 0
        ? ''
        : IveCoreUtilities.getFormattedMoney(
            creditAmount,
            digitsAfterDecimal,
            currencySymbol,
          );

    return SizedBox(
      width: 40,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 0.0),
            child: Text(counter.toString(), style: ts_titleLargeCondensedBlack),
          ),
          IconButton(
            padding: const EdgeInsets.all(0),
            onPressed: () {
              onTap();
            },
            icon: Image.asset(
              'images/icons/payment_type_${paymentRecordType.value}.png',
              height: 35.0,
              width: 35.0,
              color: color,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: SizedBox(
              height: 20,
              child: AutoSizeText(
                total,
                style: ts_titleLargeCondensedBlack,
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
