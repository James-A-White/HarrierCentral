import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// The findability question and a hasher row at a small phone width and a
/// large text size — the size at which this app's layouts have overflowed
/// before (2026-09-25). No layout exception may be thrown.
Widget _host(Widget child, {required bool dark}) => GetMaterialApp(
  home: MediaQuery(
    data: const MediaQueryData(
      size: Size(320, 640),
      textScaler: TextScaler.linear(1.5),
    ),
    child: Scaffold(
      backgroundColor: dark ? Colors.black : Colors.white,
      body: SingleChildScrollView(child: child),
    ),
  ),
);

void main() {
  setUp(Get.reset);

  for (final bool dark in <bool>[false, true]) {
    testWidgets('findability question lays out (${dark ? 'jungle' : 'dialog'})', (
      WidgetTester t,
    ) async {
      t.view.physicalSize = const Size(320, 640);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final FindabilityController c = FindabilityController();
      await t.pumpWidget(
        _host(
          FindabilityChooser(
            controller: c,
            onDark: dark,
            onSaved: (_) {},
            onCancel: () {},
          ),
          dark: dark,
        ),
      );
      expect(find.text('Can other hashers find you?'), findsOneWidget);
      // Save stays off until a choice is made: a dismissal is never a decision.
      final ElevatedButton save = t.widget(
        find.widgetWithText(ElevatedButton, 'Save'),
      );
      expect(save.onPressed, isNull);
      await t.ensureVisible(find.text("Only hashers I've run with"));
      await t.tap(find.text("Only hashers I've run with"));
      await t.pump();
      expect(c.scope.value, DirectoryVisibility.runTogether);
      final ElevatedButton save2 = t.widget(
        find.widgetWithText(ElevatedButton, 'Save'),
      );
      expect(save2.onPressed, isNotNull);
      await t.ensureVisible(find.text("Nobody. I don't want to be found"));
      await t.tap(find.text("Nobody. I don't want to be found"));
      await t.pump();
      expect(c.scope.value, DirectoryVisibility.nobody);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('a hasher row lays out on both backgrounds', (WidgetTester t) async {
    t.view.physicalSize = const Size(320, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    const HasherSummary h = HasherSummary(
      publicHasherId: HcId.empty,
      displayName: 'A Very Long Hash Name That Will Not Fit On One Line At All',
      homeKennelShortName: 'Some Kennel With A Long Name',
      runsTogether: 493,
    );
    await t.pumpWidget(
      _host(
        const Column(
          children: <Widget>[
            HasherRow(hasher: h, onDark: false, rank: 1),
            HasherRow(hasher: h, onDark: true),
          ],
        ),
        dark: false,
      ),
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('By Hasher row: By Kennel layout, square photo, no clipping', (
    WidgetTester t,
  ) async {
    t.view.physicalSize = const Size(320, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    const HasherSummary h = HasherSummary(
      publicHasherId: HcId.empty,
      displayName: 'Tuna Melt',
      homeKennelShortName: 'City H3',
      runsTogether: 492,
    );
    await t.pumpWidget(
      _host(
        const SizedBox(height: 100, child: HasherRunCountListItem(hasher: h)),
        dark: false,
      ),
    );
    expect(find.text('492'), findsOneWidget);
    expect(find.text('(City H3)'), findsOneWidget);
    expect(find.byType(ClipOval), findsNothing);
    final Size photo = t.getSize(find.byType(HasherPhoto));
    expect(photo.width, photo.height);
    expect(t.takeException(), isNull);
  });

  testWidgets('shared run row matches the run history row', (
    WidgetTester t,
  ) async {
    t.view.physicalSize = const Size(320, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final SharedRun r = SharedRun(
      eventId: HcId.empty,
      eventNumber: 226,
      eventName: 'FILTH #226 - Amsterdam',
      startLocal: DateTime(2024, 3, 25, 19, 30),
      kennelShortName: 'FILTH',
      meHare: true,
      themHare: true,
      myRunNumber: 114,
      myHareNumber: 63,
    );
    await t.pumpWidget(
      _host(
        SharedRunListItem(run: r, theirName: 'Tuna Melt', onTap: () {}),
        dark: false,
      ),
    );
    expect(find.text('FILTH #226 - Amsterdam'), findsOneWidget);
    expect(find.text('Run #226 on Mon, Mar 25, 2024 at 7:30 PM'), findsOneWidget);
    expect(find.text('My FILTH run #114'), findsOneWidget);
    expect(find.text(' and #63 time haring'), findsOneWidget);
    expect(find.text('Tuna Melt hared'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
