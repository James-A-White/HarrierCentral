// Screenshots for the On-On user guide (docs/user-guide/). Boots the real
// app on a simulator that is signed in, walks the screens each chapter
// describes, and captures each at 2x into integration_test/screenshots/.
// Everything run-specific happens on the test kennel's test run, so the
// guide shows no real member's private data. Nothing is saved or sent:
// the run editor is made dirty only to light up its buttons, then popped.
//
// Run (simulator signed in; uninstall first and pass the code if not):
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/user_guide_shots_test.dart -d <udid> \
//     --dart-define=HC_UI_TEST=true \
//     [--dart-define=HC_TEST_INVITE_CODE=ABCDEF]
//
// Screens deliberately NOT captured: Support and "Be Scanned" (they show the
// user's secret QR code), My Account (email address), the Chats list (other
// people's messages in its previews).
import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';
import 'package:integration_test/integration_test.dart';

import 'harness/hc_harness.dart';
import 'screens_test.dart' show Walk;

const String kKennel = String.fromEnvironment('HC_TEST_KENNEL', defaultValue: 'HCTEST-ABC');
const String kRunSearch = String.fromEnvironment('HC_TEST_RUN', defaultValue: 'Test image upload');
// A real kennel (e.g. --dart-define=HC_GUIDE_REAL=true with HC_TEST_KENNEL=BMPH3):
// screens are prefixed "real" and every screen that shows members' private
// details — the roster, manual check-in, payments, the email audience — is skipped.
const bool kReal = bool.fromEnvironment('HC_GUIDE_REAL');
const String kTag = kReal ? 'guide real' : 'guide';

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'user guide screenshots',
    (WidgetTester tester) async {
      final Harness h = Harness(tester, binding)..pixelRatio = 2.0;
      final Walk w = Walk(h);
      final Guide g = Guide(h, w);

      await w.step('boot', () async {
        await h.launch();
        await w.dismissStaleCodeDialog();
        await w.signInIfGuest();
        await h.waitFor(find.byIcon(Icons.menu), timeout: const Duration(minutes: 3), what: 'main page');
        await h.settle(const Duration(seconds: 6));
      });

      await w.step('runs', g.runsList);
      await w.step('kennels', g.kennels);
      await w.step('map', g.mapTab);
      await w.step('history', g.history);
      await w.step('songs', g.songs);
      await w.step('leaderboard', g.leaderboard);
      await w.step('run', g.run);

      debugPrint('[HARNESS] ${h.ledger.report()}');
      h.restoreErrorHandler();
      // Screens are evidence here, not assertions: a framework error is
      // reported in the log but does not fail the shoot.
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}

class Guide {
  Guide(this.h, this.w);
  final Harness h;
  final Walk w;
  WidgetTester get t => h.tester;

  Future<void> runsList() async {
    await w.navTab('Runs');
    await h.settle(const Duration(seconds: 4));
    await h.screen('$kTag runs list');
  }

  Future<void> kennels() async {
    await w.navTab('Kennels');
    await h.settle(const Duration(seconds: 3));
    await h.screen('$kTag kennels list');
    final Finder search = find.descendant(of: find.byType(KennelsListPage), matching: find.byType(TextField));
    if (search.evaluate().isNotEmpty) {
      await h.enterText(search, kKennel);
      await h.settle(const Duration(seconds: 2));
    }
    await h.tap(find.byType(KennelListItem).first, what: 'kennel card');
    await h.settle(const Duration(seconds: 4));
    await h.screen('$kTag kennel page');
    if (!kReal && await h.appears(find.text('Manage Members'), timeout: const Duration(seconds: 10))) {
      await h.tapText('Manage Members');
      await h.settle(const Duration(seconds: 6));
      await h.screen('$kTag kennel members');
    }
  }

  Future<void> mapTab() async {
    await w.navTab('Map');
    await h.settle(const Duration(seconds: 6));
    await h.screen('$kTag run map');
  }

  Future<void> history() async {
    await w.navTab('History');
    await h.settle(const Duration(seconds: 4));
    await h.screen('$kTag history');
  }

  Future<void> songs() async {
    await w.navTab('Songs');
    await h.settle(const Duration(seconds: 3));
    await h.screen('$kTag songs');
  }

  Future<void> leaderboard() async {
    await w.openDrawerItem('Global Leaders');
    await h.waitFor(find.text('Total'), timeout: const Duration(seconds: 40));
    await h.settle(const Duration(seconds: 4));
    await h.screen('$kTag leaderboard');
  }

  /// The test run: details and tabs, then run admin, its sub-screens, the
  /// run editor and the run email composer.
  Future<void> run() async {
    await w.navTab('Runs');
    final Finder search = find.descendant(of: find.byType(FutureRunsListPage), matching: find.byType(TextField));
    if (search.evaluate().isNotEmpty) {
      await h.enterText(search, kRunSearch);
      await h.settle(const Duration(seconds: 3));
    }
    // The card that names the run — past runs are folded until "Past Runs"
    // is opened, so open it when the run is not already showing.
    Finder target = find.ancestor(of: find.textContaining(kRunSearch, skipOffstage: false), matching: find.byType(RunListItem));
    if (!await h.appears(target, timeout: const Duration(seconds: 4))) {
      final Finder past = find.textContaining('Past Runs');
      if (past.evaluate().isNotEmpty) {
        await h.tap(past, what: 'Past Runs');
        await h.settle(const Duration(seconds: 4));
      }
    }
    target = find.ancestor(of: find.textContaining(kRunSearch, skipOffstage: false), matching: find.byType(RunListItem));
    if (target.evaluate().isEmpty) {
      throw TestFailure('No run card containing "$kRunSearch"');
    }
    await h.tap(target.first, what: 'run card "$kRunSearch"');
    await h.waitFor(find.text('Run Details'));
    await h.settle(const Duration(seconds: 4));
    await h.screen('$kTag run details');
    for (final String tab in <String>['RSVP', 'Map', 'Photos', 'Chat', 'Stats']) {
      // Tap the run's own tab, not the bottom-nav label of the same name.
      final Finder inBar = find.descendant(of: find.byType(TabBar), matching: find.text(tab));
      await h.tap(inBar.evaluate().isNotEmpty ? inBar : find.text(tab), what: 'tab $tab');
      await h.settle(Duration(seconds: tab == 'Map' ? 10 : 5));
      await h.screen('$kTag run tab $tab');
    }
    await h.tapText('Details');
    await h.settle(const Duration(seconds: 1));

    if (find.byIcon(FontAwesome.gear).evaluate().isEmpty) return;
    await h.tapIcon(FontAwesome.gear);
    await h.waitFor(find.text('Run Admin'));
    await h.settle(const Duration(seconds: 3));
    await h.screen('$kTag run admin');
    final String eventId = t.widget<RunAdminPage>(find.byType(RunAdminPage)).eventId;

    Future<void> sub(String label, String name, {int wait = 5}) async {
      final Finder f = find.textContaining(label);
      if (f.evaluate().isEmpty) return;
      await h.tap(f, what: label);
      await h.settle(Duration(seconds: wait));
      await h.screen(name);
      await h.back();
      await h.settle(const Duration(seconds: 1));
    }

    await sub('Award', '$kTag award list');
    await sub('Downs', '$kTag down downs');
    await sub('Photos', '$kTag review photos', wait: 6);
    if (kReal) return;
    await sub('cash', '$kTag hash cash report', wait: 6);
    await sub('Manual', '$kTag manual check in');
    await sub('Trash', '$kTag hash trash');

    // The run editor with its Save / Save and send bar lit: one keystroke
    // in the first text field makes the form dirty. Popped, never saved.
    if (find.textContaining('Edit run').evaluate().isNotEmpty) {
      await h.tap(find.textContaining('Edit run'), what: 'Edit run details');
      await h.waitFor(find.text('Edit run details'), timeout: const Duration(seconds: 20));
      await h.settle(const Duration(seconds: 3));
      final Finder field = find.byType(TextFormField);
      if (field.evaluate().isNotEmpty) {
        final TextFormField f = t.widget<TextFormField>(field.first);
        final String before = f.controller?.text ?? '';
        await h.enterText(field.first, '$before ');
        await h.settle(const Duration(seconds: 1));
        FocusManager.instance.primaryFocus?.unfocus();
        await h.settle(const Duration(seconds: 1));
      }
      await h.screen('$kTag edit run');
      await h.back();
      await h.settle(const Duration(seconds: 2));
    }

    // The email composer, opened directly with the run's aggregate (the same
    // page Save and send opens), filled from the run description.
    final RunAdminController rc = Get.find<RunAdminController>(tag: eventId);
    final RunAdminAggregate? agg = rc.eventAggregate.value;
    if (agg == null) return;
    final RunEmailContext ctx = await const RunEmailService().context(HcId(eventId));
    unawaited(Get.to<int>(() => RunEmailComposerPage(eventAggregate: agg, emailContext: ctx)));
    await h.waitFor(find.text('Email the run'), timeout: const Duration(seconds: 20));
    await h.settle(const Duration(seconds: 2));
    await h.screen('$kTag email composer empty');
    if (find.text('Use run description').evaluate().isNotEmpty) {
      await h.tapText('Use run description');
      await h.settle(const Duration(seconds: 2));
      await h.screen('$kTag email composer filled');
    }
    if (find.text('Who gets it').evaluate().isNotEmpty) {
      await h.tapText('Who gets it');
      await h.settle(const Duration(seconds: 6));
      await h.screen('$kTag email audience');
      await h.back();
    }
  }
}
