// Walks the 18 screens that moved to GetX controllers on 2026-09-23 and
// records every framework error each one raises — the GetX "improper use"
// class included. One broken screen does not stop the walk: each step is
// caught, screenshotted and the walk carries on; the ledger is asserted at
// the end.
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/screens_test.dart -d <simulator udid> \
//     [--dart-define=HC_TEST_INVITE_CODE=ABCDEF]   # only when signed out
//     [--dart-define=HC_TEST_KENNEL=HCTEST-ABC]     # a kennel you manage (default)
//     [--dart-define=HC_TEST_RUN="Test image upload"] # search text for one of its runs (default)
//
// Screenshots land in integration_test/screenshots/ (see test_driver/).
import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';
import 'package:integration_test/integration_test.dart';

import 'harness/hc_harness.dart';

const String kInviteCode = String.fromEnvironment('HC_TEST_INVITE_CODE');
// Defaults: the test kennel and the run James set up on it on 2026-09-24 —
// attended, RSVP'd, with a charge — so Add Down Down, run admin and Edit
// Down Down are all reachable. Override with --dart-define for another.
const String kKennel = String.fromEnvironment(
  'HC_TEST_KENNEL',
  defaultValue: 'HCTEST-ABC',
);
const String kRunSearch = String.fromEnvironment(
  'HC_TEST_RUN',
  defaultValue: 'Test image upload',
);

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'the migrated screens open without framework errors',
    (WidgetTester tester) async {
      final Harness h = Harness(tester, binding);
      final Walk w = Walk(h);

      await w.step('00 boot and sign in', () async {
        await h.launch();
        await w.dismissStaleCodeDialog();
        await w.signInIfGuest();
        await w.waitForMain();
      });

      await w.step('06 history list', w.historyList);
      await w.step('07 my runs for a kennel', w.myRunsForKennel);
      await w.step('08 my runs for a country', w.myRunsForCountry);
      await w.step('12 check-in QR page', w.qrPage);
      await w.step('14 support', w.support);
      await w.step('16a my account', w.myAccount);
      await w.step('11 global leaderboard', w.globalLeaderboard);
      await w.step('17 run tabs (+02 photos, 11b stats, 15a add)', w.runTabs);
      await w.step('10 kennel members (+16b, 07b, 16c)', w.kennelAdmin);
      if (!w.runAdminDone) {
        await w.step('run admin via past events', w.runAdminViaPastEvents);
      }

      debugPrint('[HARNESS] ${h.ledger.report()}');
      h.restoreErrorHandler();
      expect(h.ledger.entries, isEmpty, reason: h.ledger.report());
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}

class Walk {
  Walk(this.h);

  final Harness h;
  bool runAdminDone = false;

  WidgetTester get t => h.tester;

  /// Runs one screen's step; a failure is recorded against the screen, the
  /// app is brought back to the main page, and the walk continues.
  Future<void> step(String name, Future<void> Function() body) async {
    h.ledger.screen = name;
    debugPrint('[HARNESS] ▶ $name');
    try {
      await body();
    } catch (e) {
      h.ledger.entries.add((screen: name, error: 'walk failed: $e'));
      await h.shot('FAILED_$name');
    }
    await backToMain();
  }

  // ── boot and sign-in ────────────────────────────────────────────────

  /// Boot can end on the main page (signed in), the guest page, or the
  /// Find My Account page (after a dead stored code), each possibly behind
  /// one or two alerts ("Close" from the server error, "Continue" from the
  /// boot service). Press through whatever shows up.
  Future<void> dismissStaleCodeDialog() async {
    final DateTime end = DateTime.now().add(const Duration(seconds: 45));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 200));
      if (find.byIcon(Icons.menu).evaluate().isNotEmpty) return;
      if (find.textContaining('Create your free account').evaluate().isNotEmpty) return;
      if (find.text('I have an invite code').evaluate().isNotEmpty) return;
      for (final String button in ['Close', 'Continue', 'OK']) {
        if (find.byType(AlertDialog).evaluate().isNotEmpty &&
            find.text(button).evaluate().isNotEmpty) {
          debugPrint('[HARNESS] boot alert: pressing $button');
          await h.tapText(button);
          break;
        }
      }
    }
  }

  Future<void> signInIfGuest() async {
    if (find.byIcon(Icons.menu).evaluate().isNotEmpty) return;
    await h.screen('00 after boot');
    debugPrint('[HARNESS] texts on screen: ${find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().take(12).toList()}');
    if (kInviteCode.isEmpty) {
      throw TestFailure(
        'The simulator is signed out; pass --dart-define=HC_TEST_INVITE_CODE',
      );
    }
    h.ledger.screen = '13 sign in';
    final Finder guestButton = find.textContaining('Create your free account');
    if (guestButton.evaluate().isNotEmpty) {
      await h.tap(guestButton, what: 'guest sign-in button');
    }

    // Intro / permission slides, if the onboarding has anything left to
    // show: Skip each one, Disallow the confirm, until the account page.
    for (int i = 0; i < 12; i++) {
      if (find.text('I have an invite code').evaluate().isNotEmpty) break;
      // The account question page: "Yes — take me to the invite code screen".
      if (find.text('Take me to the invite code screen').evaluate().isNotEmpty) {
        await h.tapText('Yes');
        break;
      }
      // Never press the primary button on a permission page: 'Allow' (or
      // 'OK' when it is the last page) fires a native prompt.
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
    await h.screen('13 use invite code');
    await h.enterText(find.byType(TextFormField), kInviteCode);
    await h.tapText('Get Started!');
    // "Success! The app has been set up for <name>." — press OK, then the
    // boot sync runs and the main page follows.
    final DateTime end = DateTime.now().add(const Duration(seconds: 60));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 200));
      if (find.byIcon(Icons.menu).evaluate().isNotEmpty) return;
      if (find.text('Success!').evaluate().isNotEmpty &&
          find.text('OK').evaluate().isNotEmpty) {
        await h.screen('13 signed in');
        await h.tapText('OK');
        return;
      }
    }
  }

  Future<void> waitForMain() async {
    // First sign-in runs the boot sync; give it a while.
    await h.waitFor(
      find.byIcon(Icons.menu),
      timeout: const Duration(minutes: 3),
      what: 'main page (menu icon)',
    );
    await h.settle(const Duration(seconds: 3));
    await h.screen('00 main');
  }

  /// Pops everything back to the main navigation page.
  Future<void> backToMain() async {
    for (int i = 0; i < 8; i++) {
      // A dialog or the drawer first.
      if (find.text('Close').evaluate().isNotEmpty &&
          find.byType(AlertDialog).evaluate().isNotEmpty) {
        await h.tapText('Close');
      }
      final NavigatorState nav = t.state(find.byType(Navigator).first);
      if (!nav.canPop()) break;
      nav.pop();
      await h.settle(const Duration(milliseconds: 700));
    }
    await h.settle(const Duration(milliseconds: 500));
  }

  Future<void> navTab(String label) async {
    await h.tapText(label);
    await h.settle(const Duration(seconds: 1));
  }

  Future<void> openDrawerItem(String label) async {
    await h.tapIcon(Icons.menu);
    await h.waitFor(find.byType(Drawer), what: 'drawer');
    await h.tapText(label);
    await h.settle(const Duration(seconds: 2));
  }

  // ── screens ─────────────────────────────────────────────────────────

  Future<void> historyList() async {
    await navTab('History');
    await h.waitFor(find.text('By Kennel'));
    await h.settle(const Duration(seconds: 3));
    await h.screen('06 history list');
  }

  Future<void> myRunsForKennel() async {
    await navTab('History');
    await h.tapText('By Kennel');
    final Finder row = find.byType(KennelRunHistoryCountListItem);
    if (!await h.appears(row, timeout: const Duration(seconds: 10))) {
      await h.screen('07 no kennel history rows');
      return;
    }
    await h.tap(row.first, what: 'first kennel history row');
    await h.waitFor(find.text('My Runs'));
    await h.settle(const Duration(seconds: 3));
    await h.screen('07 my runs for kennel');
    await h.tapText('All Runs');
    await h.settle(const Duration(seconds: 2));
    await h.screen('07 all runs for kennel');
  }

  Future<void> myRunsForCountry() async {
    await navTab('History');
    await h.tapText('By Country');
    final Finder row = find.byType(CountryRunHistoryCountListItem);
    if (!await h.appears(row, timeout: const Duration(seconds: 10))) {
      await h.screen('08 no country history rows');
      return;
    }
    await h.tap(row.first, what: 'first country history row');
    await h.waitFor(find.text('My Runs'));
    await h.settle(const Duration(seconds: 3));
    await h.screen('08 my runs for country');
  }

  Future<void> qrPage() async {
    await navTab('Runs');
    await h.tapIcon(Icons.qr_code_scanner_sharp);
    await h.waitFor(find.text('Be Scanned'));
    await h.settle(const Duration(seconds: 2));
    await h.screen('12 qr scan tab');
    await h.tapText('Be Scanned');
    await h.settle(const Duration(seconds: 2));
    await h.screen('12 qr be-scanned tab');
    await h.tapText('Scan');
    await h.settle(const Duration(seconds: 1));
  }

  Future<void> support() async {
    await openDrawerItem('Support');
    await h.waitFor(find.text('Secret QR code for:'));
    await h.screen('14 support');
  }

  Future<void> myAccount() async {
    await openDrawerItem('My Account');
    await h.waitFor(
      find.text('First name (or initial)'),
      timeout: const Duration(seconds: 40),
    );
    await h.settle(const Duration(seconds: 2));
    await h.screen('16a my account');
  }

  Future<void> globalLeaderboard() async {
    await openDrawerItem('Global Leaders');
    await h.waitFor(find.text('Total'), timeout: const Duration(seconds: 40));
    await h.settle(const Duration(seconds: 4));
    await h.screen('11 global leaderboard');
    await h.tapText('Total');
    await h.settle(const Duration(seconds: 3));
    await h.screen('11 global leaderboard total');
  }

  /// Opens a run (the configured past run if it is listed, else the first
  /// card), walks its six tabs, and the run admin screens if the gear shows.
  Future<void> runTabs() async {
    await navTab('Runs');
    final Finder search = find.descendant(
      of: find.byType(FutureRunsListPage),
      matching: find.byType(TextField),
    );
    if (search.evaluate().isNotEmpty) {
      await h.enterText(search, kRunSearch);
      await h.settle(const Duration(seconds: 3));
    }
    Finder card = find.byType(RunListItem);
    if (!await h.appears(card, timeout: const Duration(seconds: 8))) {
      if (search.evaluate().isNotEmpty) {
        await h.enterText(search, '');
        await h.settle(const Duration(seconds: 3));
      }
      card = find.byType(RunListItem);
      await h.waitFor(card, what: 'a run card');
    }
    await h.tap(card.first, what: 'run card');
    await h.waitFor(find.text('Run Details'));
    await h.settle(const Duration(seconds: 3));
    await h.screen('17 run details');

    for (final String tab in ['RSVP', 'Map', 'Stats', 'Chat', 'Photos']) {
      await h.tapText(tab);
      await h.settle(const Duration(seconds: 4));
      await h.screen('17 run tab $tab');
    }
    await h.tapText('Details');
    await h.settle(const Duration(seconds: 1));

    if (find.text('Add Down Down').evaluate().isNotEmpty) {
      await h.tapText('Add Down Down');
      await h.waitFor(find.text('Charge'), timeout: const Duration(seconds: 20));
      await h.settle(const Duration(seconds: 2));
      await h.screen('15a add down down');
      await h.back();
    }
    if (find.text('Manage').evaluate().isNotEmpty) {
      await h.tapText('Manage');
      await h.settle(const Duration(seconds: 4));
      await h.screen('05 live run charges');
      await h.back();
    }
    if (find.byIcon(FontAwesome.gear).evaluate().isNotEmpty) {
      await h.tapIcon(FontAwesome.gear);
      await runAdminScreens();
    }
  }

  /// From RunAdminPage: award list, hash cash, down downs (+ edit), receipts.
  Future<void> runAdminScreens() async {
    await h.waitFor(find.text('Run Admin'));
    await h.settle(const Duration(seconds: 2));
    await h.screen('run admin');

    if (find.textContaining('Award').evaluate().isNotEmpty) {
      await h.tap(find.textContaining('Award'), what: 'Award list');
      await h.waitFor(find.text('Drink chug-a-lug'));
      await h.settle(const Duration(seconds: 5));
      await h.screen('01 drinks list');
      await h.back();
    }
    if (find.textContaining('cash').evaluate().isNotEmpty) {
      await h.tap(find.textContaining('cash'), what: 'Hash cash');
      await h.settle(const Duration(seconds: 6));
      await h.screen('09 payment report');
      await h.back();
    }
    if (find.textContaining('Downs').evaluate().isNotEmpty) {
      await h.tap(find.textContaining('Downs'), what: 'Down Downs');
      await h.waitFor(find.text('Down Downs'));
      await h.settle(const Duration(seconds: 5));
      await h.screen('04 down downs');
      if (find.byIcon(Icons.edit_outlined).evaluate().isNotEmpty) {
        await h.tapIcon(Icons.edit_outlined);
        await h.settle(const Duration(seconds: 3));
        await h.screen('15b edit down down');
        await h.back();
      }
      await h.back();
    }
    if (find.textContaining('receipts').evaluate().isNotEmpty) {
      await h.tap(find.textContaining('receipts'), what: 'Manage receipts');
      await h.settle(const Duration(seconds: 4));
      await h.screen('03 receipts');
      await h.back();
    }
    runAdminDone = true;
  }

  Future<void> kennelAdmin() async {
    await navTab('Kennels');
    final Finder search = find.descendant(
      of: find.byType(KennelsListPage),
      matching: find.byType(TextField),
    );
    if (search.evaluate().isNotEmpty) {
      await h.enterText(search, kKennel);
      await h.settle(const Duration(seconds: 2));
    }
    await h.tap(find.byType(KennelListItem).first, what: 'kennel card');
    await h.waitFor(find.text('Manage Members'), timeout: const Duration(seconds: 20));
    await h.settle(const Duration(seconds: 2));
    await h.screen('kennel admin');
    await h.tapText('Manage Members');
    await h.waitFor(find.textContaining('Members'), timeout: const Duration(seconds: 40));
    await h.settle(const Duration(seconds: 5));
    await h.screen('10 kennel members');

    // Another hasher's profile, then their run history — the 1397 site.
    final Finder member = find.byType(KennelMemberListItem);
    if (await h.appears(member, timeout: const Duration(seconds: 10))) {
      await h.tap(member.first, what: 'first member row');
      await h.waitFor(find.text('Hasher Profile'), timeout: const Duration(seconds: 30));
      await h.settle(const Duration(seconds: 3));
      await h.screen('16b other hasher profile');
      if (await h.appears(find.text('View Run History'), timeout: const Duration(seconds: 15))) {
        await h.tapText('View Run History');
        await h.waitFor(find.text('My Runs'), timeout: const Duration(seconds: 40));
        await h.settle(const Duration(seconds: 3));
        await h.screen('07b other hasher run history');
        await h.back();
      }
      await h.back();
    }

    // New hasher via the speed dial.
    await h.waitFor(find.textContaining('Members'));
    if (find.byType(SpeedDial).evaluate().isNotEmpty) {
      await h.tap(find.byType(SpeedDial), what: 'members speed dial');
      await h.settle(const Duration(seconds: 1));
      if (find.textContaining('Add new Hasher').evaluate().isNotEmpty) {
        // The label is a chip; the button is the icon beside it.
        await h.tapIcon(Icons.person_add);
        await h.waitFor(find.text('Hasher Profile'), timeout: const Duration(seconds: 20));
        await h.settle(const Duration(seconds: 2));
        await h.screen('16c new hasher profile');
        await h.back();
      } else {
        await h.tap(find.byType(SpeedDial), what: 'close speed dial');
      }
    }
  }

  /// Kennel admin → Past events → first run → RunAdminPage.
  Future<void> runAdminViaPastEvents() async {
    await navTab('Kennels');
    final Finder search = find.descendant(
      of: find.byType(KennelsListPage),
      matching: find.byType(TextField),
    );
    if (search.evaluate().isNotEmpty) {
      await h.enterText(search, kKennel);
      await h.settle(const Duration(seconds: 2));
    }
    await h.tap(find.byType(KennelListItem).first, what: 'kennel card');
    await h.waitFor(find.textContaining('Past'), timeout: const Duration(seconds: 20));
    await h.tap(find.textContaining('Past'), what: 'Past events');
    final Finder row = find.byType(FilterEventListItem);
    await h.waitFor(row, timeout: const Duration(seconds: 30), what: 'past event row');
    await h.settle(const Duration(seconds: 2));
    await h.screen('past events');
    await h.tap(row.first, what: 'first past event');
    await runAdminScreens();
  }
}
