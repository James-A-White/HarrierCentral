import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:harrier_central/pages/run_admin/other_payment_popup.dart';

/// Payment options closed as soon as the keyboard came up (2026-09-27): the
/// dialog rebuilds on a viewInsets change, and every build used to reset the
/// form — the "Top up credit" box unticked and the amount vanished.
void main() {
  testWidgets('opening the keyboard keeps the top-up box and amount', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // The test font is wider than the real one, so some rows overflow;
    // layout is not what this test is about.
    final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails d) {
      if (d.exceptionAsString().contains('overflowed')) return;
      previous?.call(d);
    };
    addTearDown(() => FlutterError.onError = previous);

    final ValueNotifier<double> keyboard = ValueNotifier<double>(0);
    await tester.pumpWidget(
      GetMaterialApp(
        home: ValueListenableBuilder<double>(
          valueListenable: keyboard,
          builder: (BuildContext context, double inset, _) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(viewInsets: EdgeInsets.only(bottom: inset)),
            child: const Material(
              child: OtherPaymentPopup(7.0, 2, '£', true, true),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final OtherPaymentPopupController c = tester
        .state<GetBuilderState<OtherPaymentPopupController>>(
          find.byType(GetBuilder<OtherPaymentPopupController>),
        )
        .controller!;
    c.topUpCreditEnabled.value = true;
    c.topUpTextController.text = '20';
    await tester.pump();
    expect(c.totalDue.value, 27.0);

    keyboard.value = 320; // the keyboard opens → the dialog rebuilds
    await tester.pump();

    final OtherPaymentPopupController after = tester
        .state<GetBuilderState<OtherPaymentPopupController>>(
          find.byType(GetBuilder<OtherPaymentPopupController>),
        )
        .controller!;
    expect(identical(after, c), isTrue, reason: 'one controller per dialog');
    expect(after.topUpCreditEnabled.value, isTrue);
    expect(after.topUpTextController.text, '20');
    expect(after.totalDue.value, 27.0);
  });
}
