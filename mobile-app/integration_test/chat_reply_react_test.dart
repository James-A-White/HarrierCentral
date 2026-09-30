// Replies and emoji reactions in a chat (E9.F1.S21 / S22, 2026-09-30).
// Drives the real app on a simulator against the production server as the
// test account "Google Test", in a direct-message thread seeded with "Test
// Add Kennel Member" (both test accounts, neither with a push device, so
// nobody real is disturbed). The thread holds one seeded message.
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/chat_reply_react_test.dart -d <udid> \
//     --dart-define=HC_UI_TEST=true \
//     [--dart-define=HC_TEST_INVITE_CODE=ABCDEF]   # only when signed out
//
// Steps: open Chats → the DM → long-press the seeded message → Reply → send
// "Replying from the simulator" → the bubble shows the quote strip; long-
// press the seeded message → 🍺 → a "🍺 1" chip appears, ringed as mine;
// tap the chip → it disappears. The server side is checked by SQL after.
import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';
import 'package:integration_test/integration_test.dart';

import 'harness/hc_harness.dart';

const String kInviteCode = String.fromEnvironment('HC_TEST_INVITE_CODE');
const String kSeeded = 'Seeded message to reply to';
const String kReplyText = 'Replying from the simulator';
const String kOther = 'Test Add Kennel Member';

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reply with a quote, then react with a beer', (
    WidgetTester tester,
  ) async {
    final Harness h = Harness(tester, binding);
    await h.launch();

    // Boot: press through alerts until the main page's menu icon, the
    // guest landing, or the invite-code page.
    final DateTime bootEnd = DateTime.now().add(const Duration(minutes: 5));
    while (DateTime.now().isBefore(bootEnd)) {
      await tester.pump(const Duration(milliseconds: 300));
      if (find.byIcon(Icons.menu).evaluate().isNotEmpty) break;
      if (find.textContaining('Create your free account').evaluate().isNotEmpty) break;
      if (find.text('I have an invite code').evaluate().isNotEmpty) break;
      for (final String button in <String>['Continue', 'Close', 'OK', 'Skip', 'Disallow']) {
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
    while (!Get.isRegistered<FutureRunListPageController>() &&
        DateTime.now().isBefore(ctrlEnd)) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await h.settle(const Duration(seconds: 4));

    // Chats view → the seeded DM.
    await h.screen('01 runs');
    await h.tap(find.byIcon(Icons.chat_bubble_outline), what: 'chat bubble');
    await h.settle(const Duration(seconds: 3));
    await h.screen('02 chats');
    final Finder dmRow = find.text(kOther, skipOffstage: false);
    if (!await h.appears(dmRow, timeout: const Duration(seconds: 10))) {
      // Further down the list.
      final Finder list = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(dmRow, 300, scrollable: list);
    }
    await h.tap(dmRow, what: 'DM row');
    await h.settle(const Duration(seconds: 3));
    await h.screen('03 dm open');
    await h.waitFor(find.text(kSeeded), what: 'seeded message');

    // Reply.
    await tester.longPress(find.text(kSeeded).first);
    await h.settle(const Duration(seconds: 1));
    await h.screen('04 long press sheet');
    expect(find.byKey(const Key('chat-react-beer')), findsOneWidget,
        reason: 'the six-emoji row is at the top of the sheet');
    await h.tapText('Reply');
    await h.settle(const Duration(seconds: 1));
    expect(find.textContaining('Replying to'), findsOneWidget,
        reason: 'the quote bar shows above the composer');
    await h.screen('05 reply bar');
    await h.enterText(find.byType(TextField).last, kReplyText);
    await h.tap(find.byIcon(Icons.send), what: 'send');
    await h.settle(const Duration(seconds: 4));
    await h.screen('06 reply sent');
    expect(find.byKey(const Key('chat-quote-strip')), findsWidgets,
        reason: 'the sent reply carries the quote strip');
    expect(find.text(kReplyText), findsOneWidget);
    expect(find.textContaining('Replying to'), findsNothing,
        reason: 'the bar clears after sending');

    // React.
    await tester.longPress(find.text(kSeeded).first);
    await h.settle(const Duration(seconds: 1));
    await h.tap(find.byKey(const Key('chat-react-beer')), what: 'beer');
    await h.settle(const Duration(seconds: 3));
    await h.screen('07 reacted');
    final Finder chip = find.byKey(const Key('chat-reaction-chip-beer'));
    expect(chip, findsOneWidget, reason: 'a 🍺 chip appears under the message');
    expect(find.text('🍺 1'), findsOneWidget);

    // Reactions from a fresh fetch survive (the delta carries them).
    await h.back();
    await h.settle(const Duration(seconds: 2));
    await h.tap(find.text(kOther, skipOffstage: false), what: 'DM row again');
    await h.settle(const Duration(seconds: 4));
    await h.screen('08 reopened');
    expect(find.text('🍺 1'), findsOneWidget, reason: 'the reaction was stored');
    expect(find.byKey(const Key('chat-quote-strip')), findsWidgets,
        reason: 'the quote came back from the reader');

    // Toggle off.
    await h.tap(find.byKey(const Key('chat-reaction-chip-beer')), what: 'chip');
    await h.settle(const Duration(seconds: 3));
    await h.screen('09 unreacted');
    expect(find.text('🍺 1'), findsNothing, reason: 'tapping my chip removes it');

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
