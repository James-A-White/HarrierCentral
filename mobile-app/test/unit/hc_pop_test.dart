// Get.back() does not pop while a GetX snackbar is open (GetX 4.7.3's
// compatibility shim closes the snackbar and returns). hcPop() pops
// regardless. This pins the behaviour that hung Add Down Down on 1397.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:harrier_central/util/hc_nav.dart';

void main() {
  Widget app() => GetMaterialApp(
    home: Builder(
      builder: (BuildContext context) => TextButton(
        onPressed: () =>
            Get.to<void>(() => const Scaffold(body: Text('second'))),
        child: const Text('go'),
      ),
    ),
  );

  Future<void> openSecondPageWithToast(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('second'), findsOneWidget);
    Get.rawSnackbar(message: 'saved', duration: const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 600));
    expect(Get.isSnackbarOpen, isTrue);
  }

  Future<void> letTheToastExpire(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  testWidgets('Get.back() with a snackbar open only closes the snackbar', (
    WidgetTester tester,
  ) async {
    await openSecondPageWithToast(tester);
    Get.back<void>();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(Get.currentRoute, isNot('/'), reason: 'the page was not popped');
    expect(find.text('second'), findsOneWidget);
    await letTheToastExpire(tester);
  });

  testWidgets('hcPop() pops even with a snackbar open', (
    WidgetTester tester,
  ) async {
    await openSecondPageWithToast(tester);
    hcPop<void>();
    await tester.pump();
    expect(Get.currentRoute, '/', reason: 'popped at once');
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('second'), findsNothing);
    expect(find.text('go'), findsOneWidget);
    await letTheToastExpire(tester);
  });
}
