import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// SumUp Payment Switch hand-off (E8.F7.S1): the request each platform needs,
/// reading SumUp's answer, and the ids that make a repeated answer harmless.
void main() {
  const String marker = '0f8e2c4a-1b2d-4c3e-9f00-1234567890ab';

  Uri req({required bool android, double amount = 5, int digits = 2}) =>
      CardPaymentHandoff.buildRequest(
        affiliateKey: 'KEY',
        amount: amount,
        digitsAfterDecimal: digits,
        currency: 'gbp',
        title: 'BMPH3 · run 2064 · Opee',
        foreignTxId: marker,
        android: android,
      );

  group('request', () {
    test('iOS: amount, both callbacks, no app id', () {
      final Uri u = req(android: false);
      expect(u.scheme, 'sumupmerchant');
      expect(u.host, 'pay');
      expect(u.path, '/1.0');
      final Map<String, String> q = u.queryParameters;
      expect(q['amount'], '5.00');
      expect(q['total'], isNull);
      expect(q['currency'], 'GBP');
      expect(q['affiliate-key'], 'KEY');
      expect(q['foreign-tx-id'], marker);
      expect(q['callbacksuccess'], 'harriercentral://sumup-result');
      expect(q['callbackfail'], 'harriercentral://sumup-result');
      expect(q['app-id'], isNull);
      expect(q['title'], 'BMPH3 · run 2064 · Opee');
    });

    test('Android: total (amount is deprecated), app id, one callback', () {
      final Map<String, String> q = req(android: true).queryParameters;
      expect(q['total'], '5.00');
      expect(q['amount'], isNull);
      expect(q['app-id'], 'com.harriercentral.app');
      expect(q['callback'], 'harriercentral://sumup-result');
      expect(q['callbacksuccess'], isNull);
    });

    test('amount uses a dot and the currency\'s decimals', () {
      expect(req(android: false, amount: 1500, digits: 0)
          .queryParameters['amount'], '1500');
      expect(req(android: false, amount: 4.5)
          .queryParameters['amount'], '4.50');
    });
  });

  group('answer', () {
    test('success carries the transaction code and our id', () {
      final SumUpResult? r = CardPaymentHandoff.parseCallback(Uri.parse(
        'harriercentral://sumup-result?smp-status=success'
        '&smp-tx-code=TEENSK4W2K&foreign-tx-id=${marker.toUpperCase()}',
      ));
      expect(r, isNotNull);
      expect(r!.success, isTrue);
      expect(r.transactionCode, 'TEENSK4W2K');
      expect(r.foreignTxId, marker, reason: 'ids are compared lowercase');
    });

    test('failure and invalidstate are not success; Android cause kept', () {
      final SumUpResult r = CardPaymentHandoff.parseCallback(Uri.parse(
        'harriercentral://sumup-result?smp-status=failed'
        '&smp-failure-cause=transaction-failed&foreign-tx-id=$marker',
      ))!;
      expect(r.success, isFalse);
      expect(r.message, 'transaction-failed');
      expect(CardPaymentHandoff.parseCallback(Uri.parse(
        'harriercentral://sumup-result?smp-status=invalidstate',
      ))!.success, isFalse);
    });

    test('only harriercentral://sumup-result is an answer', () {
      expect(CardPaymentHandoff.parseCallback(
          Uri.parse('harriercentral://import?file=x.gpx')), isNull);
      expect(CardPaymentHandoff.parseCallback(
          Uri.parse('https://www.hashruns.org/bmph3/2064')), isNull);
    });
  });

  group('ids and reference', () {
    test('paid and cancel ids are stable, distinct, and not the marker', () {
      final String paid = CardPaymentHandoff.paidIdFor(marker);
      final String cancel = CardPaymentHandoff.cancelIdFor(marker);
      expect(paid, CardPaymentHandoff.paidIdFor(marker));
      expect(cancel, CardPaymentHandoff.cancelIdFor(marker));
      expect(paid, isNot(cancel));
      expect(paid, isNot(marker));
      expect(paid, paid.toLowerCase());
    });

    test('reference is SU:<code>, capped at the column width', () {
      expect(CardPaymentHandoff.referenceFor('TEENSK4W2K'), 'SU:TEENSK4W2K');
      expect(CardPaymentHandoff.referenceFor(''), isNull);
      expect(CardPaymentHandoff.referenceFor(null), isNull);
      expect(CardPaymentHandoff.referenceFor('X' * 80)!.length, 50);
    });
  });
}
