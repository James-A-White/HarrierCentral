// Pipeline check: the app boots on the device, a screenshot lands on disk.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'harness/hc_harness.dart';

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots', (WidgetTester tester) async {
    final Harness h = Harness(tester, binding);
    await h.launch();
    await h.settle(const Duration(seconds: 8));
    await h.screen('boot');
    final bool guest = await h.appears(
      find.textContaining('Create your free account'),
      timeout: const Duration(seconds: 2),
    );
    debugPrint('[HARNESS] guest page: $guest');
    expect(find.byType(MaterialApp), findsWidgets);
    debugPrint('[HARNESS] ${h.ledger.report()}');
  });
}
