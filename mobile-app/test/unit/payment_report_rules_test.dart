import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// The payment report's footer maths and chip-filter arithmetic. Both lived
/// inside a 1900-line State until 2026-09-23.
void main() {
  group('PaymentFooterTotals.fromProductRows', () {
    Map<String, dynamic> row(
      int product,
      double gross,
      double pending,
      int pendingCount,
      int txns, {
      double extras = 0,
    }) => <String, dynamic>{
      'productType': product,
      'gross': gross,
      'pendingAmount': pending,
      'pendingCount': pendingCount,
      'txnCount': txns,
      'extrasPaid': extras,
    };

    test('splits run, membership and haberdashery; pending is subtracted', () {
      final f = PaymentFooterTotals.fromProductRows([
        row(productTypeEvent.value, 100, 20, 2, 10, extras: 3),
        row(productTypeMembership.value, 50, 10, 1, 2),
        row(productTypeHaberdashery.value, 30, 0, 0, 3),
      ]);
      expect(f.runGross, 100);
      expect(f.runPending, 20);
      expect(f.memberGross, 50);
      expect(f.habGross, 30);
      expect(f.extrasPaid, 3);
      expect(f.transactionCount, 15);
      expect(f.pendingCount, 3);
      expect(f.pendingTotal, 30);
      // Category lines plus pending always sum to the recorded gross.
      expect(f.totalCollected, 100 + 50 + 30 - 30);
    });

    test('a null productType counts as a run payment', () {
      final f = PaymentFooterTotals.fromProductRows([
        <String, dynamic>{'productType': null, 'gross': 7, 'txnCount': 1},
      ]);
      expect(f.runGross, 7);
      expect(f.transactionCount, 1);
    });

    test('no rows is all zeros', () {
      const f = PaymentFooterTotals();
      expect(f.totalCollected, 0);
      expect(PaymentFooterTotals.fromProductRows(const []).transactionCount, 0);
    });
  });

  group('PaymentReportController.nextFilter', () {
    const all = PaymentReportController.ALL_PAYMENTS_FILTER_VALUE;
    test('from "all", a chip selects just that type', () {
      expect(PaymentReportController.nextFilter(all, 2), 2);
    });
    test('further chips toggle in and out', () {
      expect(PaymentReportController.nextFilter(2, 16), 18);
      expect(PaymentReportController.nextFilter(18, 2), 16);
    });
    test('clearing the last chip returns to "all"', () {
      expect(PaymentReportController.nextFilter(16, 16), all);
    });
  });
}
