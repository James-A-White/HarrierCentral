// Opens a chat and proves it opens AT THE BOTTOM — the newest message on
// screen, no scrolling needed (James, 2026-10-09: "Chats are still not
// opening at the bottom of the view"). The default ChatAnimatedList jumps to
// the end on its first frame, before the thread has loaded, so the chat
// opened at the top; ChatAnimatedListReversed fixes it, and this pins it.
//
// Run on a booted simulator that is already signed in:
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/chat_opens_at_bottom_test.dart -d <udid> \
//     --dart-define=HC_UI_TEST=true \
//     [--dart-define=HC_TEST_CHAT="Kennel Admins"]   # a thread longer than a screen
//     [--dart-define=HC_TEST_INVITE_CODE=ABCDEF]      # only when signed out
import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';
import 'package:integration_test/integration_test.dart';

import 'harness/hc_harness.dart';

const String kInviteCode = String.fromEnvironment('HC_TEST_INVITE_CODE');
const String kChat = String.fromEnvironment('HC_TEST_CHAT', defaultValue: 'Kennel Admins');

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a chat opens scrolled to its newest message', (WidgetTester tester) async {
    final Harness h = Harness(tester, binding);
    await h.launch();

    final DateTime bootEnd = DateTime.now().add(const Duration(minutes: 5));
    while (DateTime.now().isBefore(bootEnd)) {
      await tester.pump(const Duration(milliseconds: 300));
      if (find.byIcon(Icons.menu).evaluate().isNotEmpty) break;
      if (find.textContaining('Create your free account').evaluate().isNotEmpty) break;
      if (find.text('I have an invite code').evaluate().isNotEmpty) break;
      // 'Reload' is the "Device No Longer Registered" alert: the app then
      // re-registers itself from the reset code in the keychain.
      for (final String button in <String>['Continue', 'Close', 'OK', 'Skip', 'Disallow', 'Reload']) {
        if (find.text(button).evaluate().isNotEmpty) {
          await h.tapText(button);
          await h.settle(const Duration(seconds: 1));
          break;
        }
      }
    }
    await _signInIfGuest(h, tester);
    expect(find.byIcon(Icons.menu), findsWidgets, reason: 'main page never appeared');
    final DateTime ctrlEnd = DateTime.now().add(const Duration(seconds: 60));
    while (!Get.isRegistered<FutureRunListPageController>() && DateTime.now().isBefore(ctrlEnd)) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await h.settle(const Duration(seconds: 4));

    // Chats view → the named thread.
    await h.tap(find.byIcon(Icons.chat_bubble_outline), what: 'chat bubble');
    await h.settle(const Duration(seconds: 3));
    await h.screen('01 chats');
    final Finder row = find.text(kChat, skipOffstage: false);
    if (!await h.appears(row, timeout: const Duration(seconds: 10))) {
      await tester.scrollUntilVisible(row, 300, scrollable: find.byType(Scrollable).first);
    }
    await h.tap(row, what: 'chat row "$kChat"');

    // Wait for the thread to load: the list exists and has at least one bubble.
    final Finder list = find.byType(ChatAnimatedListReversed);
    await h.waitFor(list, what: 'chat list');
    final Finder scrollable = find.descendant(of: list, matching: find.byType(Scrollable));
    await h.waitFor(scrollable, what: 'chat scrollable');
    // Give the fetch time to land and the list to lay out — the bug was
    // precisely that the jump happened BEFORE this.
    await h.settle(const Duration(seconds: 6));
    await h.screen('02 chat open');

    final ScrollPosition pos = tester.state<ScrollableState>(scrollable.first).position;
    debugPrint('[HARNESS] chat scroll pixels=${pos.pixels} max=${pos.maxScrollExtent} '
        'axisDirection=${pos.axisDirection}');
    expect(pos.maxScrollExtent, greaterThan(200),
        reason: '"$kChat" must be longer than a screen for this test to mean anything');
    // A reversed list puts the newest message at offset 0; a plain list would
    // put it at maxScrollExtent. Either way "at the bottom" is the end the
    // newest message lives at.
    final bool reversed = pos.axisDirection == AxisDirection.up;
    final double distanceFromNewest = reversed ? pos.pixels : pos.maxScrollExtent - pos.pixels;
    expect(distanceFromNewest, lessThan(2),
        reason: 'the chat opened ${distanceFromNewest.toStringAsFixed(0)} px away from its newest message');
    expect(find.byType(Composer), findsOneWidget, reason: 'the composer is on screen');

    h.restoreErrorHandler();
    debugPrint('[HARNESS] ${h.ledger.report()}');
    expect(h.ledger.entries, isEmpty, reason: h.ledger.report());
  });
}

Future<void> _signInIfGuest(Harness h, WidgetTester t) async {
  if (find.byIcon(Icons.menu).evaluate().isNotEmpty) return;
  if (kInviteCode.isEmpty) {
    throw TestFailure('The simulator is signed out; pass --dart-define=HC_TEST_INVITE_CODE');
  }
  final Finder guestButton = find.textContaining('Create your free account');
  if (guestButton.evaluate().isNotEmpty) {
    await h.tap(guestButton, what: 'guest sign-in button');
  }
  for (int i = 0; i < 12; i++) {
    if (find.text('I have an invite code').evaluate().isNotEmpty) break;
    if (find.text('Take me to the invite code screen').evaluate().isNotEmpty) {
      await h.tapText('Yes');
      break;
    }
    final bool permissionPage = find.text('Allow').evaluate().isNotEmpty;
    if (find.text('Disallow').evaluate().isNotEmpty) {
      await h.tapText('Disallow');
    } else if (find.text('Skip').evaluate().isNotEmpty) {
      await h.tapText('Skip');
    } else if (!permissionPage && find.text('Next').evaluate().isNotEmpty) {
      await h.tapText('Next');
    } else if (!permissionPage && find.text('OK').evaluate().isNotEmpty) {
      await h.tapText('OK');
    }
    await h.settle(const Duration(seconds: 1));
  }
  if (find.text('I have an invite code').evaluate().isNotEmpty) {
    await h.tapText('I have an invite code');
  }
  await h.waitFor(find.text('Please enter your invite code'));
  await h.enterText(find.byType(TextFormField), kInviteCode);
  await h.tapText('Get Started!');
  final DateTime end = DateTime.now().add(const Duration(minutes: 3));
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 200));
    if (find.byIcon(Icons.menu).evaluate().isNotEmpty) return;
    if (find.text('Success!').evaluate().isNotEmpty && find.text('OK').evaluate().isNotEmpty) {
      await h.tapText('OK');
    }
    for (final String button in <String>['Continue', 'Close', 'Skip', 'Disallow']) {
      if (find.text(button).evaluate().isNotEmpty) {
        await h.tapText(button);
        break;
      }
    }
  }
}
