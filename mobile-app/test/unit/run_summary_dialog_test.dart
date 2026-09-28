import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:harrier_central/services/location_service/run_summary.dart';
import 'package:harrier_central/widgets/run_summary_dialog.dart';

/// The run card leaves the drink stops out of running time and pace
/// (James, 2026-09-28).
void main() {
  Future<void> open(WidgetTester tester, Duration drinks) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GetMaterialApp(home: Builder(builder: (context) {
      return Scaffold(body: Center(child: ElevatedButton(
        onPressed: () => showRunSummaryDialog(context, FixedRunSummary(
          distanceMeters: 8500,
          elapsed: const Duration(hours: 1, minutes: 49, seconds: 58),
          marks: RunSummary(checksReached: 17, checksOnTrail: 17, drinkStopsReached: 2, drinkStopTime: drinks),
          summaryImperial: false,
        )),
        child: const Text('open'),
      )));
    })));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('drink stops are taken out of running time and pace', (tester) async {
    await open(tester, const Duration(minutes: 49));
    expect(find.text('Running time'), findsOneWidget);
    expect(find.text('1:00:58'), findsOneWidget);
    expect(find.text('Running pace'), findsOneWidget);
    expect(find.text('7:10 /km'), findsOneWidget);
  });

  testWidgets('no drink stop: no running time line, pace from the whole run', (tester) async {
    await open(tester, Duration.zero);
    expect(find.text('Running time'), findsNothing);
    expect(find.text('12:56 /km'), findsOneWidget);
  });
}
