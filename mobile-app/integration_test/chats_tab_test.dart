// Reproduces "the Chats view comes back after Kennels → Runs" (James,
// 2026-09-30). Drives the real app on a simulator: chat bubble → Chats
// view, Kennels tab, Runs tab, and asserts the list is NOT in Chats mode.
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/chats_tab_test.dart -d <udid> \
//     --dart-define=HC_UI_TEST=true
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';
import 'package:integration_test/integration_test.dart';

import 'harness/hc_harness.dart';

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Chats view closes when the tab changes', (
    WidgetTester tester,
  ) async {
    final Harness h = Harness(tester, binding);
    await h.launch();
    // Boot on a stale simulator can take minutes (a DB_VERSION bump reloads
    // everything) and may put a "what's new" or a boot alert in the way:
    // press through them until the main page's menu icon is there.
    final DateTime end = DateTime.now().add(const Duration(minutes: 5));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 300));
      if (find.byIcon(Icons.menu).evaluate().isNotEmpty) break;
      for (final String button in <String>['Continue', 'Close', 'OK', 'Skip', 'Disallow']) {
        if (find.text(button).evaluate().isNotEmpty) {
          debugPrint('[HARNESS] boot: pressing $button');
          await h.tapText(button);
          await h.settle(const Duration(seconds: 1));
          break;
        }
      }
    }
    expect(find.byIcon(Icons.menu), findsWidgets, reason: 'main page never appeared');
    // The list controller is put by the Runs page a moment after the menu.
    final DateTime ctrlEnd = DateTime.now().add(const Duration(seconds: 60));
    while (!Get.isRegistered<FutureRunListPageController>() &&
        DateTime.now().isBefore(ctrlEnd)) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await h.settle(const Duration(seconds: 4));

    final FutureRunListPageController list =
        Get.find<FutureRunListPageController>();
    // Who changes the mode? Print a stack trace on every change.
    ever<RunsToDisplay>(list.runsToDisplay, (RunsToDisplay v) {
      debugPrint('[MODE] -> $v\n${StackTrace.current}');
    });
    Finder tab(String label) => find.descendant(
      of: find.byType(CurvedNavigationBar),
      matching: find.text(label),
    );

    // Bubble → Chats view.
    await h.tap(find.byIcon(Icons.chat_bubble_outline), what: 'chat bubble');
    await h.settle(const Duration(seconds: 3));
    await h.shot('chats_1_open');
    expect(list.isChatsMode, isTrue, reason: 'bubble should open Chats');

    // Kennels, then back to Runs.
    await h.tap(tab('Kennels'), what: 'Kennels tab');
    await h.settle(const Duration(seconds: 2));
    await h.shot('chats_2_kennels');
    await h.tap(tab('Runs'), what: 'Runs tab');
    await h.settle(const Duration(seconds: 3));
    await h.shot('chats_3_back_on_runs');
    final FutureRunListPageController live =
        Get.find<FutureRunListPageController>();
    debugPrint(
      '[HARNESS] list=${identityHashCode(list)} live=${identityHashCode(live)} '
      'list.mode=${list.runsToDisplay.value} live.mode=${live.runsToDisplay.value} '
      'chatsHeaderOnScreen=${find.text('Chats').evaluate().isNotEmpty} '
      'requestsOnScreen=${find.text('Message requests').evaluate().isNotEmpty}',
    );
    expect(
      live.isChatsMode,
      isFalse,
      reason: 'Kennels → Runs must show the runs list, not Chats',
    );

    // Re-tap Runs while on Chats also closes it.
    await h.tap(find.byIcon(Icons.chat_bubble_outline), what: 'chat bubble');
    await h.settle(const Duration(seconds: 3));
    expect(list.isChatsMode, isTrue);
    await h.tap(tab('Runs'), what: 'Runs tab again');
    await h.settle(const Duration(seconds: 3));
    await h.shot('chats_4_retap');
    expect(list.isChatsMode, isFalse, reason: 'Runs re-tap must close Chats');
  });
}
